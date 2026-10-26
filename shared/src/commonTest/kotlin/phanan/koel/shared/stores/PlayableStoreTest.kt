package phanan.koel.shared.stores

import io.ktor.client.network.sockets.SocketTimeoutException
import io.ktor.http.HttpMethod
import kotlinx.coroutines.delay
import kotlinx.coroutines.flow.first
import kotlinx.coroutines.test.UnconfinedTestDispatcher
import kotlinx.coroutines.test.runTest
import phanan.koel.shared.api.ApiClient
import phanan.koel.shared.models.PlayableSortField
import phanan.koel.shared.models.Song
import phanan.koel.shared.models.SortOrder
import phanan.koel.shared.models.filtered
import phanan.koel.shared.models.sorted
import phanan.koel.shared.support.Fixtures
import phanan.koel.shared.support.Harness
import kotlin.test.Test
import kotlin.test.assertEquals
import kotlin.test.assertFailsWith
import kotlin.test.assertFalse
import kotlin.test.assertTrue
import kotlin.time.Duration.Companion.milliseconds

class PlayableStoreTest {
    private val h = Harness()

    private fun store() = PlayableStore(h.api)

    @Test
    fun paginatesAllSongsUntilTheLastPage() = runTest(UnconfinedTestDispatcher()) {
        val store = store()
        h.on(HttpMethod.Get, "songs?page=1&sort=title&order=asc") {
            Fixtures.page(listOf(Fixtures.song("s1"), Fixtures.song("s2")), currentPage = 1, hasNext = true).toString()
        }
        h.on(HttpMethod.Get, "songs?page=2&sort=title&order=asc") {
            Fixtures.page(listOf(Fixtures.song("s2"), Fixtures.song("s3")), currentPage = 2).toString()
        }

        store.loadMoreSongs()
        assertTrue(store.hasMoreSongs.value)

        store.loadMoreSongs()
        assertEquals(listOf("s1", "s2", "s3"), store.songs.value.map { it.id })
        assertFalse(store.hasMoreSongs.value)

        store.loadMoreSongs()
        assertEquals(2, h.requestsTo(HttpMethod.Get, "songs").size)
    }

    @Test
    fun refreshingWithANewSortStartsOver() = runTest(UnconfinedTestDispatcher()) {
        val store = store()
        h.on(HttpMethod.Get, "songs?page=1&sort=title&order=asc") { Fixtures.page(listOf(Fixtures.song("s1"))).toString() }
        h.on(HttpMethod.Get, "songs?page=1&sort=created_at&order=desc") { Fixtures.page(listOf(Fixtures.song("s9"))).toString() }

        store.loadMoreSongs()
        store.refreshSongs(PlayableSortField.CREATED_AT, SortOrder.DESC)

        assertEquals(listOf("s9"), store.songs.value.map { it.id })
    }

    @Test
    fun cachesCollectionsUntilForcedToRefresh() = runTest(UnconfinedTestDispatcher()) {
        val store = store()
        var title = "First"
        h.on(HttpMethod.Get, "albums/a1/songs") { Fixtures.list(Fixtures.song("s1", title = title)) }

        store.fetchForAlbum("a1")
        title = "Second"
        assertEquals("First", store.fetchForAlbum("a1").single().title)
        assertEquals("Second", store.fetchForAlbum("a1", forceRefresh = true).single().title)
        assertEquals(2, h.requestsTo(HttpMethod.Get, "albums/a1/songs").size)
    }

    @Test
    fun collectionsFollowChangesMadeElsewhere() = runTest(UnconfinedTestDispatcher()) {
        val store = store()
        h.on(HttpMethod.Get, "playlists/p1/songs") { Fixtures.list(Fixtures.song("s1"), Fixtures.song("s2")) }
        store.fetchForPlaylist("p1")

        store.update("s1") { it.withFavorite(true) }
        store.removeFromPlaylistCollection("p1", listOf(store.byId("s2")!!))

        val songs = store.playlistSongs("p1").first()
        assertEquals(listOf("s1"), songs.map { it.id })
        assertTrue(songs.single().favorite)
    }

    @Test
    fun checkingForNewEpisodesAsksTheServerToReReadTheFeed() = runTest(UnconfinedTestDispatcher()) {
        val store = store()
        h.on(HttpMethod.Get, "podcasts/p1/episodes") { Fixtures.list(Fixtures.episode("e1")) }

        store.fetchForPodcast("p1")
        store.fetchForPodcast("p1", checkForNewEpisodes = true)

        assertEquals(listOf("podcasts/p1/episodes", "podcasts/p1/episodes?refresh=1"), h.requests.map { it.path })
    }

    @Test
    fun checkingForNewEpisodesWaitsForASlowFeedLongerThanOtherRequests() = runTest(UnconfinedTestDispatcher()) {
        h.onRequest(HttpMethod.Get, "podcasts/p1/episodes") {
            delay(300.milliseconds)
            Harness.Reply(200, Fixtures.list(Fixtures.episode("e1")))
        }
        val impatientStore = PlayableStore(ApiClient(h.engine, h.preferences, stallTimeout = 100.milliseconds))

        assertFailsWith<SocketTimeoutException> { impatientStore.fetchForPodcast("p1") }
        assertEquals(listOf("e1"), impatientStore.fetchForPodcast("p1", checkForNewEpisodes = true).map { it.id })
    }

    @Test
    fun renamesPropagateToSongs() = runTest(UnconfinedTestDispatcher()) {
        val store = store()
        h.on(HttpMethod.Get, "artists/ar1/songs") {
            Fixtures.list(Fixtures.song("s1", artistId = "ar1", albumId = "al1"), Fixtures.song("s2", artistId = "other"))
        }
        store.fetchForArtist("ar1")

        store.applyAlbumRename("al1", "Renamed Album")
        store.applyArtistRename("ar1", "Renamed Artist")

        val renamed = store.byId("s1") as Song
        assertEquals("Renamed Album", renamed.albumName)
        assertEquals("Renamed Artist", renamed.artistName)
        assertEquals("Artist", (store.byId("s2") as Song).artistName)
    }

    @Test
    fun sortsAndFiltersLocally() = runTest(UnconfinedTestDispatcher()) {
        val store = store()
        h.on(HttpMethod.Get, "albums/a1/songs") {
            Fixtures.list(
                Fixtures.song("s1", title = "Beta", track = 2),
                Fixtures.song("s2", title = "Alpha", track = 1),
                Fixtures.song("s3", title = "Gamma", artistName = "Someone Else", track = 3),
            )
        }
        val songs = store.fetchForAlbum("a1")

        assertEquals(listOf("s2", "s1", "s3"), songs.sorted(PlayableSortField.TITLE, SortOrder.ASC).map { it.id })
        assertEquals(listOf("s3", "s1", "s2"), songs.sorted(PlayableSortField.TRACK, SortOrder.DESC).map { it.id })
        assertEquals(listOf("s3", "s2", "s1"), songs.sorted(PlayableSortField.POSITION, SortOrder.DESC).map { it.id })
        assertEquals(listOf("s3"), songs.filtered("someone").map { it.id })
    }
}
