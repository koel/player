package phanan.koel.shared.stores

import kotlinx.coroutines.CoroutineScope
import kotlinx.coroutines.Job
import kotlinx.coroutines.delay
import kotlinx.coroutines.flow.MutableStateFlow
import kotlinx.coroutines.flow.StateFlow
import kotlinx.coroutines.flow.asStateFlow
import kotlinx.coroutines.launch
import kotlinx.serialization.json.JsonArray
import kotlinx.serialization.json.JsonElement
import kotlinx.serialization.json.JsonPrimitive
import kotlinx.serialization.json.buildJsonObject
import kotlinx.serialization.json.put
import phanan.koel.shared.api.ApiClient
import phanan.koel.shared.json.KoelJson
import phanan.koel.shared.models.Equalizer
import phanan.koel.shared.models.EqualizerPreset
import phanan.koel.shared.models.UserPreferences
import phanan.koel.shared.onMain
import phanan.koel.shared.storage.Preferences
import kotlin.time.Duration
import kotlin.time.Duration.Companion.milliseconds

/** The equalizer and crossfade, kept with the user's preferences on the server so they follow them to Koel web and back. */
class PlaybackSettingsStore internal constructor(
    private val api: ApiClient,
    private val preferences: Preferences,
    private val scope: CoroutineScope,
    private val syncDelay: Duration = 500.milliseconds,
) {
    private val equalizerState = MutableStateFlow(preferences.equalizer ?: Equalizer.default)
    val equalizer: StateFlow<EqualizerPreset> = equalizerState.asStateFlow()

    private val customPresetsState = MutableStateFlow<List<EqualizerPreset>>(emptyList())
    val customPresets: StateFlow<List<EqualizerPreset>> = customPresetsState.asStateFlow()

    private val canSavePresetsState = MutableStateFlow(false)

    /** Older servers keep only the current setting, not a list of saved presets. */
    val canSavePresets: StateFlow<Boolean> = canSavePresetsState.asStateFlow()

    private val crossfadeDurationState = MutableStateFlow(preferences.crossfadeDuration)

    /** Seconds two songs overlap when one ends on its own; 0 turns crossfading off. */
    val crossfadeDuration: StateFlow<Int> = crossfadeDurationState.asStateFlow()

    /** Servers before v9.0.0 have no crossfade preference, so the setting stays on the device. */
    private var serverKeepsCrossfade = false

    private val normalizeVolumeState = MutableStateFlow(preferences.normalizeVolume)

    /** Whether songs play at about the same loudness; takes effect on Koel Plus servers. */
    val normalizeVolume: StateFlow<Boolean> = normalizeVolumeState.asStateFlow()

    private var serverKeepsNormalizeVolume = false

    private val equalizerKey: String get() = if (canSavePresetsState.value) CURRENT_EQUALIZER_KEY else OLD_EQUALIZER_KEY

    private val pendingSyncs = mutableMapOf<String, Job>()

    fun setEqualizer(preset: EqualizerPreset) {
        equalizerState.value = preset
        preferences.equalizer = preset
        markUnsynced(EQUALIZER_SETTING)
        sync(EQUALIZER_SETTING, equalizerKey, KoelJson.encodeToJsonElement(EqualizerPreset.serializer(), preset))
    }

    fun setCrossfadeDuration(seconds: Int) {
        val clamped = seconds.coerceIn(0, MAX_CROSSFADE_SECONDS)
        crossfadeDurationState.value = clamped
        preferences.crossfadeDuration = clamped
        markUnsynced(CROSSFADE_KEY)
        if (serverKeepsCrossfade) sync(CROSSFADE_KEY, CROSSFADE_KEY, JsonPrimitive(clamped))
    }

    fun setNormalizeVolume(enabled: Boolean) {
        normalizeVolumeState.value = enabled
        preferences.normalizeVolume = enabled
        markUnsynced(NORMALIZE_VOLUME_KEY)
        if (serverKeepsNormalizeVolume) sync(NORMALIZE_VOLUME_KEY, NORMALIZE_VOLUME_KEY, JsonPrimitive(enabled))
    }

    /** Saves the current setting under [name] and makes it the current preset. */
    @Throws(Exception::class)
    suspend fun savePreset(name: String): EqualizerPreset = onMain {
        val current = equalizerState.value
        val response = api.post(PRESETS_PATH, buildJsonObject {
            put("name", name.trim())
            put("preamp", current.preamp)
            put("gains", JsonArray(current.gains.map(::JsonPrimitive)))
        })
        val saved = KoelJson.decodeFromJsonElement(EqualizerPreset.serializer(), response)
        customPresetsState.value += saved
        setEqualizer(saved)
        saved
    }

    @Throws(Exception::class)
    suspend fun removePreset(preset: EqualizerPreset): Unit = onMain {
        val id = preset.id ?: return@onMain
        api.delete("$PRESETS_PATH/$id")
        customPresetsState.value = customPresetsState.value.filterNot { it.id == id }
        if (equalizerState.value.id == id) setEqualizer(preset.copy(id = null, name = null))
    }

    /** A setting changed here but not yet saved on the server wins over the server's value, and is saved now. */
    internal fun seed(serverPreferences: UserPreferences) {
        val unsynced = preferences.unsyncedPlaybackSettings
        customPresetsState.value = serverPreferences.equalizerPresets.orEmpty()
        canSavePresetsState.value = serverPreferences.equalizerPresets != null

        if (EQUALIZER_SETTING in unsynced) {
            setEqualizer(equalizerState.value)
        } else {
            serverPreferences.equalizer?.let {
                equalizerState.value = it
                preferences.equalizer = it
            }
        }

        serverKeepsCrossfade = serverPreferences.crossfadeDuration != null
        if (CROSSFADE_KEY in unsynced) {
            setCrossfadeDuration(crossfadeDurationState.value)
        } else {
            serverPreferences.crossfadeDuration?.let {
                crossfadeDurationState.value = it.coerceIn(0, MAX_CROSSFADE_SECONDS)
                preferences.crossfadeDuration = crossfadeDurationState.value
            }
        }

        serverKeepsNormalizeVolume = serverPreferences.normalizeVolume != null
        if (NORMALIZE_VOLUME_KEY in unsynced) {
            setNormalizeVolume(normalizeVolumeState.value)
        } else {
            serverPreferences.normalizeVolume?.let {
                normalizeVolumeState.value = it
                preferences.normalizeVolume = it
            }
        }
    }

    internal fun reset() {
        pendingSyncs.values.forEach(Job::cancel)
        pendingSyncs.clear()
        preferences.unsyncedPlaybackSettings = emptySet()
        preferences.equalizer = null
        preferences.crossfadeDuration = 0
        equalizerState.value = Equalizer.default
        customPresetsState.value = emptyList()
        canSavePresetsState.value = false
        serverKeepsCrossfade = false
        crossfadeDurationState.value = 0
        serverKeepsNormalizeVolume = false
        preferences.normalizeVolume = true
        normalizeVolumeState.value = true
    }

    private fun markUnsynced(setting: String) {
        preferences.unsyncedPlaybackSettings += setting
    }

    /** Waits for a slider to settle, then saves only the last value. Until that succeeds, the change is [markUnsynced]. */
    private fun sync(setting: String, key: String, value: JsonElement) {
        pendingSyncs.remove(setting)?.cancel()
        pendingSyncs[setting] = scope.launch {
            delay(syncDelay)
            runCatching { api.patch(PREFERENCES_PATH, buildJsonObject { put("key", key); put("value", value) }) }
                .onSuccess { preferences.unsyncedPlaybackSettings -= setting }
        }
    }

    companion object {
        const val MAX_CROSSFADE_SECONDS = 15

        private const val PREFERENCES_PATH = "me/preferences"
        private const val PRESETS_PATH = "me/equalizer-presets"

        /** Servers that save presets reject the old key. */
        private const val CURRENT_EQUALIZER_KEY = "current_equalizer_preset"
        private const val OLD_EQUALIZER_KEY = "equalizer"
        private const val CROSSFADE_KEY = "crossfade_duration"
        private const val NORMALIZE_VOLUME_KEY = "normalize_volume"
        private const val EQUALIZER_SETTING = "equalizer"
    }
}
