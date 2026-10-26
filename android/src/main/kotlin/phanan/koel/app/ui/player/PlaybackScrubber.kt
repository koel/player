package phanan.koel.app.ui.player

import androidx.compose.animation.core.Animatable
import androidx.compose.animation.core.FastOutSlowInEasing
import androidx.compose.animation.core.animateDpAsState
import androidx.compose.animation.core.tween
import androidx.compose.animation.core.withInfiniteAnimationFrameMillis
import androidx.compose.foundation.Canvas
import androidx.compose.foundation.gestures.awaitEachGesture
import androidx.compose.foundation.gestures.awaitFirstDown
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.height
import androidx.compose.runtime.Composable
import androidx.compose.runtime.LaunchedEffect
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableLongStateOf
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.remember
import androidx.compose.runtime.rememberUpdatedState
import androidx.compose.runtime.setValue
import androidx.compose.ui.Modifier
import androidx.compose.ui.geometry.CornerRadius
import androidx.compose.ui.geometry.Offset
import androidx.compose.ui.geometry.Size
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.graphics.drawscope.DrawScope
import androidx.compose.ui.graphics.drawscope.clipRect
import androidx.compose.ui.input.pointer.pointerInput
import androidx.compose.ui.input.pointer.positionChange
import androidx.compose.ui.semantics.contentDescription
import androidx.compose.ui.semantics.semantics
import androidx.compose.ui.semantics.stateDescription
import androidx.compose.ui.unit.dp
import kotlin.math.PI
import kotlin.math.abs
import kotlin.math.cos
import kotlin.math.max
import kotlin.math.min
import kotlin.math.pow

/**
 * A knobless progress control, as on iOS: a thin bar, or the song's waveform when there is one.
 * A tap jumps to the touched spot; dragging moves the position by the distance moved.
 */
@Composable
fun PlaybackScrubber(
    position: Double,
    length: Double,
    waveform: List<Double>,
    isPlaying: Boolean,
    accent: Color,
    onScrub: (Double) -> Unit,
    onCommit: (Double) -> Unit,
    modifier: Modifier = Modifier,
) {
    val currentPosition by rememberUpdatedState(position)
    val currentOnScrub by rememberUpdatedState(onScrub)
    val currentOnCommit by rememberUpdatedState(onCommit)
    var dragStart by remember { mutableStateOf<Double?>(null) }
    val isDragging = dragStart != null
    val isAdvancing = isPlaying && !isDragging
    var positionUpdatedAt by remember { mutableLongStateOf(System.currentTimeMillis()) }
    var now by remember { mutableLongStateOf(System.currentTimeMillis()) }
    val growth = remember { Animatable(0f) }
    val barHeight by animateDpAsState(if (isDragging) 12.dp else 7.dp, tween(250), label = "barHeight")

    LaunchedEffect(position, isAdvancing) { positionUpdatedAt = System.currentTimeMillis() }
    LaunchedEffect(isAdvancing) {
        while (isAdvancing) withInfiniteAnimationFrameMillis { now = System.currentTimeMillis() }
    }
    LaunchedEffect(waveform) {
        growth.snapTo(0f)
        if (waveform.isNotEmpty()) growth.animateTo(1f, tween(900, easing = FastOutSlowInEasing))
    }

    val elapsed = if (isAdvancing) max(now - positionUpdatedAt, 0L) / 1000.0 else 0.0
    val fraction = if (length > 0) ((position + elapsed) / length).coerceIn(0.0, 1.0).toFloat() else 0f

    Canvas(
        modifier
            .fillMaxWidth()
            .height(44.dp)
            .semantics {
                contentDescription = "Position"
                stateDescription = position.playbackTime
            }
            .pointerInput(length) {
                awaitEachGesture {
                    val down = awaitFirstDown()
                    val start = currentPosition
                    dragStart = start
                    var moved = 0f
                    while (true) {
                        val event = awaitPointerEvent()
                        val change = event.changes.firstOrNull { it.id == down.id } ?: break
                        if (!change.pressed) break
                        moved += change.positionChange().x
                        change.consume()
                        currentOnScrub(Scrubbing.target(start, moved, size.width.toFloat(), length))
                    }
                    dragStart = null
                    val target = if (abs(moved) < 4.dp.toPx() && size.width > 0) {
                        (down.position.x / size.width).coerceIn(0f, 1f) * length
                    } else {
                        Scrubbing.target(start, moved, size.width.toFloat(), length)
                    }
                    currentOnCommit(target)
                }
            },
    ) {
        if (waveform.isEmpty()) {
            drawBar(fraction, barHeight.toPx(), isDragging)
        } else {
            drawWaveform(waveform, fraction, isDragging, growth.value, accent)
        }
    }
}

