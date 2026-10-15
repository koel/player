package phanan.koel.shared.stores

import kotlinx.coroutines.flow.MutableStateFlow
import kotlinx.coroutines.flow.StateFlow
import kotlinx.coroutines.flow.asStateFlow
import kotlinx.serialization.json.JsonArray
import kotlinx.serialization.json.JsonPrimitive
import kotlinx.serialization.json.buildJsonObject
import kotlinx.serialization.json.put
import phanan.koel.shared.api.ApiClient
import phanan.koel.shared.json.KoelJson
import phanan.koel.shared.models.Playable
import phanan.koel.shared.models.Playlist

class PlaylistStore internal constructor(
    private val api: ApiClient,
    private val playableStore: PlayableStore,
) {
    private val playlistsState = MutableStateFlow<List<Playlist>>(emptyList())
    val playlists: StateFlow<List<Playlist>> = playlistsState.asStateFlow()

    private val standardPlaylistsState = MutableStateFlow<List<Playlist>>(emptyList())

    /** Playlists whose songs can be added or removed by hand, i.e. not smart ones. */
    val standardPlaylists: StateFlow<List<Playlist>> = standardPlaylistsState.asStateFlow()

    fun byId(id: String): Playlist? = playlistsState.value.firstOrNull { it.id == id }

    internal fun seed(playlists: List<Playlist>) = publish(playlists)

    @Throws(Exception::class)
    suspend fun fetchAll() = publish(api.getList("playlists", Playlist.serializer()))

    @Throws(Exception::class)
    suspend fun addToPlaylist(playables: List<Playable>, playlist: Playlist) {
        requireStandard(playlist)
        api.post("playlists/${playlist.id}/songs", songsBody(playables))
        playableStore.addToPlaylistCollection(playlist.id, playables)
    }

    @Throws(Exception::class)
    suspend fun removeFromPlaylist(playables: List<Playable>, playlist: Playlist) {
        requireStandard(playlist)
        api.delete("playlists/${playlist.id}/songs", songsBody(playables))
        playableStore.removeFromPlaylistCollection(playlist.id, playables)
    }

    @Throws(Exception::class)
    suspend fun addToFolder(playlist: Playlist, folderId: String) {
        api.post("playlist-folders/$folderId/playlists", buildJsonObject {
            put("playlists", JsonArray(listOf(JsonPrimitive(playlist.id))))
        })
        replace(playlist.id) { it.copy(folderId = folderId) }
    }

    @Throws(Exception::class)
    suspend fun create(name: String, description: String? = null, folderId: String? = null): Playlist {
        val json = api.post("playlists", buildJsonObject {
            put("name", name)
            if (!description.isNullOrEmpty()) put("description", description)
            if (folderId != null) put("folder_id", folderId)
        })

        val playlist = KoelJson.decodeFromJsonElement(Playlist.serializer(), json)
        publish(playlistsState.value + playlist)
        return playlist
    }

    @Throws(Exception::class)
    suspend fun update(playlist: Playlist, name: String, description: String? = null, folderId: String? = null) {
        api.put("playlists/${playlist.id}", buildJsonObject {
            put("name", name)
            put("description", description.orEmpty())
            put("folder_id", folderId)
        })
        replace(playlist.id) { it.copy(name = name, description = description, folderId = folderId) }
    }

    /** Removes the playlist right away, and puts it back if the server refuses. */
    @Throws(Exception::class)
    suspend fun remove(playlist: Playlist) {
        val before = playlistsState.value
        publish(before.filterNot { it.id == playlist.id })

        try {
            api.delete("playlists/${playlist.id}")
        } catch (error: Exception) {
            val index = before.indexOfFirst { it.id == playlist.id }.coerceAtLeast(0)
            val current = playlistsState.value
            publish(current.take(index) + playlist + current.drop(index))
            throw error
        }

        playableStore.forgetPlaylist(playlist.id)
    }

    internal fun reset() = publish(emptyList())

    private fun publish(playlists: List<Playlist>) {
        playlistsState.value = playlists
        standardPlaylistsState.value = playlists.filterNot(Playlist::isSmart)
    }

    private fun replace(id: String, transform: (Playlist) -> Playlist) =
        publish(playlistsState.value.map { if (it.id == id) transform(it) else it })

    private fun requireStandard(playlist: Playlist) =
        require(!playlist.isSmart) { "Smart playlists can't be changed by hand." }

    private fun songsBody(playables: List<Playable>) = buildJsonObject {
        put("songs", JsonArray(playables.map { JsonPrimitive(it.id) }))
    }
}
