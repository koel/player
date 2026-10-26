package phanan.koel.shared.stores

import phanan.koel.shared.onMain
import kotlinx.coroutines.flow.Flow
import kotlinx.coroutines.flow.MutableStateFlow
import kotlinx.coroutines.flow.StateFlow
import kotlinx.coroutines.flow.combine
import kotlinx.coroutines.flow.distinctUntilChanged
import kotlinx.coroutines.flow.update
import kotlinx.serialization.builtins.ListSerializer
import kotlinx.serialization.json.JsonElement
import phanan.koel.shared.api.ApiClient
import phanan.koel.shared.api.Page
import phanan.koel.shared.json.KoelJson
import phanan.koel.shared.models.Playable
import phanan.koel.shared.models.PlayableSortField
import phanan.koel.shared.models.Song
import phanan.koel.shared.models.SortOrder
import kotlin.time.Duration

/** Owns every song and episode the app has seen, plus the collections that list them. */
class PlayableStore internal constructor(private val api: ApiClient) {
    internal val vault = Vault<Playable> { it.id }

    /** Song and episode lists per collection (album, artist, playlist, podcast), by ID. */
    private val collections = MutableStateFlow<Map<String, List<String>>>(emptyMap())

    var songSortField: String = PlayableSortField.TITLE
        private set
    var songSortOrder: SortOrder = SortOrder.ASC
        private set

    private val songPager = Pager(vault, Playable::id) { page ->
        api.getPage("songs?page=$page&sort=$songSortField&order=${songSortOrder.value}", Playable.serializer())
    }

    /** The paginated All Songs list. */
    val songs: StateFlow<List<Playable>> = songPager.items
    val hasMoreSongs: StateFlow<Boolean> = songPager.hasMore

    fun byId(id: String): Playable? = vault[id]

    /** Follows the given playables as they change (favorites, play counts, renames). */
    fun live(playables: List<Playable>): Flow<List<Playable>> = vault.live(playables.map(Playable::id))

    fun albumSongs(albumId: String): Flow<List<Playable>> = liveCollection(albumKey(albumId))

    fun artistSongs(artistId: String): Flow<List<Playable>> = liveCollection(artistKey(artistId))

    fun playlistSongs(playlistId: String): Flow<List<Playable>> = liveCollection(playlistKey(playlistId))

    fun podcastEpisodes(podcastId: String): Flow<List<Playable>> = liveCollection(podcastKey(podcastId))

    @Throws(Exception::class)
    suspend fun loadMoreSongs() = onMain { songPager.loadMore() }

    @Throws(Exception::class)
    suspend fun refreshSongs(sortField: String = songSortField, sortOrder: SortOrder = songSortOrder): Unit = onMain {
        songSortField = sortField
        songSortOrder = sortOrder
        songPager.refresh()
    }

    @Throws(Exception::class)
    suspend fun fetchForAlbum(albumId: String, forceRefresh: Boolean = false): List<Playable> = onMain {
        fetchCollection(albumKey(albumId), "albums/$albumId/songs", forceRefresh)
    }

    @Throws(Exception::class)
    suspend fun fetchForArtist(artistId: String, forceRefresh: Boolean = false): List<Playable> = onMain {
        fetchCollection(artistKey(artistId), "artists/$artistId/songs", forceRefresh)
    }

    @Throws(Exception::class)
    suspend fun fetchForPlaylist(playlistId: String, forceRefresh: Boolean = false): List<Playable> = onMain {
        fetchCollection(playlistKey(playlistId), "playlists/$playlistId/songs", forceRefresh)
    }

    /** [checkForNewEpisodes] asks the server to re-read the feed first. */
    @Throws(Exception::class)
    suspend fun fetchForPodcast(
        podcastId: String,
        forceRefresh: Boolean = false,
        checkForNewEpisodes: Boolean = false,
    ): List<Playable> = onMain {
        val query = if (checkForNewEpisodes) "?refresh=1" else ""
        fetchCollection(
            podcastKey(podcastId),
            "podcasts/$podcastId/episodes$query",
            forceRefresh || checkForNewEpisodes,
            timeout = PodcastStore.FEED_FETCH_TIMEOUT.takeIf { checkForNewEpisodes },
        )
    }

