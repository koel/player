package phanan.koel.shared.storage

import kotlinx.serialization.builtins.ListSerializer
import kotlinx.serialization.builtins.serializer
import phanan.koel.shared.json.KoelJson
import phanan.koel.shared.models.EqualizerPreset
import phanan.koel.shared.player.RepeatMode

/** Implemented natively (UserDefaults/Keychain on iOS); in-memory in tests. */
interface KeyValueStore {
    fun get(key: String): String?
    fun set(key: String, value: String?)
}

class Preferences(private val store: KeyValueStore) {
    var host: String?
        get() = store.get("hostUrl")
        set(value) = store.set("hostUrl", value?.trimEnd('/'))

    val apiBaseUrl: String? get() = host?.let { "$it/api" }

    var apiToken: String?
        get() = store.get("apiToken")
        set(value) = store.set("apiToken", value)

    var audioToken: String?
        get() = store.get("audioToken")
        set(value) = store.set("audioToken", value)

    var userEmail: String?
        get() = store.get("email")
        set(value) = store.set("email", value)

    var repeatMode: RepeatMode
        get() = RepeatMode.entries.firstOrNull { it.name == store.get("repeatMode") } ?: RepeatMode.NONE
        set(value) = store.set("repeatMode", value.name)

    var volume: Double
        get() = store.get("volume")?.toDoubleOrNull() ?: 0.7
        set(value) = store.set("volume", value.toString())

    var equalizer: EqualizerPreset?
        get() = store.get("equalizer")?.let { runCatching { KoelJson.decodeFromString(EqualizerPreset.serializer(), it) }.getOrNull() }
        set(value) = store.set("equalizer", value?.let { KoelJson.encodeToString(EqualizerPreset.serializer(), it) })

    var crossfadeDuration: Int
        get() = store.get("crossfadeDuration")?.toIntOrNull() ?: 0
        set(value) = store.set("crossfadeDuration", value.toString())

    var normalizeVolume: Boolean
        get() = store.get("normalizeVolume")?.toBooleanStrictOrNull() ?: true
        set(value) = store.set("normalizeVolume", value.toString())

    var recentSearches: List<String>
        get() = store.get("recentSearches")?.let { runCatching { KoelJson.decodeFromString(ListSerializer(String.serializer()), it) }.getOrNull() }.orEmpty()
        set(value) = store.set("recentSearches", value.takeIf { it.isNotEmpty() }?.let { KoelJson.encodeToString(ListSerializer(String.serializer()), it) })

    /** The email the Flutter app filed downloads under, until they're moved to the email the server confirms. */
    internal var flutterDownloadsEmail: String?
        get() = store.get("flutterDownloadsEmail")
        set(value) = store.set("flutterDownloadsEmail", value)

    /** Playback settings changed while the server couldn't be told, e.g. offline. */
    internal var unsyncedPlaybackSettings: Set<String>
        get() = store.get("unsyncedPlaybackSettings")?.split(',')?.filter(String::isNotEmpty)?.toSet().orEmpty()
        set(value) = store.set("unsyncedPlaybackSettings", value.joinToString(",").ifEmpty { null })
}

class InMemoryKeyValueStore : KeyValueStore {
    private val values = mutableMapOf<String, String>()

    override fun get(key: String): String? = values[key]

    override fun set(key: String, value: String?) {
        if (value == null) values.remove(key) else values[key] = value
    }
}
