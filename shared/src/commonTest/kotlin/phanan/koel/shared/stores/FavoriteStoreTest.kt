package phanan.koel.shared.stores

import io.ktor.http.HttpMethod
import kotlinx.coroutines.test.UnconfinedTestDispatcher
import kotlinx.coroutines.test.runTest
import kotlinx.serialization.json.JsonArray
import kotlinx.serialization.json.JsonPrimitive
import kotlinx.serialization.json.buildJsonObject
import kotlinx.serialization.json.put
import phanan.koel.shared.api.HttpResponseException
import phanan.koel.shared.models.Playable
import phanan.koel.shared.support.Fixtures
import phanan.koel.shared.support.Harness
import kotlin.test.Test
import kotlin.test.assertEquals
import kotlin.test.assertFailsWith
import kotlin.test.assertFalse
import kotlin.test.assertTrue

class FavoriteStoreTest {
    private val h = Harness()
    private val playables = PlayableStore(h.api)
    private val store = FavoriteStore(h.api, playables)

    private fun ids() = store.items.value.map { it.id }

    private suspend fun loadFavorites(vararg ids: String) {
        h.on(HttpMethod.Get, "songs/favorite") {
            Fixtures.list(*ids.map { Fixtures.song(it, favorite = true) }.toTypedArray())
        }
        store.fetch(forceRefresh = true)
    }

    private suspend fun knownSong(id: String, favorite: Boolean = false): Playable {
        h.on(HttpMethod.Get, "albums/$id-album/songs") { Fixtures.list(Fixtures.song(id, favorite = favorite)) }
        return playables.fetchForAlbum("$id-album").single()
    }

    @Test
    fun fetchesFavoritesAndCachesUntilForcedToRefresh() = runTest(UnconfinedTestDispatcher()) {
        h.on(HttpMethod.Get, "songs/favorite") { Fixtures.list(Fixtures.song("s2", favorite = true), Fixtures.episode("e1")) }

        store.fetch()
        store.fetch()
        assertEquals(1, h.requestsTo(HttpMethod.Get, "songs/favorite").size)

        store.fetch(forceRefresh = true)
        assertEquals(2, h.requestsTo(HttpMethod.Get, "songs/favorite").size)
        assertEquals(listOf("s2", "e1"), ids())
    }

    @Test
    fun likingFlipsOptimisticallyAndAddsToTheList() = runTest(UnconfinedTestDispatcher()) {
        loadFavorites("s1")
        val song = knownSong("s2")
        var favoriteDuringRequest: Boolean? = null
        h.onRequest(HttpMethod.Post, "interaction/like") {
            favoriteDuringRequest = playables.byId("s2")?.favorite
            Harness.Reply(200, "{}")
        }

        store.toggle(song)

        assertEquals(true, favoriteDuringRequest)
        assertTrue(playables.byId("s2")!!.favorite)
        assertEquals(listOf("s1", "s2"), ids())
        assertEquals(buildJsonObject { put("song", "s2") }, h.requests.last().json)
    }

    @Test
    fun likingRollsBackAndRethrowsOnFailure() = runTest(UnconfinedTestDispatcher()) {
        val song = knownSong("s1")
        h.on(HttpMethod.Post, "interaction/like", status = 500) { "nope" }

        assertFailsWith<HttpResponseException> { store.toggle(song) }

        assertFalse(playables.byId("s1")!!.favorite)
        assertEquals(emptyList(), ids())
    }

    @Test
    fun togglingAFavoriteUnlikesIt() = runTest(UnconfinedTestDispatcher()) {
        loadFavorites("s1", "s2")
        h.on(HttpMethod.Post, "interaction/like") { "{}" }

        store.toggle(playables.byId("s1")!!)

        assertFalse(playables.byId("s1")!!.favorite)
        assertEquals(listOf("s2"), ids())
    }

    @Test
    fun aFailedToggleOfAFavoriteRestoresItInPlace() = runTest(UnconfinedTestDispatcher()) {
        loadFavorites("s1", "s2", "s3")
        h.on(HttpMethod.Post, "interaction/like", status = 500) { "nope" }

        assertFailsWith<HttpResponseException> { store.toggle(playables.byId("s2")!!) }

        assertTrue(playables.byId("s2")!!.favorite)
        assertEquals(listOf("s1", "s2", "s3"), ids())
    }

    @Test
    fun togglingUsesTheCurrentStateNotTheCallersCopy() = runTest(UnconfinedTestDispatcher()) {
        val staleCopy = knownSong("s1", favorite = false)
        playables.update("s1") { it.withFavorite(true) }
        h.on(HttpMethod.Post, "interaction/like") { "{}" }

        store.toggle(staleCopy)

        assertFalse(playables.byId("s1")!!.favorite)
    }

    @Test
    fun unlikingPostsABatchAndRemovesFromTheList() = runTest(UnconfinedTestDispatcher()) {
        loadFavorites("s1", "s2")
        h.on(HttpMethod.Post, "interaction/batch/unlike") { "{}" }

        store.unlike(playables.byId("s1")!!)

        assertFalse(playables.byId("s1")!!.favorite)
        assertEquals(listOf("s2"), ids())
        assertEquals(buildJsonObject { put("songs", JsonArray(listOf(JsonPrimitive("s1")))) }, h.requests.last().json)
    }

    @Test
    fun unlikingRollsBackAndRethrowsOnFailure() = runTest(UnconfinedTestDispatcher()) {
        loadFavorites("s1", "s2")
        h.on(HttpMethod.Post, "interaction/batch/unlike", status = 500) { "nope" }

        assertFailsWith<HttpResponseException> { store.unlike(playables.byId("s1")!!) }

        assertTrue(playables.byId("s1")!!.favorite)
        assertEquals(listOf("s1", "s2"), ids())
    }

    @Test
    fun favoriteStateShowsInOtherCollections() = runTest(UnconfinedTestDispatcher()) {
        val song = knownSong("s1")
        h.on(HttpMethod.Post, "interaction/like") { "{}" }

        store.toggle(song)

        assertTrue(playables.fetchForAlbum("s1-album").single().favorite)
    }

    @Test
    fun resetEmptiesTheListAndRefetchesNextTime() = runTest(UnconfinedTestDispatcher()) {
        loadFavorites("s1")

        store.reset()
        assertEquals(emptyList(), ids())

        store.fetch()
        assertEquals(2, h.requestsTo(HttpMethod.Get, "songs/favorite").size)
    }
}
