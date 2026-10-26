package phanan.koel.app.ui.components

import androidx.compose.foundation.background
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.size
import androidx.compose.foundation.shape.CircleShape
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.runtime.Composable
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.clip
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.layout.ContentScale
import androidx.compose.ui.res.painterResource
import androidx.compose.ui.unit.Dp
import androidx.compose.ui.unit.dp
import coil3.compose.AsyncImage
import phanan.koel.app.R

/** A cover, falling back to Koel's default cover while it loads or when there is none. */
@Composable
fun Artwork(
    url: String?,
    modifier: Modifier = Modifier,
    size: Dp? = null,
    cornerRadius: Dp = 8.dp,
    isCircle: Boolean = false,
) {
    val placeholder = painterResource(R.drawable.default_cover)
    AsyncImage(
        model = url?.takeIf { it.isNotBlank() },
        contentDescription = null,
        placeholder = placeholder,
        error = placeholder,
        fallback = placeholder,
        contentScale = ContentScale.Crop,
        modifier = modifier
            .then(if (size != null) Modifier.size(size) else Modifier)
            .clip(if (isCircle) CircleShape else RoundedCornerShape(cornerRadius)),
    )
}

/** A small cover with [overlay] centered over it on a dark scrim while [isOverlaid], like the now-playing bars. */
@Composable
fun ArtworkWithOverlay(
    size: Dp,
    isOverlaid: Boolean,
    scrimAlpha: Float = 0.45f,
    artwork: @Composable () -> Unit,
    overlay: @Composable () -> Unit,
) {
    Box(contentAlignment = Alignment.Center) {
        artwork()
        if (isOverlaid) {
            Box(
                Modifier.size(size).background(Color.Black.copy(alpha = scrimAlpha), RoundedCornerShape(6.dp)),
                contentAlignment = Alignment.Center,
            ) { overlay() }
        }
    }
}
