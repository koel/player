package phanan.koel.shared.stores

import io.ktor.http.encodeURLParameter
import kotlinx.serialization.json.jsonObject
import phanan.koel.shared.api.ApiClient
import phanan.koel.shared.json.decodeList
import phanan.koel.shared.models.Album
import phanan.koel.shared.models.Artist
import phanan.koel.shared.models.Playable
import phanan.koel.shared.models.Podcast
import phanan.koel.shared.models.RadioStation

data class SearchResult(
    val playables: List<Playable> = emptyList(),
    val artists: List<Artist> = emptyList(),
    val albums: List<Album> = emptyList(),
    val podcasts: List<Podcast> = emptyList(),
    val radioStations: List<RadioStation> = emptyList(),
)

class SearchStore internal constructor(
    private val api: ApiClient,
    private val playableStore: PlayableStore,
    private val albumStore: AlbumStore,
    private val artistStore: ArtistStore,
) {
    private val excerptCache = mutableMapOf<String, SearchResult>()
    private val playableCache = mutableMapOf<String, List<Playable>>()

    @Throws(Exception::class)
    suspend fun searchExcerpts(keywords: String): SearchResult {
        excerptCache[keywords]?.let { return it.withCurrentEntities() }

        val response = api.get("search?q=${keywords.encodeURLParameter()}").jsonObject
        val result = SearchResult(
            playables = playableStore.sync(response.decodeList("songs", Playable.serializer())),
            artists = artistStore.sync(response.decodeList("artists", Artist.serializer())),
            albums = albumStore.sync(response.decodeList("albums", Album.serializer())),
            podcasts = response.decodeList("podcasts", Podcast.serializer()),
            radioStations = response.decodeList("radio_stations", RadioStation.serializer()),
        )

        excerptCache[keywords] = result
        return result
    }

    @Throws(Exception::class)
    suspend fun searchPlayables(keywords: String): List<Playable> {
        playableCache[keywords]?.let { cached -> return cached.map { playableStore.byId(it.id) ?: it } }

        val result = playableStore.sync(api.get("search/songs?q=${keywords.encodeURLParameter()}"))
        playableCache[keywords] = result
        return result
    }

    internal fun reset() {
        excerptCache.clear()
        playableCache.clear()
    }

    private fun SearchResult.withCurrentEntities() = copy(
        playables = playables.map { playableStore.byId(it.id) ?: it },
        artists = artists.map { artistStore.byId(it.id) ?: it },
        albums = albums.map { albumStore.byId(it.id) ?: it },
    )
}
