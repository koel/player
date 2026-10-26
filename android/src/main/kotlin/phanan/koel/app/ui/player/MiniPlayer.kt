package phanan.koel.app.ui.player

import androidx.compose.foundation.clickable
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.size
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.filled.FastForward
import androidx.compose.material.icons.filled.Warning
import androidx.compose.material3.CircularProgressIndicator
import androidx.compose.material3.Icon
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.Surface
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.runtime.getValue
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.graphics.vector.ImageVector
import androidx.compose.ui.semantics.contentDescription
import androidx.compose.ui.semantics.semantics
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.text.style.TextOverflow
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import androidx.lifecycle.compose.collectAsStateWithLifecycle
import phanan.koel.app.ui.LocalAppModel
import phanan.koel.app.ui.components.Artwork
import phanan.koel.app.ui.components.ArtworkWithOverlay
import phanan.koel.app.ui.components.PlayPauseIcon
import phanan.koel.app.ui.theme.BrandMesh
import phanan.koel.app.ui.theme.KoelColors
import phanan.koel.app.ui.theme.KoelPills
import phanan.koel.shared.player.PlaybackState

private val ArtworkSize = 30.dp

/**
 * Above the navigation bar while something is playing; tapping it opens Now Playing. A rounded,
 * brand-purple card with a hairline edge like the Flutter app's, laid out like the iOS one.
 */
@Composable
fun MiniPlayer(onOpen: () -> Unit) {
    val app = LocalAppModel.current
    val state by app.core.player.state.collectAsStateWithLifecycle()
    val station = state.radioStation

    val title = station?.let { state.radioStreamTitle ?: it.name } ?: state.current?.title.orEmpty()
    val subtitle = when {
        station == null -> state.current?.subtitle
        state.isBuffering -> "Connecting…"
        state.radioStreamTitle != null -> station.name
        else -> null
    }

    Surface(
        color = BrandMesh.colors[5],
        shape = RoundedCornerShape(14.dp),
        border = KoelPills.border,
        modifier = Modifier.fillMaxWidth().padding(horizontal = 6.dp, vertical = 6.dp),
    ) {
        Row(
            modifier = Modifier
                .clickable(onClickLabel = "Open Now Playing", onClick = onOpen)
                .padding(horizontal = 12.dp, vertical = 10.dp),
            horizontalArrangement = Arrangement.spacedBy(12.dp),
            verticalAlignment = Alignment.CenterVertically,
        ) {
            MiniArtwork(station?.logo ?: state.current?.artworkUrl, state)
            Column(Modifier.weight(1f)) {
                Text(
                    title,
                    style = MaterialTheme.typography.bodyMedium.copy(fontSize = 15.sp, fontWeight = FontWeight.Medium),
                    maxLines = 1,
                    overflow = TextOverflow.Ellipsis,
                )
                subtitle?.let {
                    Text(it, style = MaterialTheme.typography.bodySmall.copy(fontSize = 12.sp), color = KoelColors.secondaryText, maxLines = 1, overflow = TextOverflow.Ellipsis)
                }
            }
            MiniButton(if (state.isPlaying) "Pause" else "Play", { app.core.player.togglePlayPause() }) {
                PlayPauseIcon(state.isPlaying, size = 24.dp)
            }
            if (!state.isRadioMode) {
                MiniButton("Next", { app.core.player.skipToNext() }) { MiniIcon(Icons.Default.FastForward) }
            }
        }
    }
}

/** The cover, dimmed under a warning when playback failed, or under a spinner while buffering. */
@Composable
private fun MiniArtwork(url: String?, state: PlaybackState) {
    ArtworkWithOverlay(
        size = ArtworkSize,
        isOverlaid = state.hasFailed || state.isBuffering,
        scrimAlpha = 0.55f,
        artwork = { Artwork(url, size = ArtworkSize, cornerRadius = 6.dp) },
    ) {
        if (state.hasFailed) {
            Icon(
                Icons.Default.Warning,
                contentDescription = "Couldn't play this item",
                tint = Color.White,
                modifier = Modifier.size(14.dp),
            )
        } else {
            CircularProgressIndicator(Modifier.size(14.dp), color = Color.White, strokeWidth = 1.5.dp)
        }
    }
}

@Composable
private fun MiniButton(label: String, onClick: () -> Unit, icon: @Composable () -> Unit) {
    Box(
        Modifier.size(32.dp).clickable(onClick = onClick).semantics { contentDescription = label },
        contentAlignment = Alignment.Center,
    ) { icon() }
}

@Composable
private fun MiniIcon(icon: ImageVector) {
    Icon(icon, contentDescription = null, tint = Color.White, modifier = Modifier.size(24.dp))
}
