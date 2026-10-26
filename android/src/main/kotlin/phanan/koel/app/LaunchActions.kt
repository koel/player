package phanan.koel.app

import android.content.Context
import android.content.Intent
import androidx.core.content.pm.ShortcutInfoCompat
import androidx.core.content.pm.ShortcutManagerCompat
import androidx.core.graphics.drawable.IconCompat
import kotlinx.coroutines.delay

/** What the app is opened to do: the icon's long-press shortcuts, as on iOS, and taps on the widgets. */
enum class LaunchAction(val id: String) {
    Search("koel_action_search"),
    PlayFavorites("koel_action_play_favorites"),
    PlayDownloaded("koel_action_play_downloaded"),
    PlayRecent("koel_action_play_recent"),
    OpenNowPlaying("koel_open_now_playing"),
    PlayRecentItem("koel_play_recent_item");

    fun intent(context: Context, playableId: String? = null): Intent =
        Intent(context, MainActivity::class.java).setAction(id).putExtra(PLAYABLE_ID, playableId)

    private companion object {
        const val PLAYABLE_ID = "playableId"
    }

    data class Request(val action: LaunchAction, val playableId: String? = null) {
        companion object {
            fun of(intent: Intent?): Request? {
                val action = entries.firstOrNull { it.id == intent?.action } ?: return null
                return Request(action, intent?.getStringExtra(PLAYABLE_ID))
            }
        }
    }
}

object AppShortcuts {
    fun actions(hasRecent: Boolean): List<LaunchAction> =
        listOf(LaunchAction.Search, LaunchAction.PlayFavorites, LaunchAction.PlayDownloaded) +
            if (hasRecent) listOf(LaunchAction.PlayRecent) else emptyList()

    fun publish(context: Context, hasRecent: Boolean) {
        val shortcuts = actions(hasRecent).mapIndexed { rank, action ->
            val (label, icon) = appearance(action)
            ShortcutInfoCompat.Builder(context, action.id)
                .setShortLabel(label)
                .setIcon(IconCompat.createWithResource(context, icon))
                .setIntent(action.intent(context))
                .setRank(rank)
                .build()
        }
        ShortcutManagerCompat.setDynamicShortcuts(context, shortcuts)
    }

    private fun appearance(action: LaunchAction): Pair<String, Int> = when (action) {
        LaunchAction.Search -> "Search" to R.drawable.ic_shortcut_search
        LaunchAction.PlayFavorites -> "Play Favorite Songs" to R.drawable.ic_shortcut_favorites
        LaunchAction.PlayDownloaded -> "Play Downloaded" to R.drawable.ic_shortcut_downloaded
        LaunchAction.PlayRecent -> "Play Most Recent" to R.drawable.ic_shortcut_recent
        LaunchAction.OpenNowPlaying, LaunchAction.PlayRecentItem -> error("Not a shortcut")
    }
}

suspend fun AppModel.perform(request: LaunchAction.Request) {
    when (request.action) {
        LaunchAction.Search -> {
            isNowPlayingShown = false
            navigator.focusSearch()
        }
        LaunchAction.PlayFavorites -> runCatching { core.favorites.fetch() }.onSuccess { actions.play(it, shuffled = true) }
        LaunchAction.PlayDownloaded -> actions.play(core.downloads.playables.value, shuffled = true)
        LaunchAction.PlayRecent -> {
            waitForRestoredQueue()
            if (core.player.state.value.queue.isNotEmpty()) core.player.play()
        }
        LaunchAction.OpenNowPlaying -> {
            waitForRestoredQueue()
            val state = core.player.state.value
            if (state.current != null || state.isRadioMode) isNowPlayingShown = true
        }
        LaunchAction.PlayRecentItem -> {
            val recent = core.recentlyPlayed
            val playable = recent.items.value.firstOrNull { it.id == request.playableId }
                ?: runCatching { recent.fetch() }.getOrDefault(emptyList()).firstOrNull { it.id == request.playableId }
            playable?.let(actions::play)
        }
    }
}

/** On a cold launch the saved queue comes back after the library loads; give it a moment. */
private suspend fun AppModel.waitForRestoredQueue() {
    repeat(50) {
        if (core.player.state.value.queue.isNotEmpty()) return
        delay(100)
    }
}
