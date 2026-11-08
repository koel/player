package phanan.koel.app.ui.components

import androidx.compose.animation.core.RepeatMode
import androidx.compose.animation.core.animateFloat
import androidx.compose.animation.core.infiniteRepeatable
import androidx.compose.animation.core.rememberInfiniteTransition
import androidx.compose.animation.core.tween
import androidx.compose.foundation.Canvas
import androidx.compose.foundation.ExperimentalFoundationApi
import androidx.compose.foundation.clickable
import androidx.compose.foundation.combinedClickable
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.size
import androidx.compose.foundation.layout.width
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.filled.CheckCircle
import androidx.compose.material.icons.filled.MoreHoriz
import androidx.compose.material.icons.outlined.ArrowCircleDown
import androidx.compose.material3.CircularProgressIndicator
import androidx.compose.material3.Icon
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.runtime.getValue
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.geometry.CornerRadius
import androidx.compose.ui.geometry.Offset
import androidx.compose.ui.geometry.Size
import androidx.compose.ui.semantics.contentDescription
import androidx.compose.ui.semantics.semantics
import androidx.compose.ui.text.style.TextOverflow
import androidx.compose.ui.unit.Dp
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import androidx.lifecycle.compose.collectAsStateWithLifecycle
import phanan.koel.app.AppSheet
import phanan.koel.app.ui.LocalAppModel
import phanan.koel.app.ui.theme.DownloadedColor
import phanan.koel.app.ui.theme.KoelColors
import phanan.koel.app.ui.theme.LocalBrandColor
import phanan.koel.shared.models.Playable
import phanan.koel.shared.models.Song
import java.time.Instant

enum class PlayableRowStyle {
    /** Artwork, title, artist (or podcast). */
    Standard,
    /** Track number instead of artwork, for album screens. */
    Album,
    /** Artwork with the album as the subtitle, for artist screens. */
    Artist,
    /** No artwork, and the episode's date as the subtitle, for podcast screens. */
    Episode,
    /** For the queue under Now Playing: no queue swipes, no download or "…" buttons. */
    Queue,
}

val PlayableRowArtworkSize = 44.dp
val PlayableRowArtworkCornerRadius = 6.dp

/** The space above and below a row's content. */
val PlayableRowVerticalPadding = 8.dp

/**
 * A song or episode in a list, sized like the iOS app's rows. Swipe right to play it next, left to
 * play it last; a [SwipeToRemove] around it adds its removal to the left swipe. [trailing] goes
 * at the end of the row, such as the queue's drag handle.
 */
@OptIn(ExperimentalFoundationApi::class)
@Composable
fun PlayableRow(
    playable: Playable,
    modifier: Modifier = Modifier,
    style: PlayableRowStyle = PlayableRowStyle.Standard,
    hasQueueSwipes: Boolean = style != PlayableRowStyle.Queue,
    trailing: (@Composable () -> Unit)? = null,
    onClick: (() -> Unit)? = null,
) {
    val app = LocalAppModel.current
    val removal = LocalRowRemoval.current
    val leading = if (hasQueueSwipes) listOf(SwipeAction.playNext { app.actions.playNext(playable) }) else emptyList()
    val trailingSwipes = listOfNotNull(removal) +
        if (hasQueueSwipes) listOf(SwipeAction.playLast { app.actions.playLast(playable) }) else emptyList()

    SwipeActions(leading, trailingSwipes) {
        PlayableRowContent(playable, modifier, style, trailing, onClick)
    }
}

