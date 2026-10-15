package phanan.koel.shared.stores

import kotlinx.coroutines.flow.MutableStateFlow
import kotlinx.coroutines.flow.StateFlow
import kotlinx.coroutines.flow.asStateFlow
import kotlinx.coroutines.sync.Mutex
import kotlinx.coroutines.sync.withLock
import phanan.koel.shared.api.Page

/** A server-paginated list whose entities live in a [Vault]. */
internal class Pager<T : Any>(
    private val vault: Vault<T>,
    private val idOf: (T) -> String,
    private val fetch: suspend (page: Int) -> Page<T>,
) {
    private val list = vault.liveList()
    val items: StateFlow<List<T>> = list.items

    private val hasMoreState = MutableStateFlow(true)
    val hasMore: StateFlow<Boolean> = hasMoreState.asStateFlow()

    private var nextPage: Int? = 1
    private val mutex = Mutex()

    suspend fun loadMore() = mutex.withLock {
        val page = nextPage ?: return@withLock
        val result = fetch(page)
        list.append(vault.sync(result.items).map(idOf))
        setNextPage(result.nextPage)
    }

    /** Swaps the list only once the first page arrives, so the old one stays visible meanwhile. */
    suspend fun refresh() = mutex.withLock {
        val result = fetch(1)
        list.ids = vault.sync(result.items).map(idOf)
        setNextPage(result.nextPage)
    }

    fun reset() {
        list.ids = emptyList()
        setNextPage(1)
    }

    private fun setNextPage(page: Int?) {
        nextPage = page
        hasMoreState.value = page != null
    }
}
