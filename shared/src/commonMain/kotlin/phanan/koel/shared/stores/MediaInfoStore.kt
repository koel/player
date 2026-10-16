package phanan.koel.shared.stores

import phanan.koel.shared.onMain
import kotlinx.serialization.json.JsonArray
import kotlinx.serialization.json.JsonObject
import kotlinx.serialization.json.jsonPrimitive
import kotlinx.serialization.json.doubleOrNull
import phanan.koel.shared.api.ApiClient
import phanan.koel.shared.api.HttpResponseException
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
    private val waveforms = mutableMapOf<String, List<Double>>()

    @Throws(Exception::class)
    suspend fun fetchForAlbum(albumId: String): AlbumInfo = onMain {
        albumInfos.getOrPut(albumId) {
            val json = api.get("albums/$albumId/information") as? JsonObject
            val tracks = (json?.get("tracks") as? JsonArray)?.objects().orEmpty()

            AlbumInfo(
                information = json?.obj("wiki")?.string("full").orEmpty(),
                tracks = tracks.map { track -> AlbumTrack(track.string("title").orEmpty(), track.int("length") ?: 0) },
            )
        }
    }

    @Throws(Exception::class)
    suspend fun fetchForArtist(artistId: String): ArtistInfo = onMain {
        artistInfos.getOrPut(artistId) {
            val json = api.get("artists/$artistId/information") as? JsonObject
            ArtistInfo(biography = json?.obj("bio")?.string("full").orEmpty())
        }
    }

    /**
     * The song's loudness per evenly sized slice, each between 0 and 1. Empty when the song hasn't been
     * analyzed or the server isn't Koel Plus.
     */
    @Throws(Exception::class)
    suspend fun fetchWaveform(songId: String): List<Double> = onMain {
        waveforms[songId] ?: run {
            val levels = try {
                val json = api.get("songs/$songId/waveform") as? JsonObject
                (json?.get("waveform") as? JsonArray).orEmpty().mapNotNull { it.jsonPrimitive.doubleOrNull }
            } catch (error: HttpResponseException) {
                if (error.statusCode !in 400..499) throw error
                emptyList()
            }
            levels.also { waveforms[songId] = it }
        }
    }

    internal fun reset() {
        albumInfos.clear()
        artistInfos.clear()
        waveforms.clear()
    }
}
