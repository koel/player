package phanan.koel.app

import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.automirrored.filled.PlaylistAdd
import androidx.compose.material.icons.filled.PlaylistRemove
import androidx.compose.material.icons.filled.ArrowCircleDown
import androidx.compose.material.icons.filled.ArrowCircleRight
import kotlinx.coroutines.MainScope
import kotlinx.coroutines.launch
import phanan.koel.app.ui.main.Route
import phanan.koel.shared.models.Episode
import phanan.koel.shared.models.Playable
import phanan.koel.shared.models.Playlist
import phanan.koel.shared.models.Song

/** What the menus and swipes do with a song or an episode. */
class PlayableActions(private val app: AppModel) {
    private val scope = MainScope()
    private val player get() = app.core.player

    fun play(playable: Playable) = player.play(playable)

    fun play(playables: List<Playable>, shuffled: Boolean = false) {
        if (playables.isNotEmpty()) player.replaceQueue(playables, shuffle = shuffled, autoPlay = true)
    }

    /** Plays the list from [playable] on, like tapping a song in a list does. */
    fun playFrom(playable: Playable, playables: List<Playable>) {
        player.replaceQueue(playables, shuffle = false, autoPlay = false)
        play(playable)
    }

    fun playNext(playable: Playable) {
        player.playNext(playable)
        showQueuedNext()
    }

    fun playLast(playable: Playable) {
        player.queueToBottom(playable)
        showQueuedLast()
    }

    fun playNext(playables: List<Playable>) {
        if (playables.isEmpty()) return
        player.playNext(playables)
        showQueuedNext()
    }

    fun playLast(playables: List<Playable>) {
        if (playables.isEmpty()) return
        player.queueToBottom(playables)
        showQueuedLast()
    }

    fun removeFromQueue(playable: Playable) {
        player.removeFromQueue(playable)
        app.messages.show("Removed", "Removed from queue.", Icons.Filled.PlaylistRemove)
    }

    private fun showQueuedNext() = app.messages.show("Queued", "To be played next.", Icons.Filled.ArrowCircleRight)

    private fun showQueuedLast() = app.messages.show("Queued", "Queued to bottom.", Icons.Filled.ArrowCircleDown)

    fun toggleFavorite(playable: Playable) {
        scope.launch {
            runCatching { app.core.favorites.toggle(playable) }.onFailure { app.messages.showError() }
        }
    }

    fun download(playable: Playable) {
        scope.launch {
            runCatching { app.core.downloads.download(playable) }.onFailure { app.messages.showError("Download failed") }
        }
    }

    fun addToPlaylist(playables: List<Playable>, playlist: Playlist) {
        scope.launch {
            runCatching { app.core.playlists.addToPlaylist(playables, playlist) }
                .onSuccess { app.messages.show("Added", "Item added to playlist.", Icons.AutoMirrored.Filled.PlaylistAdd) }
                .onFailure { app.messages.showError(message = "Could not add to playlist.") }
        }
    }

    fun removeDownload(playable: Playable) = app.core.downloads.remove(playable)

    fun goToAlbum(playable: Playable) {
        (playable as? Song)?.let { app.navigator.push(Route.Album(it.albumId)) }
    }

    fun goToArtist(playable: Playable) {
        when (playable) {
            is Song -> app.navigator.push(Route.Artist(playable.artistId))
            is Episode -> app.navigator.push(Route.Podcast(playable.podcastId))
        }
    }
}
