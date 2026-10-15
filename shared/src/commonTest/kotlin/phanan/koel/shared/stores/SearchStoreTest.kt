package phanan.koel.shared.stores

import io.ktor.http.HttpMethod
import kotlinx.coroutines.test.UnconfinedTestDispatcher
import kotlinx.coroutines.test.runTest
import kotlinx.serialization.json.JsonArray
import kotlinx.serialization.json.buildJsonObject
import kotlinx.serialization.json.put
import phanan.koel.shared.support.Fixtures
import phanan.koel.shared.support.Harness
import kotlin.test.Test
import kotlin.test.assertEquals
import kotlin.test.assertTrue

class SearchStoreTest {
    private val h = Harness()
    private val playables = PlayableStore(h.api)
    private val albums = AlbumStore(h.api, playables)
    private val artists = ArtistStore(h.api, playables, albums)
    private val store = SearchStore(h.api, playables, albums, artists)

    private fun excerpts(withPodcastsAndRadio: Boolean = true) = buildJsonObject {
        put("songs", JsonArray(listOf(Fixtures.song("s1"), Fixtures.episode("e1"))))
        put("artists", JsonArray(listOf(Fixtures.artist("ar1"))))
        put("albums", JsonArray(listOf(Fixtures.album("al1"))))
        if (withPodcastsAndRadio) {
            put("podcasts", JsonArray(listOf(Fixtures.podcast("p1"))))
            put("radio_stations", JsonArray(listOf(Fixtures.radioStation("r1", name = "Jazz FM"))))
        }
    }.toString()

    @Test
    fun searchingExcerptsReturnsEveryKindAndSyncsTheVaults() = runTest(UnconfinedTestDispatcher()) {
        h.on(HttpMethod.Get, "search") { excerpts() }

        val result = store.searchExcerpts("jazz")

        assertEquals(listOf("s1", "e1"), result.playables.map { it.id })
        assertEquals(listOf("ar1"), result.artists.map { it.id })
        assertEquals(listOf("al1"), result.albums.map { it.id })
        assertEquals(listOf("p1"), result.podcasts.map { it.id })
        assertEquals(listOf("Jazz FM"), result.radioStations.map { it.name })
        assertEquals(result.playables.first(), playables.byId("s1"))
        assertEquals(result.albums.single(), albums.byId("al1"))
        assertEquals(result.artists.single(), artists.byId("ar1"))
    }

    @Test
    fun olderServersWithoutPodcastsOrRadioStationsGiveEmptyLists() = runTest(UnconfinedTestDispatcher()) {
        h.on(HttpMethod.Get, "search") { excerpts(withPodcastsAndRadio = false) }

        val result = store.searchExcerpts("jazz")

        assertEquals(emptyList(), result.podcasts)
        assertEquals(emptyList(), result.radioStations)
        assertEquals(1, result.albums.size)
    }

    @Test
    fun encodesTheKeywords() = runTest(UnconfinedTestDispatcher()) {
        h.on(HttpMethod.Get, "search") { excerpts() }
        h.on(HttpMethod.Get, "search/songs") { Fixtures.list(Fixtures.song("s1")) }

        store.searchExcerpts("rock & roll")
        store.searchPlayables("50% off")

        assertEquals(listOf("search?q=rock%20%26%20roll", "search/songs?q=50%25%20off"), h.requests.map { it.path })
    }

    @Test
    fun cachesExcerptsPerKeywordAndKeepsThemCurrent() = runTest(UnconfinedTestDispatcher()) {
        h.on(HttpMethod.Get, "search") { excerpts() }
        h.on(HttpMethod.Post, "favorites/toggle") { "{}" }

        store.searchExcerpts("jazz")
        albums.toggleFavorite(albums.byId("al1")!!)
        val cached = store.searchExcerpts("jazz")
        store.searchExcerpts("rock")

        assertTrue(cached.albums.single().favorite)
        assertEquals(listOf("search?q=jazz", "search?q=rock"), h.requestsTo(HttpMethod.Get, "search").map { it.path })
    }

    @Test
    fun searchesPlayablesAndCachesPerKeyword() = runTest(UnconfinedTestDispatcher()) {
        h.on(HttpMethod.Get, "search/songs") { Fixtures.list(Fixtures.song("s1"), Fixtures.song("s2")) }

        store.searchPlayables("song")
        playables.update("s1") { it.withFavorite(true) }
        val cached = store.searchPlayables("song")

        assertEquals(listOf("s1", "s2"), cached.map { it.id })
        assertTrue(cached.first().favorite)
        assertEquals(1, h.requestsTo(HttpMethod.Get, "search/songs").size)
    }

    @Test
    fun resetDropsTheCaches() = runTest(UnconfinedTestDispatcher()) {
        h.on(HttpMethod.Get, "search/songs") { Fixtures.list(Fixtures.song("s1")) }

        store.searchPlayables("song")
        store.reset()
        store.searchPlayables("song")

        assertEquals(2, h.requestsTo(HttpMethod.Get, "search/songs").size)
    }
}
