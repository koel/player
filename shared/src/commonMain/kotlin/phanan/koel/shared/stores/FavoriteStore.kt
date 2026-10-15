package phanan.koel.shared.stores

import phanan.koel.shared.onMain
import kotlinx.coroutines.flow.StateFlow
import kotlinx.serialization.json.JsonElement
import kotlinx.serialization.json.JsonPrimitive
import kotlinx.serialization.json.buildJsonObject
import kotlinx.serialization.json.put
import kotlinx.serialization.json.putJsonArray
import phanan.koel.shared.api.ApiClient
import phanan.koel.shared.models.Playable

/**
 * Favorite songs and episodes, in the server's order, which is the user's custom order on
 * servers that support [phanan.koel.shared.session.Feature.CUSTOM_FAVORITES_ORDER].
 */
class FavoriteStore internal constructor(
    private val api: ApiClient,
    private val playables: PlayableStore,
) {
    private val list = playables.vault.liveList()
    val items: StateFlow<List<Playable>> = list.items

    private var loaded = false

    @Throws(Exception::class)
    suspend fun fetch(forceRefresh: Boolean = false): List<Playable> = onMain {
        if (loaded && !forceRefresh) return@onMain items.value

        list.ids = playables.sync(api.get("songs/favorite")).map(Playable::id)
        loaded = true
        items.value
    }

    @Throws(Exception::class)
    suspend fun toggle(playable: Playable): Unit = onMain {
        saveOptimistically(playable, favorite = !current(playable).favorite) {
            api.post("interaction/like", buildJsonObject { put("song", playable.id) })
        }
    }

    @Throws(Exception::class)
    suspend fun unlike(playable: Playable) = onMain {
        saveOptimistically(playable, favorite = false) {
            api.post("interaction/batch/unlike", buildJsonObject {
                putJsonArray("songs") { add(JsonPrimitive(playable.id)) }
            })
        }
    }

    internal fun reset() {
        list.ids = emptyList()
        loaded = false
    }

    private suspend fun saveOptimistically(playable: Playable, favorite: Boolean, request: suspend () -> JsonElement) {
        val wasFavorite = current(playable).favorite
        val originalIds = list.ids

        setFavorite(playable.id, favorite)
        try {
            request()
        } catch (error: Exception) {
            setFavorite(playable.id, wasFavorite)
            list.ids = originalIds
            throw error
        }
    }

    private fun current(playable: Playable): Playable =
        playables.byId(playable.id) ?: playables.sync(listOf(playable)).single()

    private fun setFavorite(id: String, favorite: Boolean) {
        playables.update(id) { it.withFavorite(favorite) }
        if (favorite) list.append(listOf(id)) else list.remove(id)
    }
}
