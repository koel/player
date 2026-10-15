package phanan.koel.shared.stores

import phanan.koel.shared.onMain
import kotlinx.coroutines.flow.StateFlow
import phanan.koel.shared.api.ApiClient
import phanan.koel.shared.models.Genre

class GenreStore internal constructor(private val api: ApiClient) {
    private val vault = Vault<Genre> { it.id }
    private val list = vault.liveList()

    /** In the server's order. */
    val items: StateFlow<List<Genre>> = list.items

    fun byId(id: String): Genre? = vault[id]

    @Throws(Exception::class)
    suspend fun fetch(): List<Genre> = onMain {
        val genres = vault.sync(api.getList("genres", Genre.serializer()))
        list.ids = genres.map(Genre::id)
        genres
    }

    internal fun reset() {
        list.ids = emptyList()
        vault.clear()
    }
}
