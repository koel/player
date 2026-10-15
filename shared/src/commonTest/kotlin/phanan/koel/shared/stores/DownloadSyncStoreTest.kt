package phanan.koel.shared.stores

import io.ktor.http.HttpMethod
import kotlinx.coroutines.CoroutineScope
import kotlinx.coroutines.flow.first
import kotlinx.coroutines.test.UnconfinedTestDispatcher
import kotlinx.coroutines.test.advanceTimeBy
import kotlinx.coroutines.test.runTest
import kotlinx.coroutines.yield
import kotlinx.io.files.Path
import kotlinx.serialization.json.jsonArray
import kotlinx.serialization.json.jsonObject
import kotlinx.serialization.json.jsonPrimitive
import phanan.koel.shared.json.KoelJson
import phanan.koel.shared.models.Playable
import phanan.koel.shared.support.Fixtures
import phanan.koel.shared.support.Harness
import phanan.koel.shared.support.readText
import phanan.koel.shared.support.temporaryDirectory
import kotlin.test.Test
import kotlin.test.assertEquals
import kotlin.test.assertFalse
import kotlin.test.assertNotNull
import kotlin.test.assertNull
import kotlin.test.assertTrue
import kotlin.time.Duration.Companion.minutes

class DownloadSyncStoreTest {
    private val h = Harness()
    private val documents = temporaryDirectory()
    private val playableStore = PlayableStore(h.api)

    private fun song(id: String, title: String = "Song $id"): Playable =
        KoelJson.decodeFromJsonElement(Playable.serializer(), Fixtures.song(id, title = title))

    private suspend fun CoroutineScope.downloadsOf(vararg ids: String): DownloadStore {
        val downloads = DownloadStore(h.api, playableStore, h.session, h.preferences, documents.toString(), this)
        ids.forEach { id ->
            h.on(HttpMethod.Get, "/play/$id") { "audio of $id" }
            downloads.download(song(id))
        }
        return downloads
    }

    @Test
    fun removesDownloadsGoneFromTheServerAndUpdatesChangedOnes() = runTest(UnconfinedTestDispatcher()) {
        val downloads = backgroundScope.downloadsOf("s1", "s2", "s3")
        val sync = DownloadSyncStore(h.api, downloads, playableStore, backgroundScope)
        h.on(HttpMethod.Post, "songs/by-ids") {
            Fixtures.list(Fixtures.song("s1", title = "Renamed"), Fixtures.song("s2"))
        }

        sync.sync()
        yield()

        assertEquals(listOf("s1", "s2", "s3"), h.requestsTo(HttpMethod.Post, "songs/by-ids").single().json
            .getValue("ids").jsonArray.map { it.jsonPrimitive.content })
        assertEquals(listOf("s1", "s2"), downloads.playables.value.map { it.id })
        assertEquals("Renamed", playableStore.byId("s1")?.title)
        assertEquals(DownloadSyncResult(updatedCount = 1, removedCount = 1), sync.lastSyncResult.value)
        assertFalse(sync.syncing.value)

        val stored = KoelJson.parseToJsonElement(Path(documents, "Downloads.gs").readText()).jsonObject
            .getValue("https://koel.test.me@koel.test.songs").jsonArray
        assertEquals(listOf("Renamed", "Song s2"), stored.map { it.jsonObject.getValue("title").jsonPrimitive.content })
    }

    @Test
    fun recordsAFailureWithoutTouchingDownloads() = runTest(UnconfinedTestDispatcher()) {
        val downloads = backgroundScope.downloadsOf("s1")
        val sync = DownloadSyncStore(h.api, downloads, playableStore, backgroundScope)
        h.on(HttpMethod.Post, "songs/by-ids", status = 500) { "{}" }

        sync.sync()

        assertNotNull(sync.lastSyncResult.value?.error)
        assertEquals(listOf("s1"), downloads.playables.value.map { it.id })
    }

    @Test
    fun skipsTheServerWhenNothingIsDownloaded() = runTest(UnconfinedTestDispatcher()) {
        val sync = DownloadSyncStore(h.api, backgroundScope.downloadsOf(), playableStore, backgroundScope)

        sync.sync()

        assertTrue(h.requests.isEmpty())
    }

    @Test
    fun syncsFiveMinutesAfterTheLastRequest() = runTest(UnconfinedTestDispatcher()) {
        val downloads = backgroundScope.downloadsOf("s1")
        val sync = DownloadSyncStore(h.api, downloads, playableStore, backgroundScope)
        h.on(HttpMethod.Post, "songs/by-ids") { Fixtures.list(Fixtures.song("s1")) }

        sync.syncAfterDelay()
        advanceTimeBy(3.minutes)
        sync.syncAfterDelay()
        advanceTimeBy(3.minutes)
        assertFalse(sync.syncing.value)
        assertNull(sync.lastSyncResult.value)

        advanceTimeBy(3.minutes)
        sync.lastSyncResult.first { it != null }
        assertEquals(1, h.requestsTo(HttpMethod.Post, "songs/by-ids").size)
    }
}
