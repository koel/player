package phanan.koel.shared.stores

import kotlinx.coroutines.flow.Flow
import kotlinx.coroutines.flow.StateFlow
import kotlinx.coroutines.flow.distinctUntilChanged
import kotlinx.coroutines.flow.map
import kotlinx.serialization.json.buildJsonObject
import kotlinx.serialization.json.put
import phanan.koel.shared.api.ApiClient
import phanan.koel.shared.json.KoelJson
import phanan.koel.shared.models.Episode
import phanan.koel.shared.models.Podcast
import kotlin.coroutines.cancellation.CancellationException

class PodcastStore internal constructor(private val api: ApiClient) {
    internal val vault = Vault<Podcast> { it.id }
    private val list = vault.liveList()

    /** The podcasts the user is subscribed to. */
    val podcasts: StateFlow<List<Podcast>> = list.items

    fun byId(id: String): Podcast? = vault[id]

    fun observe(id: String): Flow<Podcast?> = vault.entities.map { it[id] }.distinctUntilChanged()

    @Throws(Exception::class)
    suspend fun fetchAll() {
        list.ids = vault.sync(fetchSubscriptions()).map(Podcast::id)
    }

    /** Like [fetchAll], but also drops podcasts cached by [resolve] so their state is reloaded. */
    @Throws(Exception::class)
    suspend fun refresh() {
        val subscriptions = fetchSubscriptions()
        vault.clear()
        list.ids = vault.sync(subscriptions).map(Podcast::id)
    }

    @Throws(Exception::class)
    suspend fun toggleFavorite(podcast: Podcast) {
        val wasFavorite = vault[podcast.id]?.favorite ?: podcast.favorite
        vault.update(podcast.id) { it.copy(favorite = !wasFavorite) }

        try {
            api.post("favorites/toggle", buildJsonObject {
                put("type", "podcast")
                put("id", podcast.id)
            })
        } catch (error: Exception) {
            vault.update(podcast.id) { it.copy(favorite = wasFavorite) }
            throw error
        }
    }

    /** Removes the podcast right away, and puts it back if the server refuses. */
    @Throws(Exception::class)
    suspend fun unsubscribe(podcast: Podcast) {
        val index = list.ids.indexOf(podcast.id).coerceAtLeast(0)
        list.remove(podcast.id)

        try {
            api.delete("podcasts/${podcast.id}/subscriptions")
        } catch (error: Exception) {
            list.insert(index, podcast.id)
            throw error
        }

        vault.remove(podcast.id)
    }

    @Throws(Exception::class)
    suspend fun add(url: String): Podcast {
        val json = api.post("podcasts", buildJsonObject { put("url", url) })
        val podcast = vault.sync(KoelJson.decodeFromJsonElement(Podcast.serializer(), json))
        list.append(listOf(podcast.id))
        return podcast
    }

    @Throws(Exception::class)
    suspend fun resolve(id: String, forceRefresh: Boolean = false): Podcast {
        val cached = vault[id]
        if (cached != null && !forceRefresh) return cached
        return vault.sync(api.get("podcasts/$id", Podcast.serializer()))
    }

    /** The saved playback position of the episode in seconds, or 0 when unknown. */
    @Throws(Exception::class)
    suspend fun episodeProgress(episode: Episode): Double =
        try {
            resolve(episode.podcastId).state.progresses[episode.id] ?: 0.0
        } catch (cancellation: CancellationException) {
            throw cancellation
        } catch (error: Exception) {
            0.0
        }

    internal fun reset() {
        list.ids = emptyList()
        vault.clear()
    }

    private suspend fun fetchSubscriptions(): List<Podcast> = api.getList("podcasts", Podcast.serializer())
}
