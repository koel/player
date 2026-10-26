package phanan.koel.shared.stores

import io.ktor.http.HttpMethod
import kotlinx.coroutines.flow.first
import kotlinx.coroutines.test.UnconfinedTestDispatcher
import kotlinx.coroutines.test.runTest
import kotlinx.serialization.json.JsonNull
import kotlinx.serialization.json.JsonObject
import kotlinx.serialization.json.jsonPrimitive
import phanan.koel.shared.api.HttpResponseException
import phanan.koel.shared.json.KoelJson
import phanan.koel.shared.models.Playlist
import phanan.koel.shared.support.Fixtures
import phanan.koel.shared.support.Harness
import kotlin.test.Test
import kotlin.test.assertEquals
import kotlin.test.assertFailsWith
import kotlin.test.assertNull
import kotlin.test.assertTrue

class PlaylistStoreTest {
    private val h = Harness()
    private val playables = PlayableStore(h.api)
    private val store = PlaylistStore(h.api, playables)

    private fun playlist(json: JsonObject) = KoelJson.decodeFromJsonElement(Playlist.serializer(), json)

    private fun seed(vararg playlists: JsonObject): List<Playlist> = playlists.map(::playlist).also(store::seed)

    @Test
    fun seedingSeparatesStandardPlaylistsFromSmartOnes() {
        seed(Fixtures.playlist("p1"), Fixtures.playlist("p2", isSmart = true))

        assertEquals(listOf("p1", "p2"), store.playlists.value.map { it.id })
        assertEquals(listOf("p1"), store.standardPlaylists.value.map { it.id })
    }

    @Test
    fun fetchingAllReplacesTheList() = runTest(UnconfinedTestDispatcher()) {
        seed(Fixtures.playlist("old"))
        h.on(HttpMethod.Get, "playlists") { Fixtures.list(Fixtures.playlist("p1"), Fixtures.playlist("p2", isSmart = true)) }

        store.fetchAll()

        assertEquals(listOf("p1", "p2"), store.playlists.value.map { it.id })
        assertEquals(listOf("p1"), store.standardPlaylists.value.map { it.id })
    }

    @Test
    fun addingSongsPostsTheirIdsAndUpdatesTheCachedPlaylistSongs() = runTest(UnconfinedTestDispatcher()) {
        val (target) = seed(Fixtures.playlist("p1"))
        h.on(HttpMethod.Get, "playlists/p1/songs") { Fixtures.list(Fixtures.song("s1")) }
        h.on(HttpMethod.Get, "albums/a1/songs") { Fixtures.list(Fixtures.song("s2"), Fixtures.song("s3")) }
        h.on(HttpMethod.Post, "playlists/p1/songs") { "" }
        playables.fetchForPlaylist("p1")
        val added = playables.fetchForAlbum("a1")

        store.addToPlaylist(added, target)

        assertEquals(KoelJson.parseToJsonElement("""{"songs":["s2","s3"]}"""), h.requestsTo(HttpMethod.Post, "playlists/p1/songs").single().body)
        assertEquals(listOf("s1", "s2", "s3"), playables.playlistSongs("p1").first().map { it.id })
    }

    @Test
    fun removingSongsDeletesTheirIdsAndUpdatesTheCachedPlaylistSongs() = runTest(UnconfinedTestDispatcher()) {
        val (target) = seed(Fixtures.playlist("p1"))
        h.on(HttpMethod.Get, "playlists/p1/songs") { Fixtures.list(Fixtures.song("s1"), Fixtures.song("s2")) }
        h.on(HttpMethod.Delete, "playlists/p1/songs") { "" }
        val songs = playables.fetchForPlaylist("p1")

        store.removeFromPlaylist(listOf(songs.first()), target)

        assertEquals(KoelJson.parseToJsonElement("""{"songs":["s1"]}"""), h.requestsTo(HttpMethod.Delete, "playlists/p1/songs").single().body)
        assertEquals(listOf("s2"), playables.playlistSongs("p1").first().map { it.id })
    }

    @Test
    fun smartPlaylistsCannotBeChangedByHand() = runTest(UnconfinedTestDispatcher()) {
        val (smart) = seed(Fixtures.playlist("p1", isSmart = true))
        h.on(HttpMethod.Get, "albums/a1/songs") { Fixtures.list(Fixtures.song("s1")) }
        val songs = playables.fetchForAlbum("a1")
        h.requests.clear()

        assertFailsWith<IllegalArgumentException> { store.addToPlaylist(songs, smart) }
        assertFailsWith<IllegalArgumentException> { store.removeFromPlaylist(songs, smart) }
        assertTrue(h.requests.isEmpty())
    }

