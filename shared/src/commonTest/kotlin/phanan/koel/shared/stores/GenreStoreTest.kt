package phanan.koel.shared.stores

import io.ktor.http.HttpMethod
import kotlinx.coroutines.test.UnconfinedTestDispatcher
import kotlinx.coroutines.test.runTest
import phanan.koel.shared.support.Fixtures
import phanan.koel.shared.support.Harness
import kotlin.test.Test
import kotlin.test.assertEquals
import kotlin.test.assertNull

class GenreStoreTest {
    private val h = Harness()
    private val store = GenreStore(h.api)

    @Test
    fun fetchesGenresInTheServersOrder() = runTest(UnconfinedTestDispatcher()) {
        h.on(HttpMethod.Get, "genres") {
            Fixtures.list(Fixtures.genre("g2", name = "Rock", songCount = 3), Fixtures.genre("g1", name = "Jazz"))
        }

        store.fetch()

        assertEquals(listOf("Rock", "Jazz"), store.items.value.map { it.name })
        assertEquals(3, store.byId("g2")?.songCount)
    }

    @Test
    fun fetchingAgainReplacesTheListAndMergesKnownGenres() = runTest(UnconfinedTestDispatcher()) {
        var songCount = 1
        var genres = listOf("g1", "g2")
        h.on(HttpMethod.Get, "genres") {
            Fixtures.list(*genres.map { Fixtures.genre(it, songCount = songCount) }.toTypedArray())
        }
        store.fetch()

        songCount = 5
        genres = listOf("g1")
        store.fetch()

        assertEquals(listOf("g1"), store.items.value.map { it.id })
        assertEquals(5, store.byId("g1")?.songCount)
    }

    @Test
    fun resetForgetsEverything() = runTest(UnconfinedTestDispatcher()) {
        h.on(HttpMethod.Get, "genres") { Fixtures.list(Fixtures.genre("g1")) }
        store.fetch()

        store.reset()

        assertEquals(emptyList(), store.items.value)
        assertNull(store.byId("g1"))
    }
}
