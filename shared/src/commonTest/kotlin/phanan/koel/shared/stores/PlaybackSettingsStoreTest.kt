package phanan.koel.shared.stores

import io.ktor.http.HttpMethod
import kotlinx.coroutines.test.TestScope
import kotlinx.coroutines.test.UnconfinedTestDispatcher
import kotlinx.coroutines.test.advanceTimeBy
import kotlinx.coroutines.test.runCurrent
import kotlinx.coroutines.test.runTest
import kotlinx.serialization.json.JsonPrimitive
import kotlinx.serialization.json.jsonArray
import kotlinx.serialization.json.jsonObject
import kotlinx.serialization.json.jsonPrimitive
import phanan.koel.shared.json.KoelJson
import phanan.koel.shared.models.Equalizer
import phanan.koel.shared.models.User
import phanan.koel.shared.storage.Preferences
import phanan.koel.shared.support.Harness
import kotlin.test.Test
import kotlin.test.assertEquals
import kotlin.test.assertFalse
import kotlin.test.assertTrue
import kotlin.time.Duration.Companion.milliseconds

class PlaybackSettingsStoreTest {
    private val h = Harness()

    private fun TestScope.store() = PlaybackSettingsStore(h.api, h.preferences, backgroundScope, syncDelay = 500.milliseconds)

    private fun user(preferences: String) = KoelJson.decodeFromString(
        User.serializer(),
        """{"id":"u1","name":"Me","email":"me@koel.test","preferences":$preferences}""",
    )

    @Test
    fun newServersHandOverTheCurrentPresetSavedPresetsAndCrossfade() = runTest(UnconfinedTestDispatcher()) {
        val store = store()

        store.seed(
            user(
                """{"current_equalizer_preset":{"id":"p1","name":"Mine","preamp":-3,"gains":[1,2,3,4,5,6,7,8,9,10]},
                   "equalizer_presets":[{"id":"p1","name":"Mine","preamp":-3,"gains":[1,2,3,4,5,6,7,8,9,10]}],
                   "crossfade_duration":6}""",
            ).preferences,
        )

        assertEquals("Mine", store.equalizer.value.name)
        assertEquals(listOf("p1"), store.customPresets.value.map { it.id })
        assertTrue(store.canSavePresets.value)
        assertEquals(6, store.crossfadeDuration.value)
    }

    @Test
    fun olderServersCallTheCurrentPresetEqualizerAndCantSavePresets() = runTest(UnconfinedTestDispatcher()) {
        val store = store()

        store.seed(user("""{"equalizer":{"preamp":-2,"gains":[3,0,0,0,0,0,0,0,0,0]}}""").preferences)

        assertEquals(-2.0, store.equalizer.value.preamp)
        assertEquals(3.0, store.equalizer.value.gains[0])
        assertFalse(store.canSavePresets.value)
    }

    @Test
    fun aSliderSavesOnlyItsLastValueOnceItSettles() = runTest(UnconfinedTestDispatcher()) {
        h.on(HttpMethod.Patch, "me/preferences") { "" }
        val store = store()

        store.setEqualizer(Equalizer.default.withGain(0, 1.0))
        store.setEqualizer(Equalizer.default.withGain(0, 2.0))
        advanceTimeBy(400)
        assertTrue(h.requests.isEmpty())
        advanceTimeBy(200)
        runCurrent()

        val request = h.requests.single()
        assertEquals("equalizer", request.json.getValue("key").jsonPrimitive.content)
        assertEquals(JsonPrimitive(2.0), request.json.getValue("value").jsonObject.getValue("gains").jsonArray[0])
        assertEquals(2.0, store.equalizer.value.gains[0])
    }

    @Test
    fun serversThatSavePresetsGetTheCurrentPresetUnderItsNewKey() = runTest(UnconfinedTestDispatcher()) {
        h.on(HttpMethod.Patch, "me/preferences") { "" }
        val store = store()
        store.seed(user("""{"current_equalizer_preset":{"preamp":1,"gains":[1,0,0,0,0,0,0,0,0,0]},"equalizer_presets":[]}""").preferences)

        store.setEqualizer(Equalizer.builtInPresets.single { it.name == "Rock" })
        advanceTimeBy(600)
        runCurrent()

        val request = h.requests.single()
        assertEquals("current_equalizer_preset", request.json.getValue("key").jsonPrimitive.content)
        assertEquals("Rock", request.json.getValue("value").jsonObject.getValue("name").jsonPrimitive.content)
    }

    @Test
    fun theSettingIsKeptOnTheDeviceForTheNextLaunch() = runTest(UnconfinedTestDispatcher()) {
        h.on(HttpMethod.Patch, "me/preferences") { "" }
        store().setEqualizer(Equalizer.builtInPresets.single { it.name == "Rock" })
        store().setCrossfadeDuration(8)

        val nextLaunch = PlaybackSettingsStore(h.api, Preferences(h.keyValueStore), backgroundScope)

        assertEquals("Rock", nextLaunch.equalizer.value.name)
        assertEquals(8, nextLaunch.crossfadeDuration.value)
    }

    @Test
    fun crossfadeStaysWithinWhatTheServerAccepts() = runTest(UnconfinedTestDispatcher()) {
        h.on(HttpMethod.Patch, "me/preferences") { "" }
        val store = store()
        store.seed(user("""{"crossfade_duration":0}""").preferences)

        store.setCrossfadeDuration(30)
        advanceTimeBy(600)
        runCurrent()

        assertEquals(15, store.crossfadeDuration.value)
        assertEquals("crossfade_duration", h.requests.single().json.getValue("key").jsonPrimitive.content)
        assertEquals(JsonPrimitive(15), h.requests.single().json.getValue("value"))
    }

