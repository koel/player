package phanan.koel.shared.stores

import phanan.koel.shared.onMain
import kotlinx.coroutines.flow.MutableStateFlow
import kotlinx.coroutines.flow.StateFlow
import kotlinx.coroutines.flow.asStateFlow
import phanan.koel.shared.api.ApiClient
import phanan.koel.shared.models.Playable

class RecentlyPlayedStore internal constructor(
    private val api: ApiClient,
    private val playables: PlayableStore,
) {
    private val list = playables.vault.liveList()

    /** Most recently played first. */
    val items: StateFlow<List<Playable>> = list.items

    private val loadedState = MutableStateFlow(false)
    val loaded: StateFlow<Boolean> = loadedState.asStateFlow()

    @Throws(Exception::class)
    suspend fun fetch(): List<Playable> = onMain {
        list.ids = playables.sync(api.get("songs/recently-played")).map(Playable::id)
        loadedState.value = true
        items.value
    }

    fun add(playable: Playable) {
        if (playables.byId(playable.id) == null) playables.sync(listOf(playable))
        list.prepend(playable.id)
    }

    /** Items already in the list were played after the server's snapshot was taken, so they stay on top. */
    internal fun seed(snapshot: List<Playable>) {
        list.ids = (list.ids + snapshot.map(Playable::id)).distinct()
    }

    internal fun reset() {
        list.ids = emptyList()
        loadedState.value = false
    }
}
