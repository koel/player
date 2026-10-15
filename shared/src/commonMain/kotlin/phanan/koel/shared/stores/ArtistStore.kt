package phanan.koel.shared.stores

import kotlinx.coroutines.flow.Flow
import kotlinx.coroutines.flow.StateFlow
import kotlinx.coroutines.flow.distinctUntilChanged
import kotlinx.coroutines.flow.map
import kotlinx.serialization.json.buildJsonObject
import kotlinx.serialization.json.jsonObject
import kotlinx.serialization.json.put
import phanan.koel.shared.api.ApiClient
import phanan.koel.shared.json.string
import phanan.koel.shared.models.Artist
import phanan.koel.shared.models.ArtistSortField
import phanan.koel.shared.models.SortOrder

class ArtistStore internal constructor(
    private val api: ApiClient,
    private val playables: PlayableStore,
    private val albums: AlbumStore,
) {
    internal val vault = Vault<Artist> { it.id }

    var sortField: String = ArtistSortField.NAME
        private set
    var sortOrder: SortOrder = SortOrder.ASC
        private set

    private val pager = Pager(vault, Artist::id) { page ->
        api.getPage("artists?page=$page&sort=$sortField&order=${sortOrder.value}", Artist.serializer())
    }

    val items: StateFlow<List<Artist>> = pager.items
    val hasMore: StateFlow<Boolean> = pager.hasMore

    fun byId(id: String): Artist? = vault[id]

    fun observe(id: String): Flow<Artist?> = vault.entities.map { it[id] }.distinctUntilChanged()

    @Throws(Exception::class)
    suspend fun loadMore() = pager.loadMore()

    /** Without a [sortOrder], keeps the current one, or goes back to ascending when [sortField] changes. */
    @Throws(Exception::class)
    suspend fun refresh(sortField: String = this.sortField, sortOrder: SortOrder? = null) {
        this.sortOrder = sortOrder ?: if (sortField == this.sortField) this.sortOrder else SortOrder.ASC
        this.sortField = sortField
        pager.refresh()
    }

    @Throws(Exception::class)
    suspend fun resolve(id: String, forceRefresh: Boolean = false): Artist {
        val cached = vault[id]
        if (cached != null && !forceRefresh) return cached

        return vault.sync(api.get("artists/$id", Artist.serializer()))
    }

    @Throws(Exception::class)
    suspend fun toggleFavorite(artist: Artist) {
        val wasFavorite = (vault[artist.id] ?: vault.sync(artist)).favorite
        vault.update(artist.id) { it.copy(favorite = !wasFavorite) }

        try {
            api.post("favorites/toggle", buildJsonObject {
                put("type", "artist")
                put("id", artist.id)
            })
        } catch (error: Exception) {
            vault.update(artist.id) { it.copy(favorite = wasFavorite) }
            throw error
        }
    }

    @Throws(Exception::class)
    suspend fun update(artist: Artist, name: String): Artist {
        val response = api.put("artists/${artist.id}", buildJsonObject { put("name", name) }).jsonObject

        val savedName = response.string("name") ?: name
        val updated = vault.update(artist.id) { it.copy(name = savedName) }
            ?: vault.sync(artist.copy(name = savedName))

        if (savedName != artist.name) {
            playables.applyArtistRename(artist.id, savedName)
            albums.applyArtistRename(artist.id, savedName)
        }

        return updated
    }

    internal fun sync(artists: List<Artist>): List<Artist> = vault.sync(artists)

    internal fun reset() {
        vault.clear()
        pager.reset()
    }
}
