package phanan.koel.shared.stores

import phanan.koel.shared.onMain
import kotlinx.coroutines.flow.StateFlow
import kotlinx.serialization.json.jsonObject
import phanan.koel.shared.api.ApiClient
import phanan.koel.shared.json.decodeList
import phanan.koel.shared.models.Album
import phanan.koel.shared.models.Artist
import phanan.koel.shared.models.Playable

class OverviewStore internal constructor(
    private val api: ApiClient,
    private val playableStore: PlayableStore,
    private val albumStore: AlbumStore,
    private val artistStore: ArtistStore,
    private val recentlyPlayedStore: RecentlyPlayedStore,
) {
    private val mostPlayedSongList = playableStore.vault.liveList()
    private val recentlyAddedSongList = playableStore.vault.liveList()
    private val recentlyPlayedSongList = playableStore.vault.liveList()
    private val leastPlayedSongList = playableStore.vault.liveList()
    private val randomSongList = playableStore.vault.liveList()
    private val similarSongList = playableStore.vault.liveList()
    private val mostPlayedAlbumList = albumStore.vault.liveList()
    private val recentlyAddedAlbumList = albumStore.vault.liveList()
    private val randomAlbumList = albumStore.vault.liveList()
    private val mostPlayedArtistList = artistStore.vault.liveList()
    private val recentlyAddedArtistList = artistStore.vault.liveList()
    private val randomArtistList = artistStore.vault.liveList()

    private val playableSections = mapOf(
        "most_played_songs" to mostPlayedSongList,
        "recently_added_songs" to recentlyAddedSongList,
        "recently_played_songs" to recentlyPlayedSongList,
        "least_played_songs" to leastPlayedSongList,
        "random_songs" to randomSongList,
        "similar_songs" to similarSongList,
    )

    private val albumSections = mapOf(
        "most_played_albums" to mostPlayedAlbumList,
        "recently_added_albums" to recentlyAddedAlbumList,
        "random_albums" to randomAlbumList,
    )

    private val artistSections = mapOf(
        "most_played_artists" to mostPlayedArtistList,
        "recently_added_artists" to recentlyAddedArtistList,
        "random_artists" to randomArtistList,
    )

    private val allSections: List<LiveList<*>> = playableSections.values + albumSections.values + artistSections.values

    val mostPlayedSongs: StateFlow<List<Playable>> = mostPlayedSongList.items
    val recentlyAddedSongs: StateFlow<List<Playable>> = recentlyAddedSongList.items
    val recentlyPlayedSongs: StateFlow<List<Playable>> = recentlyPlayedSongList.items
    val leastPlayedSongs: StateFlow<List<Playable>> = leastPlayedSongList.items
    val randomSongs: StateFlow<List<Playable>> = randomSongList.items
    val similarSongs: StateFlow<List<Playable>> = similarSongList.items
    val mostPlayedAlbums: StateFlow<List<Album>> = mostPlayedAlbumList.items
    val recentlyAddedAlbums: StateFlow<List<Album>> = recentlyAddedAlbumList.items
    val randomAlbums: StateFlow<List<Album>> = randomAlbumList.items
    val mostPlayedArtists: StateFlow<List<Artist>> = mostPlayedArtistList.items
    val recentlyAddedArtists: StateFlow<List<Artist>> = recentlyAddedArtistList.items
    val randomArtists: StateFlow<List<Artist>> = randomArtistList.items

    val isEmpty: Boolean get() = allSections.all { it.items.value.isEmpty() }

    /** Sections an older server doesn't send come back empty. */
    @Throws(Exception::class)
    suspend fun refresh(): Unit = onMain {
        val response = api.get("overview").jsonObject

        playableSections.forEach { (key, list) ->
            list.ids = playableStore.sync(response.decodeList(key, Playable.serializer())).map(Playable::id)
        }
        albumSections.forEach { (key, list) ->
            list.ids = albumStore.sync(response.decodeList(key, Album.serializer())).map(Album::id)
        }
        artistSections.forEach { (key, list) ->
            list.ids = artistStore.sync(response.decodeList(key, Artist.serializer())).map(Artist::id)
        }

        recentlyPlayedStore.seed(recentlyPlayedSongs.value)
    }

    internal fun reset() = allSections.forEach { it.ids = emptyList() }
}
