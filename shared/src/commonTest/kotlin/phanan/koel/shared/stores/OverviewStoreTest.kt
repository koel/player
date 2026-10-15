package phanan.koel.shared.stores

import io.ktor.http.HttpMethod
import kotlinx.coroutines.test.UnconfinedTestDispatcher
import kotlinx.coroutines.test.runTest
import kotlinx.serialization.json.JsonArray
import kotlinx.serialization.json.JsonObject
import kotlinx.serialization.json.buildJsonObject
import kotlinx.serialization.json.put
import phanan.koel.shared.support.Fixtures
import phanan.koel.shared.support.Harness
import kotlin.test.Test
import kotlin.test.assertEquals
import kotlin.test.assertFalse
import kotlin.test.assertTrue

class OverviewStoreTest {
    private val h = Harness()
    private val playables = PlayableStore(h.api)
    private val albums = AlbumStore(h.api, playables)
    private val artists = ArtistStore(h.api, playables, albums)
    private val recentlyPlayed = RecentlyPlayedStore(h.api, playables)
    private val store = OverviewStore(h.api, playables, albums, artists, recentlyPlayed)

    private var sequence = 0

    private fun songs(count: Int) = JsonArray(List(count) { Fixtures.song("s${sequence++}") })
    private fun albumList(count: Int) = JsonArray(List(count) { Fixtures.album("al${sequence++}") })
    private fun artistList(count: Int) = JsonArray(List(count) { Fixtures.artist("ar${sequence++}") })

    private fun respond(overview: JsonObject) = h.on(HttpMethod.Get, "overview") { overview.toString() }

    @Test
    fun refreshPopulatesEverySection() = runTest(UnconfinedTestDispatcher()) {
        respond(buildJsonObject {
            put("most_played_songs", songs(3))
            put("recently_added_songs", songs(2))
            put("recently_played_songs", songs(4))
            put("least_played_songs", songs(1))
            put("random_songs", songs(5))
            put("similar_songs", songs(6))
            put("most_played_albums", albumList(3))
            put("recently_added_albums", albumList(2))
            put("random_albums", albumList(4))
            put("most_played_artists", artistList(3))
            put("recently_added_artists", artistList(2))
            put("random_artists", artistList(4))
        })

        store.refresh()

        assertEquals(
            listOf(3, 2, 4, 1, 5, 6, 3, 2, 4, 3, 2, 4),
            listOf(
                store.mostPlayedSongs, store.recentlyAddedSongs, store.recentlyPlayedSongs, store.leastPlayedSongs,
                store.randomSongs, store.similarSongs, store.mostPlayedAlbums, store.recentlyAddedAlbums,
                store.randomAlbums, store.mostPlayedArtists, store.recentlyAddedArtists, store.randomArtists,
            ).map { it.value.size },
        )
    }

    @Test
    fun sectionsAnOlderServerOmitsStayEmpty() = runTest(UnconfinedTestDispatcher()) {
        respond(buildJsonObject {
            put("most_played_songs", songs(2))
            put("recently_played_songs", songs(1))
            put("most_played_albums", albumList(2))
            put("most_played_artists", artistList(2))
        })

        store.refresh()

        assertEquals(2, store.mostPlayedSongs.value.size)
        assertEquals(1, store.recentlyPlayedSongs.value.size)
        assertEquals(2, store.mostPlayedAlbums.value.size)
        assertEquals(2, store.mostPlayedArtists.value.size)
        listOf(
            store.recentlyAddedSongs, store.leastPlayedSongs, store.randomSongs, store.similarSongs,
            store.recentlyAddedAlbums, store.randomAlbums, store.recentlyAddedArtists, store.randomArtists,
        ).forEach { assertTrue(it.value.isEmpty()) }
        assertFalse(store.isEmpty)
    }

    @Test
    fun isEmptyWhenTheServerReturnsNothing() = runTest(UnconfinedTestDispatcher()) {
        respond(JsonObject(emptyMap()))

        store.refresh()

        assertTrue(store.isEmpty)
    }

    @Test
    fun sectionsFollowFavoritesAndRenames() = runTest(UnconfinedTestDispatcher()) {
        respond(buildJsonObject {
            put("most_played_songs", JsonArray(listOf(Fixtures.song("s1", albumId = "al1"))))
            put("random_albums", JsonArray(listOf(Fixtures.album("al1", artistId = "ar1"))))
            put("random_artists", JsonArray(listOf(Fixtures.artist("ar1"))))
        })
        h.on(HttpMethod.Post, "favorites/toggle") { "{}" }
        h.on(HttpMethod.Put, "artists/ar1") { """{"name":"Renamed"}""" }
        store.refresh()

        playables.update("s1") { it.withFavorite(true) }
        albums.toggleFavorite(albums.byId("al1")!!)
        artists.update(artists.byId("ar1")!!, name = "Renamed")

        assertTrue(store.mostPlayedSongs.value.single().favorite)
        assertTrue(store.randomAlbums.value.single().favorite)
        assertEquals("Renamed", store.randomAlbums.value.single().artistName)
        assertEquals("Renamed", store.randomArtists.value.single().name)
    }

    @Test
    fun seedsRecentlyPlayedBelowWhatWasPlayedMeanwhile() = runTest(UnconfinedTestDispatcher()) {
        respond(buildJsonObject {
            put("recently_played_songs", JsonArray(listOf(Fixtures.song("s1"), Fixtures.song("s2"))))
        })
        h.on(HttpMethod.Get, "albums/al9/songs") { Fixtures.list(Fixtures.song("s9")) }
        recentlyPlayed.add(playables.fetchForAlbum("al9").single())

        store.refresh()

        assertEquals(listOf("s9", "s1", "s2"), recentlyPlayed.items.value.map { it.id })
    }

    @Test
    fun resetEmptiesEverySection() = runTest(UnconfinedTestDispatcher()) {
        respond(buildJsonObject {
            put("most_played_songs", songs(2))
            put("random_artists", artistList(1))
        })
        store.refresh()

        store.reset()

        assertTrue(store.isEmpty)
    }
}
