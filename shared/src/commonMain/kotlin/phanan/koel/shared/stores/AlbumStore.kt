package phanan.koel.shared.stores

import kotlinx.coroutines.flow.Flow
import kotlinx.coroutines.flow.StateFlow
import kotlinx.coroutines.flow.distinctUntilChanged
import kotlinx.coroutines.flow.map
import kotlinx.serialization.json.buildJsonObject
import kotlinx.serialization.json.jsonObject
import kotlinx.serialization.json.put
import phanan.koel.shared.api.ApiClient
import phanan.koel.shared.json.int
import phanan.koel.shared.json.string
import phanan.koel.shared.models.Album
import phanan.koel.shared.models.AlbumSortField
import phanan.koel.shared.models.SortOrder

class AlbumStore internal constructor(
    private val api: ApiClient,
    private val playables: PlayableStore,
) {
    internal val vault = Vault<Album> { it.id }

    var sortField: String = AlbumSortField.NAME
        private set
    var sortOrder: SortOrder = SortOrder.ASC
        private set

    private val pager = Pager(vault, Album::id) { page ->
        api.getPage("albums?page=$page&sort=$sortField&order=${sortOrder.value}", Album.serializer())
    }

    val items: StateFlow<List<Album>> = pager.items
    val hasMore: StateFlow<Boolean> = pager.hasMore

    fun byId(id: String): Album? = vault[id]

    fun observe(id: String): Flow<Album?> = vault.entities.map { it[id] }.distinctUntilChanged()

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
    suspend fun resolve(id: String, forceRefresh: Boolean = false): Album {
        val cached = vault[id]
        if (cached != null && !forceRefresh) return cached

        return vault.sync(api.get("albums/$id", Album.serializer()))
    }

    @Throws(Exception::class)
    suspend fun toggleFavorite(album: Album) {
        val wasFavorite = (vault[album.id] ?: vault.sync(album)).favorite
        vault.update(album.id) { it.copy(favorite = !wasFavorite) }

        try {
            api.post("favorites/toggle", buildJsonObject {
                put("type", "album")
                put("id", album.id)
            })
        } catch (error: Exception) {
            vault.update(album.id) { it.copy(favorite = wasFavorite) }
            throw error
        }
    }

    @Throws(Exception::class)
    suspend fun update(album: Album, name: String, year: Int?): Album {
        val response = api.put("albums/${album.id}", buildJsonObject {
            put("name", name)
            put("year", year)
        }).jsonObject

        val savedName = response.string("name") ?: name
        val savedYear = response.int("year")
        val updated = vault.update(album.id) { it.copy(name = savedName, year = savedYear) }
            ?: vault.sync(album.copy(name = savedName, year = savedYear))

        if (savedName != album.name) playables.applyAlbumRename(album.id, savedName)

        return updated
    }

    internal fun sync(albums: List<Album>): List<Album> = vault.sync(albums)

    internal fun applyArtistRename(artistId: String, name: String) =
        vault.updateWhere({ it.artistId == artistId && it.artistName != name }) { it.copy(artistName = name) }

    internal fun reset() {
        vault.clear()
        pager.reset()
    }
}
