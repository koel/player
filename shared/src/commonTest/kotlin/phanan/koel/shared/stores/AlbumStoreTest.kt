package phanan.koel.shared.stores

import io.ktor.http.HttpMethod
import kotlinx.coroutines.flow.first
import kotlinx.coroutines.test.UnconfinedTestDispatcher
import kotlinx.coroutines.test.runTest
import kotlinx.serialization.json.JsonNull
import kotlinx.serialization.json.buildJsonObject
import kotlinx.serialization.json.put
import phanan.koel.shared.api.HttpResponseException
import phanan.koel.shared.models.AlbumSortField
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

class AlbumStoreTest {
    private val h = Harness()
    private val playables = PlayableStore(h.api)
    private val store = AlbumStore(h.api, playables)

    private suspend fun seedAlbum(id: String = "a1", name: String = "Album $id", favorite: Boolean = false) {
        h.on(HttpMethod.Get, "albums/$id") { Fixtures.album(id, name = name, favorite = favorite).toString() }
        store.resolve(id)
    }

    @Test
    fun paginatesSortedByNameUntilTheLastPage() = runTest(UnconfinedTestDispatcher()) {
        h.on(HttpMethod.Get, "albums?page=1&sort=name&order=asc") {
            Fixtures.page(listOf(Fixtures.album("a1"), Fixtures.album("a2")), currentPage = 1, hasNext = true).toString()
        }
        h.on(HttpMethod.Get, "albums?page=2&sort=name&order=asc") {
            Fixtures.page(listOf(Fixtures.album("a2"), Fixtures.album("a3")), currentPage = 2).toString()
        }

        store.loadMore()
        assertTrue(store.hasMore.value)
        store.loadMore()
        store.loadMore()

        assertEquals(listOf("a1", "a2", "a3"), store.items.value.map { it.id })
        assertFalse(store.hasMore.value)
        assertEquals(2, h.requestsTo(HttpMethod.Get, "albums").size)
    }

    @Test
    fun switchingTheSortFieldGoesBackToAscendingUnlessAnOrderIsGiven() = runTest(UnconfinedTestDispatcher()) {
        h.on(HttpMethod.Get, "albums") { Fixtures.page(listOf(Fixtures.album("a1"))).toString() }

        store.refresh(AlbumSortField.NAME, SortOrder.DESC)
        store.refresh(AlbumSortField.NAME)
        store.refresh(AlbumSortField.YEAR)
        store.refresh(AlbumSortField.ARTIST_NAME, SortOrder.DESC)

        assertEquals(
            listOf(
                "albums?page=1&sort=name&order=desc",
                "albums?page=1&sort=name&order=desc",
                "albums?page=1&sort=year&order=asc",
                "albums?page=1&sort=artist_name&order=desc",
            ),
            h.requests.map { it.path },
        )
    }

    @Test
    fun resolvesFromTheVaultUntilForcedToRefresh() = runTest(UnconfinedTestDispatcher()) {
        var name = "First"
        h.on(HttpMethod.Get, "albums/a1") { Fixtures.album("a1", name = name).toString() }

        store.resolve("a1")
        name = "Second"

        assertEquals("First", store.resolve("a1").name)
        assertEquals("Second", store.resolve("a1", forceRefresh = true).name)
        assertEquals("Second", store.byId("a1")?.name)
        assertEquals(2, h.requestsTo(HttpMethod.Get, "albums/a1").size)
    }

    @Test
    fun togglingFavoriteFlipsOptimisticallyAndPostsTheAlbum() = runTest(UnconfinedTestDispatcher()) {
        seedAlbum(favorite = false)
        var favoriteDuringRequest: Boolean? = null
        h.onRequest(HttpMethod.Post, "favorites/toggle") {
            favoriteDuringRequest = store.byId("a1")?.favorite
            Harness.Reply(200, "{}")
        }

        store.toggleFavorite(store.byId("a1")!!)

        assertEquals(true, favoriteDuringRequest)
        assertTrue(store.byId("a1")!!.favorite)
        val request = h.requestsTo(HttpMethod.Post, "favorites/toggle").single()
        assertEquals(buildJsonObject { put("type", "album"); put("id", "a1") }, request.json)
    }

