package phanan.koel.shared.stores

import kotlinx.coroutines.flow.Flow
import kotlinx.coroutines.flow.MutableStateFlow
import kotlinx.coroutines.flow.StateFlow
import kotlinx.coroutines.flow.asStateFlow
import kotlinx.coroutines.flow.distinctUntilChanged
import kotlinx.coroutines.flow.map

/**
 * The single source of truth for entities of one kind, keyed by ID. Every list in the app
 * holds IDs and resolves them here, so an update (a favorite toggle, a rename) shows up in
 * every list at once.
 */
internal class Vault<T : Any>(private val idOf: (T) -> String) {
    private val state = MutableStateFlow<Map<String, T>>(emptyMap())
    val entities: StateFlow<Map<String, T>> = state.asStateFlow()

    private val liveLists = mutableListOf<LiveList<T>>()

    operator fun get(id: String): T? = state.value[id]

    fun sync(remote: List<T>): List<T> {
        val unique = remote.distinctBy(idOf)
        commit(state.value + unique.associateBy(idOf))
        return unique
    }

    fun sync(remote: T): T = sync(listOf(remote)).first()

    fun update(id: String, transform: (T) -> T): T? {
        val updated = transform(state.value[id] ?: return null)
        commit(state.value + (id to updated))
        return updated
    }

    fun updateWhere(predicate: (T) -> Boolean, transform: (T) -> T) =
        commit(state.value.mapValues { (_, entity) -> if (predicate(entity)) transform(entity) else entity })

    fun remove(id: String) = commit(state.value - id)

    fun clear() = commit(emptyMap())

    fun liveList(): LiveList<T> = LiveList(this).also(liveLists::add)

    fun live(ids: List<String>): Flow<List<T>> =
        state.map { entities -> ids.mapNotNull(entities::get) }.distinctUntilChanged()

    private fun commit(entities: Map<String, T>) {
        state.value = entities
        liveLists.forEach(LiveList<T>::refresh)
    }
}

/** An ordered list of IDs whose entities stay current with their [Vault], with no lag. */
internal class LiveList<T : Any>(private val vault: Vault<T>) {
    private val itemsState = MutableStateFlow<List<T>>(emptyList())
    val items: StateFlow<List<T>> = itemsState.asStateFlow()

    var ids: List<String> = emptyList()
        set(value) {
            field = value
            refresh()
        }

    fun append(newIds: List<String>) {
        ids = (ids + newIds).distinct()
    }

    fun prepend(id: String) {
        ids = listOf(id) + (ids - id)
    }

    fun remove(id: String) {
        ids = ids - id
    }

    internal fun refresh() {
        val resolved = ids.mapNotNull(vault::get)
        if (resolved != itemsState.value) itemsState.value = resolved
    }
}
