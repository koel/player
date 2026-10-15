package phanan.koel.shared.stores

import io.ktor.http.HttpMethod
import kotlinx.coroutines.test.UnconfinedTestDispatcher
import kotlinx.coroutines.test.runTest
import phanan.koel.shared.support.Harness
import kotlin.test.Test
import kotlin.test.assertEquals

class MediaInfoStoreTest {
    private val h = Harness()
    private val store = MediaInfoStore(h.api)

    @Test
    fun fetchesAlbumInformationWithTracks() = runTest(UnconfinedTestDispatcher()) {
        h.on(HttpMethod.Get, "albums/a1/information") {
            """
            {
              "url": "https://last.fm/a1",
              "cover": null,
              "wiki": {"summary": "Short", "full": "<p>Full story</p>"},
              "tracks": [{"title": "Intro", "length": 61, "url": null}, {"title": "Outro", "length": 180.5}]
            }
            """
        }

        val info = store.fetchForAlbum("a1")

        assertEquals("<p>Full story</p>", info.information)
        assertEquals(listOf(AlbumTrack("Intro", 61), AlbumTrack("Outro", 180)), info.tracks)
    }

    @Test
    fun fetchesArtistBiography() = runTest(UnconfinedTestDispatcher()) {
        h.on(HttpMethod.Get, "artists/ar1/information") {
            """{"url": null, "image": null, "bio": {"summary": "Short", "full": "<p>Life</p>"}}"""
        }

        assertEquals(ArtistInfo("<p>Life</p>"), store.fetchForArtist("ar1"))
    }

    @Test
    fun toleratesServersWithoutAnInformationSource() = runTest(UnconfinedTestDispatcher()) {
        h.on(HttpMethod.Get, "albums/a1/information") { "null" }
        h.on(HttpMethod.Get, "albums/a2/information") { """{"wiki": null, "tracks": null}""" }
        h.on(HttpMethod.Get, "artists/ar1/information") { "null" }
        h.on(HttpMethod.Get, "artists/ar2/information") { """{"bio": null}""" }

        assertEquals(AlbumInfo("", emptyList()), store.fetchForAlbum("a1"))
        assertEquals(AlbumInfo("", emptyList()), store.fetchForAlbum("a2"))
        assertEquals(ArtistInfo(""), store.fetchForArtist("ar1"))
        assertEquals(ArtistInfo(""), store.fetchForArtist("ar2"))
    }

    @Test
    fun cachesPerIdUntilReset() = runTest(UnconfinedTestDispatcher()) {
        h.on(HttpMethod.Get, "albums/a1/information") { """{"wiki": {"full": "A1"}, "tracks": []}""" }
        h.on(HttpMethod.Get, "albums/a2/information") { """{"wiki": {"full": "A2"}, "tracks": []}""" }
        h.on(HttpMethod.Get, "artists/ar1/information") { """{"bio": {"full": "AR1"}}""" }

        store.fetchForAlbum("a1")
        store.fetchForAlbum("a1")
        assertEquals("A2", store.fetchForAlbum("a2").information)
        store.fetchForArtist("ar1")
        store.fetchForArtist("ar1")
        store.reset()
        store.fetchForAlbum("a1")

        assertEquals(
            listOf("albums/a1/information", "albums/a2/information", "artists/ar1/information", "albums/a1/information"),
            h.requests.map { it.path },
        )
    }
}
