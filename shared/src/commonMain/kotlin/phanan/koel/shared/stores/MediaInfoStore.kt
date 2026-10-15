package phanan.koel.shared.stores

import kotlinx.serialization.json.JsonArray
import kotlinx.serialization.json.JsonObject
import phanan.koel.shared.api.ApiClient
import phanan.koel.shared.json.int
import phanan.koel.shared.json.obj
import phanan.koel.shared.json.objects
import phanan.koel.shared.json.string

data class AlbumTrack(val title: String, val length: Int)

/** [information] is HTML, empty when the server has no information source configured. */
data class AlbumInfo(val information: String, val tracks: List<AlbumTrack>)

/** [biography] is HTML, empty when the server has no information source configured. */
data class ArtistInfo(val biography: String)

class MediaInfoStore internal constructor(private val api: ApiClient) {
    private val albumInfos = mutableMapOf<String, AlbumInfo>()
    private val artistInfos = mutableMapOf<String, ArtistInfo>()

    @Throws(Exception::class)
    suspend fun fetchForAlbum(albumId: String): AlbumInfo = albumInfos.getOrPut(albumId) {
        val json = api.get("albums/$albumId/information") as? JsonObject
        val tracks = (json?.get("tracks") as? JsonArray)?.objects().orEmpty()

        AlbumInfo(
            information = json?.obj("wiki")?.string("full").orEmpty(),
            tracks = tracks.map { track -> AlbumTrack(track.string("title").orEmpty(), track.int("length") ?: 0) },
        )
    }

    @Throws(Exception::class)
    suspend fun fetchForArtist(artistId: String): ArtistInfo = artistInfos.getOrPut(artistId) {
        val json = api.get("artists/$artistId/information") as? JsonObject
        ArtistInfo(biography = json?.obj("bio")?.string("full").orEmpty())
    }

    internal fun reset() {
        albumInfos.clear()
        artistInfos.clear()
    }
}
