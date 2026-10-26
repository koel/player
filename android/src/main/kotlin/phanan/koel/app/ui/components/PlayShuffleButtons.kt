package phanan.koel.app.ui.components

import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.height
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.size
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.filled.PlayArrow
import androidx.compose.material.icons.filled.Shuffle
import androidx.compose.material3.Icon
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.Surface
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.graphics.vector.ImageVector
import androidx.compose.ui.unit.dp
import phanan.koel.app.ui.theme.KoelColors
import phanan.koel.app.ui.theme.KoelPills

/** Play and Shuffle pills above a list of songs, like the Flutter app's. */
@Composable
fun PlayShuffleButtons(onPlay: () -> Unit, onShuffle: () -> Unit, enabled: Boolean = true) {
    Row(
        modifier = Modifier.fillMaxWidth().padding(horizontal = 16.dp, vertical = 8.dp),
        horizontalArrangement = Arrangement.spacedBy(10.dp),
    ) {
        PillButton("Play", Icons.Default.PlayArrow, onPlay, enabled, Modifier.weight(1f))
        PillButton("Shuffle", Icons.Default.Shuffle, onShuffle, enabled, Modifier.weight(1f))
    }
}

/** Koel's translucent pill with an icon and a label. */
@Composable
fun PillButton(label: String, icon: ImageVector, onClick: () -> Unit, enabled: Boolean = true, modifier: Modifier = Modifier) {
    Surface(
        onClick = onClick,
        enabled = enabled,
        shape = KoelPills.shape,
        color = KoelColors.pill,
        contentColor = KoelColors.secondaryText,
        border = KoelPills.border,
        modifier = modifier.height(48.dp),
    ) {
        Row(Modifier.padding(horizontal = 16.dp), horizontalArrangement = Arrangement.Center, verticalAlignment = Alignment.CenterVertically) {
            Icon(icon, contentDescription = null, modifier = Modifier.size(18.dp))
            Text(label, style = MaterialTheme.typography.labelLarge, modifier = Modifier.padding(start = 8.dp))
        }
    }
}