@OptIn(ExperimentalFoundationApi::class)
@Composable
private fun PlayableRowContent(
    playable: Playable,
    modifier: Modifier,
    style: PlayableRowStyle,
    trailing: (@Composable () -> Unit)?,
    onClick: (() -> Unit)?,
) {
    val app = LocalAppModel.current
    val state by app.core.player.state.collectAsStateWithLifecycle()
    val isCurrent = state.current?.id == playable.id
    val isPlaying = isCurrent && state.isPlaying
    val play = onClick ?: { app.actions.play(playable) }

    Row(
        modifier = modifier
            .fillMaxWidth()
            .rowDivider(
                when (style) {
                    PlayableRowStyle.Album -> RowInsets.trackNumber
                    PlayableRowStyle.Episode -> RowInsets.plain
                    else -> RowInsets.song
                },
            )
            .combinedClickable(
                onClick = play,
                onLongClick = { app.sheet = AppSheet.Actions(playable) },
                onLongClickLabel = "More",
            )
            .padding(start = 16.dp, end = 8.dp, top = PlayableRowVerticalPadding, bottom = PlayableRowVerticalPadding),
        horizontalArrangement = Arrangement.spacedBy(12.dp),
        verticalAlignment = Alignment.CenterVertically,
    ) {
        when (style) {
            PlayableRowStyle.Album -> Box(Modifier.width(24.dp), contentAlignment = Alignment.Center) {
                if (isCurrent) {
                    NowPlayingIndicator(isPlaying)
                } else {
                    Text(
                        (playable as? Song)?.track?.takeIf { it > 0 }?.toString().orEmpty(),
                        style = MaterialTheme.typography.bodyMedium.copy(fontSize = 14.sp, fontFeatureSettings = "tnum"),
                        color = KoelColors.secondaryText,
                    )
                }
            }
            PlayableRowStyle.Episode -> Unit
            else -> ArtworkWithOverlay(PlayableRowArtworkSize, isOverlaid = isCurrent, artwork = { Artwork(playable.artworkUrl, size = PlayableRowArtworkSize, cornerRadius = PlayableRowArtworkCornerRadius) }) {
                NowPlayingIndicator(isPlaying)
            }
        }

        Column(Modifier.weight(1f), verticalArrangement = Arrangement.spacedBy(2.dp)) {
            Text(
                playable.title,
                style = MaterialTheme.typography.bodyLarge.copy(fontSize = 16.sp),
                maxLines = 1,
                overflow = TextOverflow.Ellipsis,
            )
            Text(
                subtitle(playable, style),
                style = MaterialTheme.typography.bodyMedium.copy(fontSize = 13.sp),
                color = KoelColors.secondaryText,
                maxLines = 1,
                overflow = TextOverflow.Ellipsis,
            )
        }

        Row(verticalAlignment = Alignment.CenterVertically) {
            if (style != PlayableRowStyle.Queue) {
                DownloadButton(playable)
                MoreButton { app.sheet = AppSheet.Actions(playable) }
            }
            trailing?.invoke()
        }
    }
}

private fun subtitle(playable: Playable, style: PlayableRowStyle): String = when (style) {
    PlayableRowStyle.Album, PlayableRowStyle.Artist -> (playable as? Song)?.albumName ?: playable.subtitle
    PlayableRowStyle.Episode -> EpisodeDates.label(playable.createdAt, Instant.now()).orEmpty()
    else -> playable.subtitle
}

/** The "…" button on rows, a horizontal ellipsis as on iOS and in the Flutter app. */
@Composable
fun MoreButton(size: Dp = 32.dp, onClick: () -> Unit) {
    Box(
        Modifier.size(size).clickable(onClick = onClick).semantics { contentDescription = "More" },
        contentAlignment = Alignment.Center,
    ) {
        Icon(Icons.Default.MoreHoriz, contentDescription = null, tint = KoelColors.text)
    }
}

/** Bars that bounce on the item that is playing, and rest while it's paused, in the brand color. */
@Composable
fun NowPlayingIndicator(isPlaying: Boolean = true, modifier: Modifier = Modifier) {
    val color = LocalBrandColor.current
    val transition = rememberInfiniteTransition(label = "nowPlaying")
    val phases = listOf(380, 520, 440).mapIndexed { index, period ->
        transition.animateFloat(
            initialValue = 0.3f,
            targetValue = 1f,
            animationSpec = infiniteRepeatable(tween(period), RepeatMode.Reverse),
            label = "bar$index",
        )
    }
    val resting = listOf(0.45f, 0.8f, 0.6f)

    Canvas(modifier.size(18.dp).semantics { contentDescription = if (isPlaying) "Now playing" else "Paused" }) {
        val barWidth = size.width / 5
        phases.forEachIndexed { index, phase ->
            val level = if (isPlaying) phase.value else resting[index]
            val height = size.height * level
            drawRoundRect(
                color,
                topLeft = Offset(barWidth * (index * 2), size.height - height),
                size = Size(barWidth, height),
                cornerRadius = CornerRadius(barWidth / 2),
            )
        }
    }
}

/** Shows whether the playable is downloaded, and downloads it with a tap when it isn't. */
@Composable
fun DownloadButton(playable: Playable) {
    val app = LocalAppModel.current
    val downloaded by app.core.downloads.downloadedIds.collectAsStateWithLifecycle()
    val downloading by app.core.downloads.downloading.collectAsStateWithLifecycle()

    when {
        playable.id in downloading -> Box(Modifier.size(width = 24.dp, height = 32.dp), contentAlignment = Alignment.Center) {
            CircularProgressIndicator(modifier = Modifier.size(14.dp), strokeWidth = 1.5.dp, color = KoelColors.secondaryText)
        }
        playable.id in downloaded -> Box(Modifier.size(width = 24.dp, height = 32.dp), contentAlignment = Alignment.Center) {
            Icon(Icons.Default.CheckCircle, contentDescription = "Downloaded", tint = DownloadedColor, modifier = Modifier.size(16.dp))
        }
        !app.isOffline -> Box(
            Modifier
                .size(width = 24.dp, height = 32.dp)
                .clickable { app.actions.download(playable) }
                .semantics { contentDescription = "Download" },
            contentAlignment = Alignment.Center,
        ) {
            Icon(Icons.Outlined.ArrowCircleDown, contentDescription = null, tint = KoelColors.secondaryText, modifier = Modifier.size(16.dp))
        }
    }
}