    @Throws(Exception::class)
    suspend fun fetchPageForGenre(
        genreId: String,
        page: Int,
        sortField: String = PlayableSortField.TITLE,
        sortOrder: SortOrder = SortOrder.ASC,
    ): Page<Playable> = onMain {
        val result = api.getPage(
            "genres/$genreId/songs?page=$page&sort=$sortField&order=${sortOrder.value}",
            Playable.serializer(),
        )
        result.copy(items = vault.sync(result.items))
    }

    @Throws(Exception::class)
    suspend fun fetchRandom(limit: Int = 500): List<Playable> = onMain {
        sync(api.get("queue/fetch?order=rand&limit=$limit"))
    }

    @Throws(Exception::class)
    suspend fun fetchInOrder(
        sortField: String = PlayableSortField.TITLE,
        sortOrder: SortOrder = SortOrder.ASC,
        limit: Int = 500,
    ): List<Playable> = onMain { sync(api.get("queue/fetch?order=${sortOrder.value}&sort=$sortField&limit=$limit")) }

    internal fun sync(json: JsonElement): List<Playable> =
        vault.sync(KoelJson.decodeFromJsonElement(ListSerializer(Playable.serializer()), json))

    internal fun sync(playables: List<Playable>): List<Playable> = vault.sync(playables)

    internal fun update(id: String, transform: (Playable) -> Playable): Playable? = vault.update(id, transform)

    internal fun addToPlaylistCollection(playlistId: String, playables: List<Playable>) =
        collections.update { current ->
            val ids = current[playlistKey(playlistId)] ?: return@update current
            current + (playlistKey(playlistId) to (ids + playables.map(Playable::id)).distinct())
        }

    internal fun removeFromPlaylistCollection(playlistId: String, playables: List<Playable>) =
        collections.update { current ->
            val ids = current[playlistKey(playlistId)] ?: return@update current
            val removed = playables.map(Playable::id).toSet()
            current + (playlistKey(playlistId) to ids.filterNot(removed::contains))
        }

    internal fun forgetPlaylist(playlistId: String) = collections.update { it - playlistKey(playlistId) }

    internal fun applyAlbumRename(albumId: String, name: String) =
        vault.updateWhere({ it is Song && it.albumId == albumId }) { (it as Song).copy(albumName = name) }

    internal fun applyArtistRename(artistId: String, name: String) {
        vault.updateWhere({ it is Song && it.artistId == artistId }) { (it as Song).copy(artistName = name) }
        vault.updateWhere({ it is Song && it.albumArtistId == artistId }) { (it as Song).copy(albumArtistName = name) }
    }

    internal fun reset() {
        vault.clear()
        collections.value = emptyMap()
        songPager.reset()
    }

    private suspend fun fetchCollection(
        key: String,
        path: String,
        forceRefresh: Boolean,
        timeout: Duration? = null,
    ): List<Playable> {
        val cached = collections.value[key]
        if (cached != null && !forceRefresh) return cached.mapNotNull(vault::get)

        val playables = sync(api.get(path, timeout))
        collections.update { it + (key to playables.map(Playable::id)) }
        return playables
    }

    private fun liveCollection(key: String): Flow<List<Playable>> =
        combine(collections, vault.entities) { all, entities -> all[key].orEmpty().mapNotNull(entities::get) }
            .distinctUntilChanged()

    private fun albumKey(id: String) = "album:$id"
    private fun artistKey(id: String) = "artist:$id"
    private fun playlistKey(id: String) = "playlist:$id"
    private fun podcastKey(id: String) = "podcast:$id"
}
