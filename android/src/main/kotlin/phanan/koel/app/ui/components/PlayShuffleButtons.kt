package phanan.koel.app.ui.components

import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.padding
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.filled.PlayArrow
import androidx.compose.material.icons.filled.Shuffle
import androidx.compose.runtime.Composable
import androidx.compose.ui.Modifier
import androidx.compose.ui.unit.dp

/** Play and Shuffle glass buttons above a list of songs. */
@Composable
fun PlayShuffleButtons(onPlay: () -> Unit, onShuffle: () -> Unit, enabled: Boolean = true) {
    Row(
        modifier = Modifier.fillMaxWidth().padding(horizontal = 16.dp, vertical = 8.dp),
        horizontalArrangement = Arrangement.spacedBy(10.dp),
    ) {
        GlassButton("Play", onPlay, Modifier.weight(1f), Icons.Default.PlayArrow, enabled, isLarge = true)
        GlassButton("Shuffle", onShuffle, Modifier.weight(1f), Icons.Default.Shuffle, enabled, isLarge = true)
    }
}
