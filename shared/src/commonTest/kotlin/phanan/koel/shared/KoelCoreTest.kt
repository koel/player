package phanan.koel.shared

import io.ktor.http.HttpMethod
import kotlinx.coroutines.test.TestScope
import kotlinx.coroutines.test.UnconfinedTestDispatcher
import kotlinx.coroutines.test.runTest
import kotlinx.serialization.json.JsonArray
import kotlinx.serialization.json.buildJsonObject
import kotlinx.serialization.json.put
import kotlinx.serialization.json.putJsonObject
import phanan.koel.shared.player.FakeAudioEngine
import phanan.koel.shared.session.Feature
import phanan.koel.shared.support.Fixtures
import phanan.koel.shared.support.Harness
import phanan.koel.shared.support.temporaryDirectory
import kotlin.test.Test
import kotlin.test.assertEquals
import kotlin.test.assertFalse
import kotlin.test.assertNull
import kotlin.test.assertTrue

class KoelCoreTest {
    private val h = Harness()

    private fun TestScope.core() =
        KoelCore(h.keyValueStore, temporaryDirectory().toString(), FakeAudioEngine(), h.engine, backgroundScope)

    private fun dataResponse(version: String = "v8.1.0") = buildJsonObject {
        put("current_version", version)
        put("cdn_url", "https://cdn.koel.test/")
        put("transcoding", true)
        put("use_last_fm", true)
        put("song_count", 42)
        put("playlists", JsonArray(listOf(Fixtures.playlist("p1"), Fixtures.playlist("p2", isSmart = true))))
        put("playlist_folders", JsonArray(listOf(Fixtures.folder("f1"))))
        putJsonObject("queue_state") {
            put("songs", JsonArray(listOf(Fixtures.song("s1"), Fixtures.song("s2"))))
            put("current_song", Fixtures.song("s2"))
            put("playback_position", 12)
        }
    }.toString()

    @Test
    fun loadingDataSeedsServerInfoLibraryAndQueue() = runTest(UnconfinedTestDispatcher()) {
        h.on(HttpMethod.Get, "data") { dataResponse() }
        h.on(HttpMethod.Put, "queue/state") { "" }
        h.on(HttpMethod.Put, "queue/playback-status") { "" }
        val core = core()

        core.loadData()

        val info = core.session.serverInfo.value!!
        assertEquals(42, info.songCount)
        assertTrue(info.transcoding)
        assertTrue(core.session.supports(Feature.RADIO_STATIONS))
        assertFalse(core.session.supports(Feature.CUSTOM_FAVORITES_ORDER))
        assertEquals(listOf("p1", "p2"), core.playlists.playlists.value.map { it.id })
        assertEquals(listOf("f1"), core.playlistFolders.folders.value.map { it.id })
        assertEquals(listOf("s1", "s2"), core.player.state.value.queue.map { it.id })
        assertEquals("s2", core.player.state.value.current?.id)
        assertTrue(core.session.sourceUrl(core.playables.byId("s1")!!).startsWith("https://cdn.koel.test/play/s1/1/128"))
    }

    @Test
    fun oldServersStillLoadWithoutFoldersOrQueueSync() = runTest(UnconfinedTestDispatcher()) {
        h.on(HttpMethod.Get, "data") {
            buildJsonObject {
                put("current_version", "v5.1.0")
                put("playlists", JsonArray(emptyList()))
            }.toString()
        }
        val core = core()

        core.loadData()

        assertFalse(core.session.supports(Feature.QUEUE_STATE_SYNC))
        assertTrue(core.playlistFolders.folders.value.isEmpty())
        assertTrue(core.player.state.value.queue.isEmpty())
    }

    @Test
    fun loggingOutForgetsTheUserAndTheirLibrary() = runTest(UnconfinedTestDispatcher()) {
        h.on(HttpMethod.Get, "data") { dataResponse() }
        h.on(HttpMethod.Put, "queue/state") { "" }
        h.on(HttpMethod.Put, "queue/playback-status") { "" }
        h.on(HttpMethod.Delete, "me") { "" }
        val core = core()
        core.loadData()

        core.logout()

        assertNull(h.preferences.apiToken)
        assertNull(core.session.serverInfo.value)
        assertTrue(core.playlists.playlists.value.isEmpty())
        assertTrue(core.player.state.value.queue.isEmpty())
        assertNull(core.playables.byId("s1"))
    }
}