    @Test
    fun movingIntoAFolderPostsThePlaylistIdAndRecordsTheFolder() = runTest(UnconfinedTestDispatcher()) {
        val (target) = seed(Fixtures.playlist("p1"))
        h.on(HttpMethod.Post, "playlist-folders/f1/playlists") { "" }

        store.addToFolder(target, "f1")

        assertEquals(KoelJson.parseToJsonElement("""{"playlists":["p1"]}"""), h.requests.single().body)
        assertEquals("f1", store.byId("p1")?.folderId)
    }

    @Test
    fun creatingSendsEveryFieldAndAppendsThePlaylist() = runTest(UnconfinedTestDispatcher()) {
        seed(Fixtures.playlist("p1"))
        h.on(HttpMethod.Post, "playlists") { Fixtures.playlist("p2", name = "Road Trip", folderId = "f1").toString() }

        val created = store.create("Road Trip", description = "Long drives", folderId = "f1")

        assertEquals(
            KoelJson.parseToJsonElement("""{"name":"Road Trip","description":"Long drives","folder_id":"f1"}"""),
            h.requests.single().body,
        )
        assertEquals("p2", created.id)
        assertEquals(listOf("p1", "p2"), store.playlists.value.map { it.id })
        assertEquals(listOf("p1", "p2"), store.standardPlaylists.value.map { it.id })
    }

    @Test
    fun creatingOmitsAnEmptyDescriptionAndAMissingFolder() = runTest(UnconfinedTestDispatcher()) {
        h.on(HttpMethod.Post, "playlists") { Fixtures.playlist("p1").toString() }

        store.create("Plain", description = "")

        assertEquals(KoelJson.parseToJsonElement("""{"name":"Plain"}"""), h.requests.single().body)
    }

    @Test
    fun updatingPutsEveryFieldAndAppliesThemLocally() = runTest(UnconfinedTestDispatcher()) {
        val (target) = seed(Fixtures.playlist("p1", folderId = "f1"))
        h.on(HttpMethod.Put, "playlists/p1") { "" }

        store.update(target, name = "Renamed", description = null, folderId = null)

        val body = h.requests.single().json
        assertEquals("Renamed", body.getValue("name").jsonPrimitive.content)
        assertEquals("", body.getValue("description").jsonPrimitive.content)
        assertEquals(JsonNull, body.getValue("folder_id"))

        val updated = store.byId("p1")!!
        assertEquals("Renamed", updated.name)
        assertNull(updated.description)
        assertNull(updated.folderId)
        assertEquals("Renamed", store.standardPlaylists.value.single().name)
    }

    @Test
    fun updatingASmartPlaylistSendsItsRulesBack() = runTest(UnconfinedTestDispatcher()) {
        val rules = KoelJson.parseToJsonElement(
            """[{"id":"g1","rules":[{"id":"r1","model":"title","operator":"contains","value":["love"]}]}]"""
        )
        val (smart) = seed(JsonObject(Fixtures.playlist("p1", isSmart = true) + ("rules" to rules)))
        h.on(HttpMethod.Put, "playlists/p1") { "" }

        store.update(smart, name = "Renamed", folderId = "f1")

        assertEquals(rules, h.requests.single().json.getValue("rules"))
    }

    @Test
    fun removingDropsThePlaylistBeforeTheServerAnswers() = runTest(UnconfinedTestDispatcher()) {
        val (first) = seed(Fixtures.playlist("p1"), Fixtures.playlist("p2"))
        h.on(HttpMethod.Get, "playlists/p1/songs") { Fixtures.list(Fixtures.song("s1")) }
        playables.fetchForPlaylist("p1")

        var idsDuringRequest = emptyList<String>()
        h.onRequest(HttpMethod.Delete, "playlists/p1") {
            idsDuringRequest = store.playlists.value.map { it.id }
            Harness.Reply(200, "")
        }

        store.remove(first)

        assertEquals(listOf("p2"), idsDuringRequest)
        assertEquals(listOf("p2"), store.playlists.value.map { it.id })
        assertEquals(listOf("p2"), store.standardPlaylists.value.map { it.id })
        assertTrue(playables.playlistSongs("p1").first().isEmpty())
    }

    @Test
    fun removingRestoresThePlaylistInPlaceWhenTheServerRefuses() = runTest(UnconfinedTestDispatcher()) {
        val (first) = seed(Fixtures.playlist("p1"), Fixtures.playlist("p2"))
        h.on(HttpMethod.Delete, "playlists/p1", status = 500) { "" }

        assertFailsWith<HttpResponseException> { store.remove(first) }

        assertEquals(listOf("p1", "p2"), store.playlists.value.map { it.id })
        assertEquals(listOf("p1", "p2"), store.standardPlaylists.value.map { it.id })
    }

    @Test
    fun resettingForgetsEveryPlaylist() {
        seed(Fixtures.playlist("p1"))

        store.reset()

        assertTrue(store.playlists.value.isEmpty())
        assertTrue(store.standardPlaylists.value.isEmpty())
    }
}