    @Test
    fun serversBeforeCrossfadeKeepItOnTheDeviceOnly() = runTest(UnconfinedTestDispatcher()) {
        h.on(HttpMethod.Patch, "me/preferences") { "" }
        store().setCrossfadeDuration(6)
        val store = store()

        store.seed(user("""{"equalizer":{"preamp":0,"gains":[0,0,0,0,0,0,0,0,0,0]}}""").preferences)
        assertEquals(6, store.crossfadeDuration.value)
        store.setCrossfadeDuration(9)
        advanceTimeBy(600)
        runCurrent()

        assertEquals(9, store.crossfadeDuration.value)
        assertTrue(h.requests.none { it.json.getValue("key").jsonPrimitive.content == "crossfade_duration" })
    }

    @Test
    fun normalizingVolumeFollowsTheServerAndIsSavedBack() = runTest(UnconfinedTestDispatcher()) {
        h.on(HttpMethod.Patch, "me/preferences") { "" }
        val store = store()
        assertTrue(store.normalizeVolume.value)

        store.seed(user("""{"normalize_volume":false}""").preferences)
        assertFalse(store.normalizeVolume.value)
        store.setNormalizeVolume(true)
        advanceTimeBy(600)
        runCurrent()

        val request = h.requests.single()
        assertEquals("normalize_volume", request.json.getValue("key").jsonPrimitive.content)
        assertEquals(JsonPrimitive(true), request.json.getValue("value"))
    }

    @Test
    fun serversWithoutNormalizingKeepTheSettingOnTheDevice() = runTest(UnconfinedTestDispatcher()) {
        h.on(HttpMethod.Patch, "me/preferences") { "" }
        val store = store()
        store.seed(user("""{"crossfade_duration":0}""").preferences)

        store.setNormalizeVolume(false)
        advanceTimeBy(600)
        runCurrent()

        assertFalse(store.normalizeVolume.value)
        assertTrue(h.requests.isEmpty())
    }

    @Test
    fun changesMadeOfflineWinOverTheServerOnceBackOnline() = runTest(UnconfinedTestDispatcher()) {
        h.on(HttpMethod.Patch, "me/preferences", status = 503) { "" }
        val offline = store()
        offline.seed(user("""{"crossfade_duration":0,"normalize_volume":true}""").preferences)
        offline.setEqualizer(Equalizer.builtInPresets.single { it.name == "Rock" })
        offline.setCrossfadeDuration(8)
        offline.setNormalizeVolume(false)
        advanceTimeBy(600)
        runCurrent()

        h.on(HttpMethod.Patch, "me/preferences") { "" }
        h.requests.clear()
        val nextLaunch = PlaybackSettingsStore(h.api, Preferences(h.keyValueStore), backgroundScope)
        nextLaunch.seed(
            user(
                """{"equalizer":{"preamp":0,"gains":[0,0,0,0,0,0,0,0,0,0]},"crossfade_duration":0,"normalize_volume":true}""",
            ).preferences,
        )
        advanceTimeBy(600)
        runCurrent()

        assertEquals("Rock", nextLaunch.equalizer.value.name)
        assertEquals(8, nextLaunch.crossfadeDuration.value)
        assertFalse(nextLaunch.normalizeVolume.value)
        val saved = h.requests.associate { it.json.getValue("key").jsonPrimitive.content to it.json.getValue("value") }
        assertEquals("Rock", saved.getValue("equalizer").jsonObject.getValue("name").jsonPrimitive.content)
        assertEquals(JsonPrimitive(8), saved.getValue("crossfade_duration"))
        assertEquals(JsonPrimitive(false), saved.getValue("normalize_volume"))

        nextLaunch.seed(user("""{"crossfade_duration":4}""").preferences)
        assertEquals(4, nextLaunch.crossfadeDuration.value)
    }

    @Test
    fun savingAPresetPostsTheCurrentSettingAndSelectsIt() = runTest(UnconfinedTestDispatcher()) {
        h.on(HttpMethod.Patch, "me/preferences") { "" }
        h.on(HttpMethod.Post, "me/equalizer-presets") {
            """{"id":"new","name":"Night","preamp":-4,"gains":[5,0,0,0,0,0,0,0,0,0]}"""
        }
        val store = store()
        store.setEqualizer(Equalizer.default.withPreamp(-4.0).withGain(0, 5.0))

        store.savePreset("  Night ")

        val body = h.requestsTo(HttpMethod.Post, "me/equalizer-presets").single().json
        assertEquals("Night", body.getValue("name").jsonPrimitive.content)
        assertEquals(-4.0, body.getValue("preamp").jsonPrimitive.content.toDouble())
        assertEquals(listOf("new"), store.customPresets.value.map { it.id })
        assertEquals("new", store.equalizer.value.id)
    }

    @Test
    fun removingTheCurrentPresetKeepsItsSoundAsACustomSetting() = runTest(UnconfinedTestDispatcher()) {
        h.on(HttpMethod.Patch, "me/preferences") { "" }
        h.on(HttpMethod.Delete, "me/equalizer-presets/p1") { "" }
        val store = store()
        store.seed(
            user(
                """{"current_equalizer_preset":{"id":"p1","name":"Mine","preamp":-3,"gains":[1,0,0,0,0,0,0,0,0,0]},
                   "equalizer_presets":[{"id":"p1","name":"Mine","preamp":-3,"gains":[1,0,0,0,0,0,0,0,0,0]}]}""",
            ).preferences,
        )

        store.removePreset(store.customPresets.value.single())

        assertTrue(store.customPresets.value.isEmpty())
        assertEquals(null, store.equalizer.value.id)
        assertEquals(1.0, store.equalizer.value.gains[0])
    }
}
