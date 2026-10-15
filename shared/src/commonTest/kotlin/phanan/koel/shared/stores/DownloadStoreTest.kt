package phanan.koel.shared.stores

import io.ktor.http.HttpMethod
import kotlinx.coroutines.CoroutineScope
import kotlinx.coroutines.test.UnconfinedTestDispatcher
import kotlinx.coroutines.yield
import kotlinx.coroutines.test.runTest
import kotlinx.io.files.Path
import kotlinx.serialization.json.JsonArray
import kotlinx.serialization.json.JsonObject
import kotlinx.serialization.json.boolean
import kotlinx.serialization.json.jsonArray
import kotlinx.serialization.json.jsonObject
import kotlinx.serialization.json.jsonPrimitive
import phanan.koel.shared.json.KoelJson
import phanan.koel.shared.models.Playable
import phanan.koel.shared.support.Fixtures
import phanan.koel.shared.support.Harness
import phanan.koel.shared.support.exists
import phanan.koel.shared.support.readText
import phanan.koel.shared.support.temporaryDirectory
import phanan.koel.shared.support.writeText
import kotlin.test.Test
import kotlin.test.assertEquals
import kotlin.test.assertFailsWith
import kotlin.test.assertFalse
import kotlin.test.assertNull
import kotlin.test.assertTrue

class DownloadStoreTest {
    private val h = Harness()
    private val documents = temporaryDirectory()
    private val playableStore = PlayableStore(h.api)

    /** sha256("https://koel.test" + "me@koel.test"), as the Flutter app computed it. */
    private val userDirectory = Path(documents, "3c45a7678675b4b10b0c258aa8d0adb2799d721e0b2df2ceeffea9d802b8ce7b")
    private val metadataFile = Path(documents, "Downloads.gs")
    private val metadataKey = "https://koel.test.me@koel.test.songs"

    private fun CoroutineScope.store() =
        DownloadStore(h.api, playableStore, h.session, h.preferences, documents.toString(), this)

    private fun song(id: String, favorite: Boolean = false): Playable =
        KoelJson.decodeFromJsonElement(Playable.serializer(), Fixtures.song(id, favorite = favorite))

    private fun serveAudio(id: String, content: String = "audio of $id") =
        h.on(HttpMethod.Get, "/play/$id") { content }

    private fun storedMetadata(): JsonObject = KoelJson.parseToJsonElement(metadataFile.readText()).jsonObject

    private fun storedPlayables(): List<JsonObject> =
        storedMetadata()[metadataKey]?.jsonArray?.map { it.jsonObject }.orEmpty()

    @Test
    fun downloadsIntoTheFlutterLayoutAndPersistsMetadata() = runTest(UnconfinedTestDispatcher()) {
        val store = backgroundScope.store()
        serveAudio("s1")

        store.download(song("s1"))

        val file = Path(userDirectory, "CACHE_s1.mp3")
        assertEquals("audio of s1", file.readText())
        assertTrue(store.isDownloaded(song("s1")))
        assertEquals(setOf("s1"), store.downloadedIds.value)
        assertEquals(emptySet(), store.downloading.value)
        assertEquals("file://$file", store.localFileUrl(song("s1")))
        assertEquals(listOf("s1"), store.playables.value.map { it.id })
        assertEquals(listOf("s1"), storedPlayables().map { it.getValue("id").jsonPrimitive.content })
        assertEquals("/play/s1?t=audio-token", h.requests.single().path)
    }

    @Test
    fun downloadingAgainReplacesTheFile() = runTest(UnconfinedTestDispatcher()) {
        val store = backgroundScope.store()
        serveAudio("s1", "old")
        store.download(song("s1"))

        serveAudio("s1", "new")
        store.download(song("s1"))

        assertEquals("new", Path(userDirectory, "CACHE_s1.mp3").readText())
        assertEquals(1, storedPlayables().size)
    }

    @Test
    fun aFailedDownloadLeavesNothingBehind() = runTest(UnconfinedTestDispatcher()) {
        val store = backgroundScope.store()
        h.on(HttpMethod.Get, "/play/s1", status = 404) { "Not found" }

        assertFailsWith<Exception> { store.download(song("s1")) }

        assertFalse(store.isDownloaded(song("s1")))
        assertFalse(Path(userDirectory, "CACHE_s1.mp3").exists())
        assertFalse(Path(userDirectory, "CACHE_s1.mp3.part").exists())
        assertEquals(emptySet(), store.downloading.value)
        assertNull(store.localFileUrl(song("s1")))
    }

