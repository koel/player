package phanan.koel.shared.stores

import phanan.koel.shared.onMain
import io.ktor.client.request.prepareGet
import io.ktor.client.statement.bodyAsChannel
import io.ktor.client.statement.bodyAsText
import io.ktor.http.encodeURLPath
import io.ktor.http.isSuccess
import io.ktor.utils.io.readBuffer
import kotlinx.coroutines.CoroutineScope
import kotlinx.coroutines.flow.MutableStateFlow
import kotlinx.coroutines.flow.StateFlow
import kotlinx.coroutines.flow.asStateFlow
import kotlinx.coroutines.flow.update
import kotlinx.coroutines.launch
import kotlinx.io.buffered
import kotlinx.io.files.Path
import kotlinx.io.files.SystemFileSystem
import kotlinx.serialization.builtins.ListSerializer
import kotlinx.serialization.json.JsonArray
import kotlinx.serialization.json.JsonElement
import org.kotlincrypto.hash.sha2.SHA256
import phanan.koel.shared.api.ApiClient
import phanan.koel.shared.api.HttpResponseException
import phanan.koel.shared.json.KoelJson
import phanan.koel.shared.models.Playable
import phanan.koel.shared.session.Session
import phanan.koel.shared.storage.GetStorageContainer
import phanan.koel.shared.storage.Preferences

/**
 * Songs and episodes saved for offline playback. Files and metadata live where the Flutter app
 * kept them, so downloads made before the native app survive the update.
 */
class DownloadStore internal constructor(
    private val api: ApiClient,
    private val playableStore: PlayableStore,
    private val session: Session,
    private val preferences: Preferences,
    documentsPath: String,
    scope: CoroutineScope,
) {
    private val documents = Path(documentsPath)
    private val metadata = GetStorageContainer(documents, "Downloads")
    private val liveList = playableStore.vault.liveList()

    /** Who the current list belongs to; null while logged out, so nothing is persisted then. */
    private var owner: Owner? = null
    private var persisted: Pair<Owner, List<Playable>>? = null

    val playables: StateFlow<List<Playable>> = liveList.items

    private val downloadedIdsState = MutableStateFlow<Set<String>>(emptySet())
    val downloadedIds: StateFlow<Set<String>> = downloadedIdsState.asStateFlow()

    private val downloadingState = MutableStateFlow<Set<String>>(emptySet())
    val downloading: StateFlow<Set<String>> = downloadingState.asStateFlow()

    init {
        load()
        scope.launch { playables.collect { persist() } }
    }

    fun isDownloaded(playable: Playable): Boolean = playable.id in downloadedIdsState.value

    fun isDownloading(playable: Playable): Boolean = playable.id in downloadingState.value

    fun localFileUrl(playable: Playable): String? {
        val owner = owner ?: return null
        if (!isDownloaded(playable)) return null
        return "file://" + owner.fileFor(playable).toString().encodeURLPath()
    }

    /** Re-reads the current user's downloads; called on start and after every login. */
    internal fun load() {
        val owner = currentOwner() ?: return reset()
        this.owner = owner

        val stored = metadata[owner.metadataKey]?.let(::decodePlayables).orEmpty()
        val present = stored.filter { SystemFileSystem.exists(owner.fileFor(it)) }.distinctBy(Playable::id)
        setIds(playableStore.sync(present).map(Playable::id))
    }

    @Throws(Exception::class)
    suspend fun download(playable: Playable): Unit = onMain {
        val owner = owner ?: return@onMain
        val file = owner.fileFor(playable)
        val temporaryFile = Path("$file.part")
        downloadingState.update { it + playable.id }

        try {
            SystemFileSystem.createDirectories(owner.directory)
            fetchTo(session.sourceUrl(playable), temporaryFile)
            SystemFileSystem.atomicMove(temporaryFile, file)

            if (playableStore.byId(playable.id) == null) playableStore.sync(listOf(playable))
            setIds((liveList.ids + playable.id).distinct())
        } finally {
            deleteFile(temporaryFile)
            downloadingState.update { it - playable.id }
        }
    }

    fun remove(playable: Playable) {
        owner?.let { deleteFile(it.fileFor(playable)) }
        setIds(liveList.ids - playable.id)
    }

    fun clear() {
        owner?.let { owner -> liveList.ids.forEach { id -> deleteFile(owner.fileFor(id)) } }
        setIds(emptyList())
    }

    /** Forgets the list on logout; files stay on disk for the user's next login, as in the Flutter app. */
    internal fun reset() {
        owner = null
        setIds(emptyList())
    }

    private suspend fun fetchTo(url: String, file: Path) {
        api.http.prepareGet(url).execute { response ->
            if (!response.status.isSuccess()) throw HttpResponseException(response.status.value, response.bodyAsText())

            val channel = response.bodyAsChannel()
            SystemFileSystem.sink(file).buffered().use { sink ->
                while (!channel.isClosedForRead) {
                    sink.transferFrom(channel.readBuffer(CHUNK_SIZE))
                }
            }
        }
    }

    private fun setIds(ids: List<String>) {
        liveList.ids = ids
        downloadedIdsState.value = ids.toSet()
        persist()
    }

    private fun persist() {
        val owner = owner ?: return
        val items = liveList.items.value
        // The vault is cleared on logout, possibly before we are; never let that wipe the metadata.
        if (items.size != liveList.ids.size || persisted == owner to items) return
        persisted = owner to items

        metadata[owner.metadataKey] = items.takeIf { it.isNotEmpty() }?.let {
            KoelJson.encodeToJsonElement(ListSerializer(Playable.serializer()), it)
        }
    }

    private fun decodePlayables(json: JsonElement): List<Playable> =
        (json as? JsonArray).orEmpty().mapNotNull { item ->
            runCatching { KoelJson.decodeFromJsonElement(Playable.serializer(), item) }.getOrNull()
        }

    private fun deleteFile(file: Path) {
        runCatching { SystemFileSystem.delete(file, mustExist = false) }
    }

    private fun currentOwner(): Owner? {
        val host = preferences.host ?: return null
        val email = preferences.userEmail ?: return null
        return Owner(
            metadataKey = "$host.$email.songs",
            directory = Path(documents, sha256Hex("$host$email".lowercase())),
        )
    }

    private data class Owner(val metadataKey: String, val directory: Path) {
        fun fileFor(playable: Playable) = fileFor(playable.id)

        // The `.mp3` extension is kept from the Flutter app (whose player needed one on iOS)
        // so existing files are found regardless of their real format.
        fun fileFor(id: String) = Path(directory, "CACHE_$id.mp3")
    }

    private companion object {
        const val CHUNK_SIZE = 64L * 1024

        fun sha256Hex(input: String): String =
            SHA256().digest(input.encodeToByteArray()).joinToString("") { byte ->
                (byte.toInt() and 0xff).toString(16).padStart(2, '0')
            }
    }
}
