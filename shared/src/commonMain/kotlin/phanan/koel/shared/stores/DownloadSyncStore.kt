package phanan.koel.shared.stores

import kotlinx.coroutines.CancellationException
import kotlinx.coroutines.CoroutineScope
import kotlinx.coroutines.Job
import kotlinx.coroutines.delay
import kotlinx.coroutines.flow.MutableStateFlow
import kotlinx.coroutines.flow.StateFlow
import kotlinx.coroutines.flow.asStateFlow
import kotlinx.coroutines.launch
import kotlinx.serialization.builtins.ListSerializer
import kotlinx.serialization.json.JsonArray
import kotlinx.serialization.json.JsonPrimitive
import kotlinx.serialization.json.buildJsonObject
import phanan.koel.shared.api.ApiClient
import phanan.koel.shared.json.KoelJson
import phanan.koel.shared.models.Playable
import phanan.koel.shared.models.Song
import kotlin.time.Duration.Companion.minutes

data class DownloadSyncResult(val updatedCount: Int, val removedCount: Int, val error: String? = null)

/** Brings downloaded metadata in line with the server and drops downloads the server no longer has. */
class DownloadSyncStore internal constructor(
    private val api: ApiClient,
    private val downloads: DownloadStore,
    private val playableStore: PlayableStore,
    private val scope: CoroutineScope,
) {
    private val syncingState = MutableStateFlow(false)
    val syncing: StateFlow<Boolean> = syncingState.asStateFlow()

    private val lastSyncResultState = MutableStateFlow<DownloadSyncResult?>(null)
    val lastSyncResult: StateFlow<DownloadSyncResult?> = lastSyncResultState.asStateFlow()

    private var scheduledSync: Job? = null

    /** Call when the device is online; a later call restarts the wait. */
    fun syncAfterDelay() {
        scheduledSync?.cancel()
        scheduledSync = scope.launch {
            delay(SYNC_DELAY)
            sync()
        }
    }

    @Throws(Exception::class)
    suspend fun sync() {
        val local = downloads.playables.value
        if (local.isEmpty() || syncingState.value) return

        syncingState.value = true
        try {
            lastSyncResultState.value = syncWithServer(local)
        } catch (exception: CancellationException) {
            throw exception
        } catch (exception: Exception) {
            lastSyncResultState.value = DownloadSyncResult(0, 0, exception.message ?: exception.toString())
        } finally {
            syncingState.value = false
        }
    }

    private suspend fun syncWithServer(local: List<Playable>): DownloadSyncResult {
        val response = api.post("songs/by-ids", buildJsonObject {
            put("ids", JsonArray(local.map { JsonPrimitive(it.id) }))
        })
        val remote = KoelJson.decodeFromJsonElement(ListSerializer(Playable.serializer()), response)
        val remoteIds = remote.map(Playable::id).toSet()

        val gone = local.filterNot { it.id in remoteIds }
        gone.forEach(downloads::remove)

        val localById = local.associateBy(Playable::id)
        val changed = remote.filter { serverPlayable ->
            val localPlayable = localById[serverPlayable.id]
            localPlayable is Song && serverPlayable is Song && localPlayable.differsFrom(serverPlayable)
        }
        playableStore.sync(changed)

        return DownloadSyncResult(updatedCount = changed.size, removedCount = gone.size)
    }

    private fun Song.differsFrom(server: Song) =
        title != server.title ||
            lyrics != server.lyrics ||
            artistName != server.artistName ||
            albumName != server.albumName ||
            albumCover != server.albumCover ||
            track != server.track ||
            disc != server.disc ||
            genre != server.genre ||
            year != server.year ||
            favorite != server.favorite

    private companion object {
        val SYNC_DELAY = 5.minutes
    }
}