    @Test
    fun restoresFlutterDownloadsAndSkipsThoseWithoutAFile() = runTest(UnconfinedTestDispatcher()) {
        metadataFile.writeText(
            """
            {"other.key":"kept","$metadataKey":[
              {"type":"songs","id":"s1","title":"Song One","lyrics":"","length":215.5,"track":3,
               "created_at":"2024-01-01T00:00:00.000Z","artist_id":"ar1","artist_name":"Artist",
               "album_id":"al1","album_name":"Album","album_cover":"https://koel.test/a.jpg",
               "album_artist_id":"ar1","album_artist_name":"Artist","disc":1,"year":null,"genre":"","liked":true},
              {"type":"episodes","id":"e1","length":1800,"title":"Episode One","podcast_id":"p1",
               "podcast_title":"Podcast","podcast_author":"Host","episode_description":"",
               "episode_image":null,"episode_link":null,"created_at":"2024-01-01T00:00:00.000Z"},
              {"type":"songs","id":"s2","title":"Gone","liked":false}
            ]}
            """.trimIndent(),
        )
        Path(userDirectory, "CACHE_s1.mp3").writeText("one")
        Path(userDirectory, "CACHE_e1.mp3").writeText("episode")

        val store = backgroundScope.store()

        assertEquals(listOf("s1", "e1"), store.playables.value.map { it.id })
        assertTrue(store.playables.value.first().favorite)
        assertEquals("Song One", playableStore.byId("s1")?.title)
        assertFalse(store.isDownloaded(song("s2")))
        assertEquals("kept", storedMetadata().getValue("other.key").jsonPrimitive.content)
    }

    @Test
    fun persistsMetadataWhenADownloadedPlayableChangesInTheVault() = runTest(UnconfinedTestDispatcher()) {
        val store = backgroundScope.store()
        serveAudio("s1")
        store.download(song("s1"))

        playableStore.update("s1") { it.withFavorite(true) }
        yield()

        assertTrue(storedPlayables().single().getValue("favorite").jsonPrimitive.boolean)

        playableStore.reset()
        val restored = backgroundScope.store()
        assertTrue(restored.playables.value.single().favorite)
    }

    @Test
    fun removesOneDownload() = runTest(UnconfinedTestDispatcher()) {
        val store = backgroundScope.store()
        serveAudio("s1")
        serveAudio("s2")
        store.download(song("s1"))
        store.download(song("s2"))

        store.remove(song("s1"))

        assertFalse(Path(userDirectory, "CACHE_s1.mp3").exists())
        assertTrue(Path(userDirectory, "CACHE_s2.mp3").exists())
        assertEquals(listOf("s2"), store.playables.value.map { it.id })
        assertEquals(listOf("s2"), storedPlayables().map { it.getValue("id").jsonPrimitive.content })
    }

    @Test
    fun clearingDeletesEveryFileAndTheMetadata() = runTest(UnconfinedTestDispatcher()) {
        metadataFile.writeText("""{"other.key":"kept"}""")
        val store = backgroundScope.store()
        serveAudio("s1")
        serveAudio("s2")
        store.download(song("s1"))
        store.download(song("s2"))

        store.clear()

        assertFalse(Path(userDirectory, "CACHE_s1.mp3").exists())
        assertFalse(Path(userDirectory, "CACHE_s2.mp3").exists())
        assertEquals(emptyList(), store.playables.value)
        assertEquals(setOf("other.key"), storedMetadata().keys)
    }

    @Test
    fun logoutForgetsTheListButKeepsFilesForTheNextLogin() = runTest(UnconfinedTestDispatcher()) {
        val store = backgroundScope.store()
        serveAudio("s1")
        store.download(song("s1"))

        playableStore.reset()
        store.reset()

        assertEquals(emptyList(), store.playables.value)
        assertTrue(Path(userDirectory, "CACHE_s1.mp3").exists())
        assertEquals(1, storedPlayables().size)

        h.preferences.userEmail = "other@koel.test"
        store.load()
        assertEquals(emptyList(), store.playables.value)

        h.preferences.userEmail = "me@koel.test"
        store.load()
        assertEquals(listOf("s1"), store.playables.value.map { it.id })
    }

    @Test
    fun metadataIsWrittenInGetStorageFormatForBothFiles() = runTest(UnconfinedTestDispatcher()) {
        val store = backgroundScope.store()
        serveAudio("s1")
        store.download(song("s1"))

        val backup = Path(documents, "Downloads.bak").readText()
        assertEquals(metadataFile.readText(), backup)
        assertTrue(storedMetadata().getValue(metadataKey) is JsonArray)
    }
}
