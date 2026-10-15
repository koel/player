package phanan.koel.shared.stores

import phanan.koel.shared.onMain
import kotlinx.coroutines.flow.MutableStateFlow
import kotlinx.coroutines.flow.StateFlow
import kotlinx.coroutines.flow.asStateFlow
import kotlinx.serialization.json.buildJsonObject
import kotlinx.serialization.json.put
import phanan.koel.shared.api.ApiClient
import phanan.koel.shared.json.KoelJson
import phanan.koel.shared.models.PlaylistFolder

class PlaylistFolderStore internal constructor(private val api: ApiClient) {
    private val foldersState = MutableStateFlow<List<PlaylistFolder>>(emptyList())
    val folders: StateFlow<List<PlaylistFolder>> = foldersState.asStateFlow()

    fun byId(id: String): PlaylistFolder? = foldersState.value.firstOrNull { it.id == id }

    internal fun seed(folders: List<PlaylistFolder>) {
        foldersState.value = folders
    }

    @Throws(Exception::class)
    suspend fun fetchAll(): Unit = onMain {
        foldersState.value = api.getList("playlist-folders", PlaylistFolder.serializer())
    }

    @Throws(Exception::class)
    suspend fun create(name: String): PlaylistFolder = onMain {
        val json = api.post("playlist-folders", buildJsonObject { put("name", name) })
        val folder = KoelJson.decodeFromJsonElement(PlaylistFolder.serializer(), json)
        foldersState.value += folder
        folder
    }

    @Throws(Exception::class)
    suspend fun rename(folder: PlaylistFolder, name: String): Unit = onMain {
        api.patch("playlist-folders/${folder.id}", buildJsonObject { put("name", name) })
        foldersState.value = foldersState.value.map { if (it.id == folder.id) it.copy(name = name) else it }
    }

    /** Removes the folder right away, and puts it back if the server refuses. */
    @Throws(Exception::class)
    suspend fun remove(folder: PlaylistFolder): Unit = onMain {
        val index = foldersState.value.indexOfFirst { it.id == folder.id }.coerceAtLeast(0)
        foldersState.value = foldersState.value.filterNot { it.id == folder.id }

        try {
            api.delete("playlist-folders/${folder.id}")
        } catch (error: Exception) {
            val current = foldersState.value
            foldersState.value = current.take(index) + folder + current.drop(index)
            throw error
        }
    }

    internal fun reset() {
        foldersState.value = emptyList()
    }
}
