package phanan.koel.shared.stores

import io.ktor.http.HttpMethod
import kotlinx.coroutines.test.UnconfinedTestDispatcher
import kotlinx.coroutines.test.runTest
import phanan.koel.shared.models.Playable
import phanan.koel.shared.models.Song
import phanan.koel.shared.support.Fixtures
import phanan.koel.shared.support.Harness
import kotlin.test.Test
import kotlin.test.assertEquals
import kotlin.test.assertFalse
import kotlin.test.assertTrue

class RecentlyPlayedStoreTest {
    private val h = Harness()
    private val playables = PlayableStore(h.api)
    private val store = RecentlyPlayedStore(h.api, playables)

    private fun ids() = store.items.value.map { it.id }

    private fun song(id: String): Playable = Song(id = id, title = "Song $id")

    private suspend fun knownSongs(vararg ids: String): List<Playable> {
        h.on(HttpMethod.Get, "albums/known/songs") { Fixtures.list(*ids.map { Fixtures.song(it) }.toTypedArray()) }
        return playables.fetchForAlbum("known", forceRefresh = true)
    }

    @Test
    fun fetchesTheRecentlyPlayedList() = runTest(UnconfinedTestDispatcher()) {
        h.on(HttpMethod.Get, "songs/recently-played") { Fixtures.list(Fixtures.song("s2"), Fixtures.song("s1")) }
        assertFalse(store.loaded.value)

        val fetched = store.fetch()

        assertEquals(listOf("s2", "s1"), fetched.map { it.id })
        assertEquals(listOf("s2", "s1"), ids())
        assertTrue(store.loaded.value)
    }

    @Test
    fun seedingAnEmptyListTakesTheSnapshot() = runTest(UnconfinedTestDispatcher()) {
        store.seed(knownSongs("s1", "s2", "s3"))

        assertEquals(listOf("s1", "s2", "s3"), ids())
    }

    @Test
    fun seedingKeepsWhatWasPlayedMeanwhileOnTop() = runTest(UnconfinedTestDispatcher()) {
        val songs = knownSongs("s1", "s2", "s3", "new1", "new2")
        store.add(songs[3])
        store.add(songs[4])

        store.seed(songs.take(3))

        assertEquals(listOf("new2", "new1", "s1", "s2", "s3"), ids())
    }

    @Test
    fun seedingDoesNotDuplicateOverlappingItems() = runTest(UnconfinedTestDispatcher()) {
        val songs = knownSongs("overlap", "s1", "s2")
        store.add(songs[0])

        store.seed(songs)

        assertEquals(listOf("overlap", "s1", "s2"), ids())
    }

    @Test
    fun addingPutsThePlayableOnTop() = runTest(UnconfinedTestDispatcher()) {
        store.seed(knownSongs("s1", "s2", "s3"))

        store.add(song("new"))

        assertEquals(listOf("new", "s1", "s2", "s3"), ids())
    }

    @Test
    fun addingAKnownPlayableMovesItToTheTop() = runTest(UnconfinedTestDispatcher()) {
        val songs = knownSongs("s1", "s2", "s3")
        store.seed(songs)

        store.add(songs.last())

        assertEquals(listOf("s3", "s1", "s2"), ids())
    }

    @Test
    fun addingToAnEmptyListWorks() {
        store.add(song("s1"))

        assertEquals(listOf("s1"), ids())
    }

    @Test
    fun itemsFollowChangesInTheVault() = runTest(UnconfinedTestDispatcher()) {
        store.seed(knownSongs("s1"))

        playables.update("s1") { it.withFavorite(true) }

        assertTrue(store.items.value.single().favorite)
    }

    @Test
    fun resetEmptiesTheListAndMarksItUnloaded() = runTest(UnconfinedTestDispatcher()) {
        h.on(HttpMethod.Get, "songs/recently-played") { Fixtures.list(Fixtures.song("s1")) }
        store.fetch()

        store.reset()

        assertEquals(emptyList(), ids())
        assertFalse(store.loaded.value)
    }
}
