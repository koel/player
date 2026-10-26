package phanan.koel.app.ui.player

import androidx.compose.animation.core.withInfiniteAnimationFrameMillis
import androidx.compose.foundation.layout.BoxWithConstraints
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.runtime.LaunchedEffect
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableFloatStateOf
import androidx.compose.runtime.remember
import androidx.compose.runtime.setValue
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.clipToBounds
import androidx.compose.ui.draw.drawWithContent
import androidx.compose.ui.graphics.BlendMode
import androidx.compose.ui.graphics.Brush
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.graphics.CompositingStrategy
import androidx.compose.ui.graphics.graphicsLayer
import androidx.compose.ui.layout.Layout
import androidx.compose.ui.platform.LocalDensity
import androidx.compose.ui.semantics.clearAndSetSemantics
import androidx.compose.ui.semantics.contentDescription
import androidx.compose.ui.text.TextStyle
import androidx.compose.ui.text.rememberTextMeasurer
import androidx.compose.ui.text.style.TextOverflow
import androidx.compose.ui.unit.Constraints
import androidx.compose.ui.unit.dp
import kotlin.math.roundToInt

/**
 * One line of text that, when too long to fit, pauses and then scrolls sideways in a loop, with
 * its edges fading, like the iOS app's.
 */
@Composable
fun MarqueeText(text: String, style: TextStyle, color: Color, modifier: Modifier = Modifier) {
    val measurer = rememberTextMeasurer()
    val density = LocalDensity.current
    val textWidth = remember(text, style) { measurer.measure(text, style.copy(color = color), maxLines = 1, softWrap = false).size.width }

    BoxWithConstraints(modifier.fillMaxWidth().semantics(text)) {
        val availableWidth = constraints.maxWidth
        if (textWidth <= availableWidth + 1) {
            Text(text, style = style, color = color, maxLines = 1, overflow = TextOverflow.Clip)
            return@BoxWithConstraints
        }

        var elapsed by remember(text) { mutableFloatStateOf(0f) }
        LaunchedEffect(text) {
            val start = withInfiniteAnimationFrameMillis { it }
            while (true) withInfiniteAnimationFrameMillis { elapsed = (it - start) / 1000f }
        }
        val textWidthDp = with(density) { textWidth.toDp().value }
        val offsetPx = with(density) { Marquee.offset(elapsed, textWidthDp).dp.toPx() }
        val gapPx = with(density) { Marquee.GAP.dp.roundToPx() }
        val fadePx = with(density) { Marquee.EDGE_FADE.dp.toPx() }

        Layout(
            content = {
                Text(text, style = style, color = color, maxLines = 1, softWrap = false)
                Text(text, style = style, color = color, maxLines = 1, softWrap = false)
            },
            modifier = Modifier
                .fillMaxWidth()
                .clipToBounds()
                .graphicsLayer { compositingStrategy = CompositingStrategy.Offscreen }
                .drawWithContent {
                    drawContent()
                    val leading = fadePx / size.width
                    drawRect(
                        Brush.horizontalGradient(
                            0f to if (offsetPx < 0) Color.Transparent else Color.Black,
                            leading to Color.Black,
                            1f - leading to Color.Black,
                            1f to Color.Transparent,
                        ),
                        blendMode = BlendMode.DstIn,
                    )
                },
        ) { measurables, constraints ->
            val loose = Constraints(maxHeight = constraints.maxHeight)
            val placeables = measurables.map { it.measure(loose) }
            val height = placeables.maxOf { it.height }
            layout(constraints.maxWidth, height) {
                val x = offsetPx.roundToInt()
                placeables[0].place(x, 0)
                placeables[1].place(x + placeables[0].width + gapPx, 0)
            }
        }
    }
}

private fun Modifier.semantics(text: String) = clearAndSetSemantics { contentDescription = text }

object Marquee {
    const val GAP = 48f
    const val POINTS_PER_SECOND = 30f
    const val PAUSE = 2.5f
    const val EDGE_FADE = 12f

    /** How far left the text sits [elapsed] seconds in: still for the pause, then scrolling one copy's width plus the gap. */
    fun offset(elapsed: Float, textWidth: Float): Float {
        val distance = textWidth + GAP
        val cycle = PAUSE + distance / POINTS_PER_SECOND
        val elapsedInCycle = elapsed % cycle
        if (elapsedInCycle <= PAUSE) return 0f
        return -(elapsedInCycle - PAUSE) * POINTS_PER_SECOND
    }
}
