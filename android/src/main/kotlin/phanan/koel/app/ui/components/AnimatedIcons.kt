package phanan.koel.app.ui.components

import androidx.compose.animation.AnimatedContent
import androidx.compose.animation.core.spring
import androidx.compose.animation.fadeIn
import androidx.compose.animation.fadeOut
import androidx.compose.animation.scaleIn
import androidx.compose.animation.scaleOut
import androidx.compose.animation.togetherWith
import androidx.compose.foundation.layout.size
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.filled.Favorite
import androidx.compose.material.icons.filled.FavoriteBorder
import androidx.compose.material.icons.filled.Pause
import androidx.compose.material.icons.filled.PlayArrow
import androidx.compose.material3.Icon
import androidx.compose.material3.LocalContentColor
import androidx.compose.runtime.Composable
import androidx.compose.ui.Modifier
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.unit.Dp

/** A heart that pops when it fills or empties. */
@Composable
fun FavoriteIcon(isFavorite: Boolean, size: Dp, tint: Color = LocalContentColor.current, contentDescription: String? = null) {
    AnimatedContent(
        isFavorite,
        transitionSpec = { scaleIn(spring(dampingRatio = 0.5f)) togetherWith scaleOut() },
        label = "favorite",
    ) { isShownFavorite ->
        Icon(
            if (isShownFavorite) Icons.Default.Favorite else Icons.Default.FavoriteBorder,
            contentDescription = contentDescription,
            tint = tint,
            modifier = Modifier.size(size),
        )
    }
}

/** Play or Pause, springing from one to the other. */
@Composable
fun PlayPauseIcon(isPlaying: Boolean, size: Dp, tint: Color = Color.White) {
    AnimatedContent(
        isPlaying,
        transitionSpec = { (scaleIn(spring(dampingRatio = 0.6f)) + fadeIn()) togetherWith (scaleOut() + fadeOut()) },
        label = "playPause",
    ) { isShownPlaying ->
        Icon(
            if (isShownPlaying) Icons.Default.Pause else Icons.Default.PlayArrow,
            contentDescription = null,
            tint = tint,
            modifier = Modifier.size(size),
        )
    }
}