private fun DrawScope.drawBar(fraction: Float, height: Float, isHighlighted: Boolean) {
    val top = (size.height - height) / 2
    val radius = CornerRadius(height / 2)
    drawRoundRect(Color.White.copy(alpha = 0.2f), Offset(0f, top), Size(size.width, height), radius)
    clipRect(right = size.width * fraction) {
        drawRoundRect(Color.White.copy(alpha = if (isHighlighted) 1f else 0.75f), Offset(0f, top), Size(size.width, height), radius)
    }
}

/** Rounded vertical bars mirrored around the middle, bright up to the played fraction. */
private fun DrawScope.drawWaveform(levels: List<Double>, fraction: Float, isHighlighted: Boolean, growth: Float, accent: Color) {
    val barWidth = 1.5.dp.toPx()
    val gap = 2.dp.toPx()
    val minimumBarHeight = 1.5.dp.toPx()
    val glowRadius = Waveform.GLOW_RADIUS.dp.toPx()
    val count = max(((size.width + gap) / (barWidth + gap)).toInt(), 1)
    val heights = Waveform.normalized(Waveform.resampled(levels, count))
    val step = if (count > 1) (size.width - barWidth) / (count - 1) else 0f
    val playedX = size.width * fraction
    val restingHeight = size.height / (1 + Waveform.GLOW_GROWTH)

    heights.forEachIndexed { index, level ->
        val x = index * step
        val glow = Waveform.glow((x + barWidth / 2 - playedX) / glowRadius)
        val rise = Waveform.rise(index, heights.size, growth)
        val barHeight = max(restingHeight * level.toFloat() * rise * (1 + Waveform.GLOW_GROWTH * glow), minimumBarHeight)
        val topLeft = Offset(x, (size.height - barHeight) / 2)
        val barSize = Size(barWidth, barHeight)
        val radius = CornerRadius(barWidth / 2)
        drawRoundRect(Color.White.copy(alpha = 0.3f + 0.5f * glow), topLeft, barSize, radius)
        clipRect(right = playedX) {
            drawRoundRect(Color.White.copy(alpha = if (isHighlighted) 1f else 0.85f + 0.15f * glow), topLeft, barSize, radius)
        }
    }
    drawRect(accent, Offset(playedX - 0.5.dp.toPx(), 0f), Size(1.dp.toPx(), size.height))
}

object Scrubbing {
    /** Where a drag of [moved] pixels from [start] lands, as a position in the song. */
    fun target(start: Double, moved: Float, width: Float, length: Double): Double {
        if (width <= 0) return start
        return (start + moved / width * length).coerceIn(0.0, length)
    }
}

object Waveform {
    /** How far from the playhead bars still swell, in dp. */
    const val GLOW_RADIUS = 22f
    const val GLOW_GROWTH = 0.6f

    /** How much of the rise is spent waiting for the bars to the left to start first. */
    private const val RISE_STAGGER = 0.5f

    /** From 0 to 1 as bar [index] rises from flat, left to right, while [growth] goes from 0 to 1. */
    fun rise(index: Int, count: Int, growth: Float): Float {
        val delay = RISE_STAGGER * index / max(count - 1, 1)
        return ((growth - delay) / (1 - RISE_STAGGER)).coerceIn(0f, 1f)
    }

    /** 1 right at the playhead, easing to 0 a glow radius behind it; bars ahead of it stay plain. */
    fun glow(distanceInRadii: Float): Float {
        if (distanceInRadii > 0) return 0f
        val normalized = min(-distanceInRadii, 1f)
        return 0.5f + 0.5f * cos(normalized * PI.toFloat())
    }

    /** Each bar takes the loudest slice it covers, so short peaks stay visible. */
    fun resampled(levels: List<Double>, count: Int): List<Double> {
        if (levels.isEmpty()) return List(count) { 0.0 }
        return List(count) { bar ->
            val start = bar * levels.size / count
            val end = max((bar + 1) * levels.size / count, start + 1)
            levels.subList(start, min(end, levels.size)).max()
        }
    }

    /**
     * Stretches the range between the quiet floor and the loudest bar, since mastered songs sit
     * in a narrow band and would otherwise draw as a flat block.
     */
    fun normalized(levels: List<Double>): List<Double> {
        val sorted = levels.sorted()
        val peak = sorted.lastOrNull()?.takeIf { it > 0 } ?: return levels
        val floor = sorted[sorted.size / 10] * 0.8
        val range = max(peak - floor, Double.MIN_VALUE)
        return levels.map { ((it - floor) / range).coerceIn(0.0, 1.0).pow(1.6) }
    }
}
