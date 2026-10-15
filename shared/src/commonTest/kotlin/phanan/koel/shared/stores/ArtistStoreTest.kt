package phanan.koel.shared.stores

import io.ktor.http.HttpMethod
import kotlinx.coroutines.flow.first
import kotlinx.coroutines.test.UnconfinedTestDispatcher
import kotlinx.coroutines.test.runTest
import kotlinx.serialization.json.buildJsonObject
import kotlinx.serialization.json.put
import phanan.koel.shared.api.HttpResponseException
import phanan.koel.shared.models.ArtistSortField
import phanan.koel.shared.models.Song
import phanan.koel.shared.models.SortOrder
import phanan.koel.shared.support.Fixtures
import phanan.koel.shared.support.Harness
import kotlin.test.Test
import kotlin.test.assertEquals
import kotlin.test.assertFailsWith
import kotlin.test.assertFalse
import kotlin.test.assertNull
import kotlin.test.assertTrue

class ArtistStoreTest {
    private val h = Harness()
    private val playables = PlayableStore(h.api)
    private val albums = AlbumStore(h.api, playables)
    private val store = ArtistStore(h.api, playables, albums)

    private suspend fun seedArtist(id: String = "ar1", name: String = "Artist $id", favorite: Boolean = false) {
        h.on(HttpMethod.Get, "artists/$id") { Fixtures.artist(id, name = name, favorite = favorite).toString() }
        store.resolve(id)
    }

    @Test
    fun paginatesUntilTheLastPage() = runTest(UnconfinedTestDispatcher()) {
        h.on(HttpMethod.Get, "artists?page=1&sort=name&order=asc") {
            Fixtures.page(listOf(Fixtures.artist("ar1")), currentPage = 1, hasNext = true).toString()
        }
        h.on(HttpMethod.Get, "artists?page=2&sort=name&order=asc") {
            Fixtures.page(listOf(Fixtures.artist("ar2")), currentPage = 2).toString()
        }

        store.loadMore()
        store.loadMore()

        assertEquals(listOf("ar1", "ar2"), store.items.value.map { it.id })
        assertFalse(store.hasMore.value)
    }

    @Test
    fun switchingTheSortFieldGoesBackToAscending() = runTest(UnconfinedTestDispatcher()) {
        h.on(HttpMethod.Get, "artists") { Fixtures.page(listOf(Fixtures.artist("ar1"))).toString() }

        store.refresh(ArtistSortField.NAME, SortOrder.DESC)
        store.refresh(ArtistSortField.CREATED_AT)

        assertEquals(
            listOf("artists?page=1&sort=name&order=desc", "artists?page=1&sort=created_at&order=asc"),
            h.requests.map { it.path },
        )
        assertEquals(SortOrder.ASC, store.sortOrder)
    }

    @Test
    fun resolvesFromTheVaultUntilForcedToRefresh() = runTest(UnconfinedTestDispatcher()) {
        seedArtist()

        store.resolve("ar1")
        store.resolve("ar1", forceRefresh = true)

        assertEquals(2, h.requestsTo(HttpMethod.Get, "artists/ar1").size)
    }

    @Test
    fun togglingFavoriteFlipsOptimisticallyAndPostsTheArtist() = runTest(UnconfinedTestDispatcher()) {
        seedArtist(favorite = false)
        var favoriteDuringRequest: Boolean? = null
        h.onRequest(HttpMethod.Post, "favorites/toggle") {
            favoriteDuringRequest = store.byId("ar1")?.favorite
            Harness.Reply(200, "{}")
        }

        store.toggleFavorite(store.byId("ar1")!!)

        assertEquals(true, favoriteDuringRequest)
        assertTrue(store.observe("ar1").first()!!.favorite)
        assertEquals(buildJsonObject { put("type", "artist"); put("id", "ar1") }, h.requests.last().json)
    }

    @Test
    fun togglingFavoriteRollsBackAndRethrowsOnFailure() = runTest(UnconfinedTestDispatcher()) {
        seedArtist(favorite = true)
        h.on(HttpMethod.Post, "favorites/toggle", status = 500) { "{}" }

        assertFailsWith<HttpResponseException> { store.toggleFavorite(store.byId("ar1")!!) }

        assertTrue(store.byId("ar1")!!.favorite)
        assertEquals(1, h.requestsTo(HttpMethod.Post, "favorites/toggle").size)
    }

    @Test
    fun updatingPutsTheNameAndAppliesTheServerResponse() = runTest(UnconfinedTestDispatcher()) {
        seedArtist(name = "Old")
        h.on(HttpMethod.Put, "artists/ar1") { """{"id":"ar1","name":"Renamed"}""" }

        val updated = store.update(store.byId("ar1")!!, name = "Renamed")

        assertEquals(buildJsonObject { put("name", "Renamed") }, h.requests.last().json)
        assertEquals("Renamed", updated.name)
        assertEquals("Renamed", store.byId("ar1")!!.name)
    }

    @Test
    fun renamingPropagatesToSongsAndAlbums() = runTest(UnconfinedTestDispatcher()) {
        seedArtist(name = "Old")
        h.on(HttpMethod.Get, "artists/ar1/songs") {
            Fixtures.list(Fixtures.song("s1", artistId = "ar1", artistName = "Old"), Fixtures.song("s2", artistId = "other"))
        }
        playables.fetchForArtist("ar1")
        h.on(HttpMethod.Get, "albums") {
            Fixtures.page(listOf(Fixtures.album("al1", artistId = "ar1"), Fixtures.album("al2", artistId = "other"))).toString()
        }
        albums.loadMore()
        h.on(HttpMethod.Put, "artists/ar1") { """{"name":"New Artist"}""" }

        store.update(store.byId("ar1")!!, name = "New Artist")

        val renamed = playables.byId("s1") as Song
        assertEquals("New Artist", renamed.artistName)
        assertEquals("New Artist", renamed.albumArtistName)
        assertEquals("Artist", (playables.byId("s2") as Song).artistName)
        assertEquals("New Artist", albums.byId("al1")!!.artistName)
        assertEquals("Artist", albums.byId("al2")!!.artistName)
    }

    @Test
    fun renamingAnAlbumArtistLeavesTheTrackArtistAlone() = runTest(UnconfinedTestDispatcher()) {
        seedArtist(id = "aa1", name = "Old AA")
        h.on(HttpMethod.Get, "albums/al1/songs") {
            Fixtures.list(
                Fixtures.song("s1", artistId = "ft1", artistName = "Featured", albumArtistId = "aa1", albumArtistName = "Old AA"),
            )
        }
        playables.fetchForAlbum("al1")
        h.on(HttpMethod.Put, "artists/aa1") { """{"name":"Renamed AA"}""" }

        store.update(store.byId("aa1")!!, name = "Renamed AA")

        val song = playables.byId("s1") as Song
        assertEquals("Renamed AA", song.albumArtistName)
        assertEquals("Featured", song.artistName)
    }

    @Test
    fun resetForgetsEverything() = runTest(UnconfinedTestDispatcher()) {
        seedArtist()
        h.on(HttpMethod.Get, "artists") { Fixtures.page(listOf(Fixtures.artist("ar1"))).toString() }
        store.loadMore()

        store.reset()

        assertEquals(emptyList(), store.items.value)
        assertNull(store.byId("ar1"))
    }
}
