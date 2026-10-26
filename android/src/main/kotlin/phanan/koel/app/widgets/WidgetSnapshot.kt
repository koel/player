package phanan.koel.app.widgets

import org.json.JSONArray
import org.json.JSONObject
import phanan.koel.shared.player.PlaybackState
import phanan.koel.shared.models.Playable
import phanan.koel.shared.storage.KeyValueStore

/** What the app last showed on its widgets, saved so they still show it after the app is closed. */
data class WidgetSnapshot(val nowPlaying: NowPlaying? = null, val recentlyPlayed: List<RecentItem> = emptyList()) {
    data class NowPlaying(
        val title: String,
        val subtitle: String,
        val artworkUrl: String?,
        val isPlaying: Boolean,
        val isRadio: Boolean,
    )

    data class RecentItem(val id: String, val title: String, val subtitle: String, val artworkUrl: String?)

    /**
     * Until the app fetches the full list again, it only knows what was played since it started,
     * so the rest of the saved list stays below that.
     */
    fun keepingOlderRecent(saved: WidgetSnapshot): WidgetSnapshot {
        val ids = recentlyPlayed.map { it.id }.toSet()
        return copy(recentlyPlayed = (recentlyPlayed + saved.recentlyPlayed.filter { it.id !in ids }).take(MAX_RECENT_ITEMS))
    }

    /** A fresh start of the app has nothing playing yet. */
    fun stopped() = copy(nowPlaying = nowPlaying?.copy(isPlaying = false))

    fun encode(): String = JSONObject()
        .put("nowPlaying", nowPlaying?.let {
            JSONObject()
                .put("title", it.title)
                .put("subtitle", it.subtitle)
                .put("artworkUrl", it.artworkUrl)
                .put("isPlaying", it.isPlaying)
                .put("isRadio", it.isRadio)
        })
        .put("recentlyPlayed", JSONArray(recentlyPlayed.map {
            JSONObject().put("id", it.id).put("title", it.title).put("subtitle", it.subtitle).put("artworkUrl", it.artworkUrl)
        }))
        .toString()

    companion object {
        const val MAX_RECENT_ITEMS = 12
        private const val STORAGE_KEY = "widget_snapshot"

        fun of(state: PlaybackState, recent: List<Playable>): WidgetSnapshot {
            val station = state.radioStation
            val current = state.current
            val nowPlaying = when {
                station != null -> NowPlaying(state.radioStreamTitle ?: station.name, station.name, station.logo, state.isPlaying, isRadio = true)
                current != null -> NowPlaying(current.title, current.subtitle, current.artworkUrl, state.isPlaying, isRadio = false)
                else -> null
            }
            return WidgetSnapshot(
                nowPlaying,
                recent.take(MAX_RECENT_ITEMS).map { RecentItem(it.id, it.title, it.subtitle, it.artworkUrl) },
            )
        }

        fun decode(saved: String): WidgetSnapshot? = runCatching {
            val json = JSONObject(saved)
            val nowPlaying = json.optJSONObject("nowPlaying")?.let {
                NowPlaying(
                    it.getString("title"),
                    it.getString("subtitle"),
                    it.optString("artworkUrl").ifEmpty { null },
                    it.getBoolean("isPlaying"),
                    it.getBoolean("isRadio"),
                )
            }
            val recent = json.optJSONArray("recentlyPlayed") ?: JSONArray()
            WidgetSnapshot(
                nowPlaying,
                (0 until recent.length()).map { index ->
                    val item = recent.getJSONObject(index)
                    RecentItem(item.getString("id"), item.getString("title"), item.getString("subtitle"), item.optString("artworkUrl").ifEmpty { null })
                },
            )
        }.getOrNull()

        fun read(store: KeyValueStore): WidgetSnapshot = store.get(STORAGE_KEY)?.let(::decode) ?: WidgetSnapshot()

        fun write(store: KeyValueStore, snapshot: WidgetSnapshot) = store.set(STORAGE_KEY, snapshot.encode())
    }
}