    @Test
    fun togglingFavoriteRollsBackAndRethrowsOnFailure() = runTest(UnconfinedTestDispatcher()) {
        seedAlbum(favorite = true)
        h.on(HttpMethod.Post, "favorites/toggle", status = 500) { "{}" }

        assertFailsWith<HttpResponseException> { store.toggleFavorite(store.byId("a1")!!) }

        assertTrue(store.byId("a1")!!.favorite)
    }

    @Test
    fun updatingPutsTheFieldsAndAppliesTheServerResponse() = runTest(UnconfinedTestDispatcher()) {
        seedAlbum(name = "Old Name")
        h.on(HttpMethod.Put, "albums/a1") { """{"id":"a1","name":"New Name","year":"1969"}""" }

        val updated = store.update(store.byId("a1")!!, name = "New Name", year = 1969)

        val request = h.requestsTo(HttpMethod.Put, "albums/a1").single()
        assertEquals(buildJsonObject { put("name", "New Name"); put("year", 1969) }, request.json)
        assertEquals("New Name", updated.name)
        assertEquals(1969, updated.year)
        assertEquals(updated, store.byId("a1"))
    }

    @Test
    fun aNullYearInTheResponseClearsTheYear() = runTest(UnconfinedTestDispatcher()) {
        seedAlbum()
        h.on(HttpMethod.Put, "albums/a1") { """{"name":"No Year","year":null}""" }

        store.update(store.byId("a1")!!, name = "No Year", year = null)

        assertEquals(JsonNull, h.requests.last().json["year"])
        assertNull(store.byId("a1")!!.year)
    }

    @Test
    fun renamingPropagatesToTheAlbumsSongs() = runTest(UnconfinedTestDispatcher()) {
        seedAlbum(name = "Old")
        h.on(HttpMethod.Get, "albums/a1/songs") {
            Fixtures.list(Fixtures.song("s1", albumId = "a1", albumName = "Old"), Fixtures.song("s2", albumId = "other"))
        }
        playables.fetchForAlbum("a1")
        h.on(HttpMethod.Put, "albums/a1") { """{"name":"New Album","year":null}""" }

        store.update(store.byId("a1")!!, name = "New Album", year = null)

        assertEquals("New Album", (playables.byId("s1") as Song).albumName)
        assertEquals("Album", (playables.byId("s2") as Song).albumName)
    }

    @Test
    fun keepingTheNameLeavesSongsAlone() = runTest(UnconfinedTestDispatcher()) {
        seedAlbum(name = "Same Name")
        h.on(HttpMethod.Get, "albums/a1/songs") { Fixtures.list(Fixtures.song("s1", albumId = "a1", albumName = "Stale")) }
        playables.fetchForAlbum("a1")
        h.on(HttpMethod.Put, "albums/a1") { """{"name":"Same Name","year":2001}""" }

        store.update(store.byId("a1")!!, name = "Same Name", year = 2001)

        assertEquals("Stale", (playables.byId("s1") as Song).albumName)
    }

    @Test
    fun observingFollowsChangesToTheAlbum() = runTest(UnconfinedTestDispatcher()) {
        seedAlbum()
        h.on(HttpMethod.Post, "favorites/toggle") { "{}" }

        store.toggleFavorite(store.byId("a1")!!)

        assertTrue(store.observe("a1").first()!!.favorite)
        assertNull(store.observe("missing").first())
    }

    @Test
    fun listsFollowArtistRenames() = runTest(UnconfinedTestDispatcher()) {
        h.on(HttpMethod.Get, "albums") {
            Fixtures.page(listOf(Fixtures.album("a1", artistId = "ar1"), Fixtures.album("a2", artistId = "ar2"))).toString()
        }
        store.loadMore()

        store.applyArtistRename("ar1", "Rebranded")

        assertEquals(listOf("Rebranded", "Artist"), store.items.value.map { it.artistName })
    }

    @Test
    fun resetForgetsEverything() = runTest(UnconfinedTestDispatcher()) {
        h.on(HttpMethod.Get, "albums") { Fixtures.page(listOf(Fixtures.album("a1"))).toString() }
        store.loadMore()

        store.reset()

        assertEquals(emptyList(), store.items.value)
        assertNull(store.byId("a1"))
        assertTrue(store.hasMore.value)
    }
}
