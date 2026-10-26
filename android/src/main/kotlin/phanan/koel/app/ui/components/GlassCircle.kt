package phanan.koel.app.ui.components

import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.size
import androidx.compose.foundation.shape.CircleShape
import androidx.compose.material3.Surface
import androidx.compose.runtime.Composable
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.unit.Dp
import phanan.koel.app.ui.theme.KoelColors
import phanan.koel.app.ui.theme.KoelGlass

/** A round glass button holding an icon, like iOS's Shuffle and Play buttons. */
@Composable
fun GlassCircle(size: Dp, onClick: () -> Unit, modifier: Modifier = Modifier, enabled: Boolean = true, content: @Composable () -> Unit) {
    Surface(
        onClick = onClick,
        enabled = enabled,
        shape = CircleShape,
        color = KoelGlass.fill,
        contentColor = if (enabled) Color.White else KoelColors.faintText,
        border = KoelGlass.border,
        modifier = modifier.size(size),
    ) {
        Box(contentAlignment = Alignment.Center) { content() }
    }
}
