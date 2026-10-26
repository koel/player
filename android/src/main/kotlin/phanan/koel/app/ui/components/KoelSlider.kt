package phanan.koel.app.ui.components

import androidx.compose.foundation.Canvas
import androidx.compose.foundation.gestures.detectHorizontalDragGestures
import androidx.compose.foundation.gestures.detectTapGestures
import androidx.compose.foundation.gestures.detectVerticalDragGestures
import androidx.compose.runtime.Composable
import androidx.compose.runtime.getValue
import androidx.compose.runtime.rememberUpdatedState
import androidx.compose.ui.Modifier
import androidx.compose.ui.geometry.Offset
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.graphics.StrokeCap
import androidx.compose.ui.input.pointer.pointerInput
import androidx.compose.ui.semantics.ProgressBarRangeInfo
import androidx.compose.ui.semantics.contentDescription
import androidx.compose.ui.semantics.progressBarRangeInfo
import androidx.compose.ui.semantics.semantics
import androidx.compose.ui.semantics.setProgress
import androidx.compose.ui.unit.IntSize
import androidx.compose.ui.unit.dp
import phanan.koel.app.ui.theme.KoelColors

/**
 * Koel's slider, styled like the Flutter app's: a thin track, filled from [origin] to a white thumb. Tapping or
 * dragging along the track sets the value. A vertical slider has its low end at the bottom.
 */
@Composable
fun KoelSlider(
    value: Float,
    range: ClosedFloatingPointRange<Float>,
    onValueChange: (Float) -> Unit,
    label: String,
    modifier: Modifier = Modifier,
    origin: Float = range.start,
    steps: Int = 0,
    isVertical: Boolean = false,
) {
    val currentOnValueChange by rememberUpdatedState(onValueChange)
    val span = range.endInclusive - range.start

    fun valueAt(position: Offset, size: IntSize): Float {
        val fraction = if (isVertical) 1 - position.y / size.height else position.x / size.width
        return range.start + fraction.coerceIn(0f, 1f) * span
    }

    Canvas(
        modifier
            .semantics {
                contentDescription = label
                progressBarRangeInfo = ProgressBarRangeInfo(value, range, steps)
                setProgress { target ->
                    currentOnValueChange(target.coerceIn(range))
                    true
                }
            }
            .pointerInput(range, isVertical) { detectTapGestures { currentOnValueChange(valueAt(it, size)) } }
            .pointerInput(range, isVertical) {
                if (isVertical) {
                    detectVerticalDragGestures { change, _ ->
                        change.consume()
                        currentOnValueChange(valueAt(change.position, size))
                    }
                } else {
                    detectHorizontalDragGestures { change, _ ->
                        change.consume()
                        currentOnValueChange(valueAt(change.position, size))
                    }
                }
            },
    ) {
        val trackThickness = 3.dp.toPx()
        val thumbRadius = 8.dp.toPx()
        val length = if (isVertical) size.height else size.width

        fun pointAt(fraction: Float, inset: Float = 0f): Offset {
            val along = (fraction.coerceIn(0f, 1f) * length).coerceIn(inset, length - inset)
            return if (isVertical) Offset(size.width / 2, size.height - along) else Offset(along, size.height / 2)
        }

        fun fractionOf(sliderValue: Float) = (sliderValue - range.start) / span

        drawLine(Color.White.copy(alpha = 0.3f), pointAt(0f), pointAt(1f), trackThickness, StrokeCap.Round)
        drawLine(KoelColors.secondaryText, pointAt(fractionOf(origin)), pointAt(fractionOf(value)), trackThickness, StrokeCap.Round)
        drawCircle(Color.White, thumbRadius, pointAt(fractionOf(value), inset = thumbRadius))
    }
}
