package phanan.koel.app.ui.components

import androidx.compose.foundation.background
import androidx.compose.foundation.clickable
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.RowScope
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.size
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.automirrored.filled.PlaylistAdd
import androidx.compose.material.icons.automirrored.filled.PlaylistPlay
import androidx.compose.material.icons.automirrored.filled.QueueMusic
import androidx.compose.material.icons.filled.FavoriteBorder
import androidx.compose.material.icons.filled.HeartBroken
import androidx.compose.material.icons.filled.LibraryMusic
import androidx.compose.material.icons.filled.Mic
import androidx.compose.material.icons.filled.RemoveCircleOutline
import androidx.compose.material.icons.outlined.ArrowCircleDown
import androidx.compose.material.icons.outlined.FormatQuote
import androidx.compose.material.icons.outlined.RemoveCircleOutline
import androidx.compose.material3.Icon
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.runtime.getValue
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.alpha
import androidx.compose.ui.graphics.vector.ImageVector
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.text.style.TextAlign
import androidx.compose.ui.text.style.TextOverflow
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import androidx.lifecycle.compose.collectAsStateWithLifecycle
import phanan.koel.app.AppSheet
import phanan.koel.app.ui.LocalAppModel
import phanan.koel.app.ui.theme.KoelColors
import phanan.koel.shared.models.Episode
import phanan.koel.shared.models.Playable
import phanan.koel.shared.models.Song

/**
 * The long-press and "…" menu for a song or episode, laid out like the iOS context menu: a compact
 * preview, then Favorite, Details and Download side by side, then the rest in groups.
 */
@Composable
fun PlayableActionsSheet(playable: Playable, onDismiss: () -> Unit) {
    val app = LocalAppModel.current
    val actions = app.actions
    val state by app.core.player.state.collectAsStateWithLifecycle()
    val downloaded by app.core.downloads.downloadedIds.collectAsStateWithLifecycle()
    val downloading by app.core.downloads.downloading.collectAsStateWithLifecycle()
    val isCurrent = state.current?.id == playable.id
    val isQueued = state.queue.any { it.id == playable.id }
    val isOnline = !app.isOffline

    fun run(action: () -> Unit) {
        onDismiss()
        action()
    }

    fun leaveNowPlaying(action: () -> Unit) {
        app.isNowPlayingShown = false
        action()
    }

    val queueActions = buildList {
        if (!isCurrent) {
            add(MenuAction("Play Next", Icons.AutoMirrored.Filled.PlaylistPlay) { actions.playNext(playable) })
            add(MenuAction("Play Last", Icons.AutoMirrored.Filled.QueueMusic) { actions.playLast(playable) })
        }
        if (isQueued) add(MenuAction("Remove from Queue", Icons.Default.RemoveCircleOutline) { actions.removeFromQueue(playable) })
    }
    val navigationActions = buildList {
        if (playable is Song) {
            add(MenuAction("Go to Album", Icons.Default.LibraryMusic, isEnabled = isOnline, startsSection = true) { leaveNowPlaying { actions.goToAlbum(playable) } })
            add(MenuAction("Go to Artist", Icons.Default.Mic, isEnabled = isOnline) { leaveNowPlaying { actions.goToArtist(playable) } })
        }
        if (playable is Episode) {
            add(MenuAction("Go to Podcast", Icons.Default.Mic, isEnabled = isOnline, startsSection = true) { leaveNowPlaying { actions.goToArtist(playable) } })
        }
        add(MenuAction("Add to a Playlist…", Icons.AutoMirrored.Filled.PlaylistAdd, isEnabled = isOnline, startsSection = isEmpty()) {
            app.sheet = AppSheet.AddToPlaylist(listOf(playable))
        })
    }

    ActionsSheet(
        onDismiss,
        queueActions + navigationActions,
        accessory = {
            Row(Modifier.fillMaxWidth().padding(horizontal = 16.dp, vertical = 8.dp), horizontalArrangement = Arrangement.spacedBy(8.dp)) {
                QuickAction(
                    if (playable.favorite) "Undo Favorite" else "Favorite",
                    if (playable.favorite) Icons.Default.HeartBroken else Icons.Default.FavoriteBorder,
                    isEnabled = isOnline,
                ) { run { actions.toggleFavorite(playable) } }
                QuickAction("Details", Icons.Outlined.FormatQuote) { run { app.sheet = AppSheet.Details(playable) } }
                if (playable.id in downloaded) {
                    QuickAction("Remove Download", Icons.Outlined.RemoveCircleOutline, isDestructive = true) { run { actions.removeDownload(playable) } }
                } else {
                    QuickAction("Download", Icons.Outlined.ArrowCircleDown, isEnabled = isOnline && playable.id !in downloading) {
                        run { actions.download(playable) }
                    }
                }
            }
        },
    ) {
        PreviewCard(playable.artworkUrl, playable.title, "${playable.subtitle} • ${playable.collectionName}")
    }
}

/** The compact card on top of a long-press menu: cover on the left, title and subtitle beside it. */
@Composable
fun PreviewCard(artworkUrl: String?, title: String, subtitle: String?, isCircular: Boolean = false) {
    Row(
        Modifier.fillMaxWidth().padding(14.dp),
        horizontalArrangement = Arrangement.spacedBy(14.dp),
        verticalAlignment = Alignment.CenterVertically,
    ) {
        Artwork(artworkUrl, size = 88.dp, cornerRadius = 8.dp, isCircle = isCircular)
        Column(Modifier.weight(1f), verticalArrangement = Arrangement.spacedBy(4.dp)) {
            Text(
                title,
                style = MaterialTheme.typography.titleMedium.copy(fontSize = 17.sp, fontWeight = FontWeight.SemiBold),
                maxLines = 3,
                overflow = TextOverflow.Ellipsis,
            )
            subtitle?.takeIf { it.isNotBlank() }?.let {
                Text(it, color = KoelColors.secondaryText, maxLines = 2, overflow = TextOverflow.Ellipsis)
            }
        }
    }
}

@Composable
private fun RowScope.QuickAction(
    label: String,
    icon: ImageVector,
    isEnabled: Boolean = true,
    isDestructive: Boolean = false,
    onClick: () -> Unit,
) {
    val color = if (isDestructive) KoelColors.destructiveSwipe else KoelColors.text
    Column(
        Modifier
            .weight(1f)
            .background(KoelColors.placeholder, RoundedCornerShape(12.dp))
            .clickable(enabled = isEnabled, onClick = onClick)
            .alpha(if (isEnabled) 1f else 0.38f)
            .padding(vertical = 12.dp, horizontal = 4.dp),
        horizontalAlignment = Alignment.CenterHorizontally,
        verticalArrangement = Arrangement.spacedBy(6.dp),
    ) {
        Icon(icon, contentDescription = null, tint = color, modifier = Modifier.size(22.dp))
        Text(label, color = color, style = MaterialTheme.typography.labelMedium, textAlign = TextAlign.Center, maxLines = 1, overflow = TextOverflow.Ellipsis)
    }
}
