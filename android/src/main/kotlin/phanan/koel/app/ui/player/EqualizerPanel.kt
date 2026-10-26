package phanan.koel.app.ui.player

import androidx.compose.animation.core.AnimationSpec
import androidx.compose.animation.core.animateFloatAsState
import androidx.compose.animation.core.snap
import androidx.compose.animation.core.tween
import androidx.compose.foundation.Canvas
import androidx.compose.foundation.background
import androidx.compose.foundation.gestures.detectTapGestures
import androidx.compose.foundation.gestures.detectVerticalDragGestures
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.Spacer
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.height
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.size
import androidx.compose.foundation.layout.width
import androidx.compose.foundation.layout.wrapContentWidth
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.runtime.State
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.remember
import androidx.compose.runtime.rememberUpdatedState
import androidx.compose.runtime.setValue
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.alpha
import androidx.compose.ui.draw.drawBehind
import androidx.compose.ui.geometry.Offset
import androidx.compose.ui.graphics.BlendMode
import androidx.compose.ui.graphics.Brush
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.graphics.CompositingStrategy
import androidx.compose.ui.graphics.Path
import androidx.compose.ui.graphics.StrokeCap
import androidx.compose.ui.graphics.drawscope.DrawScope
import androidx.compose.ui.graphics.drawscope.Stroke
import androidx.compose.ui.graphics.graphicsLayer
import androidx.compose.ui.input.pointer.pointerInput
import androidx.compose.ui.semantics.ProgressBarRangeInfo
import androidx.compose.ui.semantics.contentDescription
import androidx.compose.ui.semantics.progressBarRangeInfo
import androidx.compose.ui.semantics.semantics
import androidx.compose.ui.semantics.setProgress
import androidx.compose.ui.unit.dp
import phanan.koel.app.ui.theme.KoelColors
import phanan.koel.app.ui.theme.LocalBrandColor
import phanan.koel.shared.models.CurvePoint
import phanan.koel.shared.models.Equalizer
import phanan.koel.shared.models.EqualizerCurve
import phanan.koel.shared.models.EqualizerPreset

/** Where Koel web's equalizer puts a gain: dB from the top of a band's track, and band handles across the panel, in dp. */
object EqualizerGeometry {
    const val TRACK_HEIGHT = 100f
    const val BAND_WIDTH = 24f

    /** 0 at the top of the track (+20 dB), 1 at the bottom (-20 dB). */
    fun fractionFromTop(decibels: Float): Float =
        ((Equalizer.MAX_DECIBELS.toFloat() - decibels) / (2 * Equalizer.MAX_DECIBELS.toFloat())).coerceIn(0f, 1f)

    fun decibelsAt(fractionFromTop: Float): Double =
        PlaybackSettingsFormat.snapped(Equalizer.MAX_DECIBELS.toFloat() * (1 - 2 * fractionFromTop))

    /** The handle centers of bands spread edge to edge across [width], each [BAND_WIDTH] wide. */
    fun handleCenters(gains: List<Float>, width: Float): List<CurvePoint> {
        val spacing = if (gains.size > 1) (width - BAND_WIDTH) / (gains.size - 1) else 0f
        return gains.mapIndexed { band, decibels ->
            CurvePoint((BAND_WIDTH / 2 + band * spacing).toDouble(), (fractionFromTop(decibels) * TRACK_HEIGHT).toDouble())
        }
    }
}

private val TrackHeight = EqualizerGeometry.TRACK_HEIGHT.dp
private val BandWidth = EqualizerGeometry.BAND_WIDTH.dp
private val PanelFill = Color.Black.copy(alpha = 0.2f)
private const val PREAMP = -1

/** Koel web's equalizer panel: the preamp, a dB scale, and the bands with a smooth curve through their handles. */
@Composable
fun EqualizerPanel(equalizer: EqualizerPreset, onChange: (EqualizerPreset) -> Unit) {
    var draggedBand by remember { mutableStateOf<Int?>(null) }
    val preamp by animatedDecibels(equalizer.preamp, isDragged = draggedBand == PREAMP)
    val gains = Equalizer.frequencies.indices.map { band ->
        animatedDecibels(equalizer.gains.getOrElse(band) { 0.0 }, isDragged = draggedBand == band)
    }

    Row(
        Modifier.fillMaxWidth().background(PanelFill, RoundedCornerShape(6.dp)).padding(16.dp),
        horizontalArrangement = Arrangement.spacedBy(4.dp),
    ) {
        EqualizerBandSlider(
            decibels = preamp,
            label = "Preamp",
            description = "Preamp",
            onChange = { onChange(equalizer.withPreamp(it)) },
            onDraggingChange = { isDragging -> draggedBand = PREAMP.takeIf { isDragging } },
        )
        DecibelScale()
        Box(Modifier.weight(1f).drawBehind { drawBaseline() }) {
            Row(Modifier.fillMaxWidth(), horizontalArrangement = Arrangement.SpaceBetween) {
                gains.forEachIndexed { band, gain ->
                    EqualizerBandSlider(
                        decibels = gain.value,
                        label = Equalizer.bandLabel(band),
                        description = Equalizer.bandDescription(band),
                        onChange = { onChange(equalizer.withGain(band, it)) },
                        onDraggingChange = { isDragging -> draggedBand = band.takeIf { isDragging } },
                    )
                }
            }
            EqualizerCurveLine(gains.map { it.value }, Modifier.matchParentSize())
        }
    }
}

@Composable
private fun animatedDecibels(decibels: Double, isDragged: Boolean): State<Float> {
    val spec: AnimationSpec<Float> = if (isDragged) snap() else tween(durationMillis = 300)
    return animateFloatAsState(decibels.toFloat(), spec, label = "decibels")
}

/** One vertical band: a faded hairline track and a white dot, dragged or tapped in 0.1 dB steps. */
@Composable
fun EqualizerBandSlider(
    decibels: Float,
    label: String,
    description: String,
    onChange: (Double) -> Unit,
    onDraggingChange: (Boolean) -> Unit,
) {
    val currentOnChange by rememberUpdatedState(onChange)
    val currentOnDraggingChange by rememberUpdatedState(onDraggingChange)
    val range = -Equalizer.MAX_DECIBELS.toFloat()..Equalizer.MAX_DECIBELS.toFloat()

    Column(horizontalAlignment = Alignment.CenterHorizontally) {
        Canvas(
            Modifier
                .size(BandWidth, TrackHeight)
                .semantics {
                    contentDescription = description
                    progressBarRangeInfo = ProgressBarRangeInfo(decibels, range)
                    setProgress { target ->
                        currentOnChange(PlaybackSettingsFormat.snapped(target))
                        true
                    }
                }
                .pointerInput(Unit) { detectTapGestures { currentOnChange(EqualizerGeometry.decibelsAt(it.y / size.height)) } }
                .pointerInput(Unit) {
                    detectVerticalDragGestures(
                        onDragStart = { currentOnDraggingChange(true) },
                        onDragEnd = { currentOnDraggingChange(false) },
                        onDragCancel = { currentOnDraggingChange(false) },
                    ) { change, _ ->
                        change.consume()
                        currentOnChange(EqualizerGeometry.decibelsAt(change.position.y / size.height))
                    }
                },
        ) {
            val track = Color.White.copy(alpha = 0.15f)
            drawLine(
                Brush.verticalGradient(0f to Color.Transparent, 0.15f to track, 0.85f to track, 1f to Color.Transparent),
                Offset(center.x, 0f),
                Offset(center.x, size.height),
                strokeWidth = 1.dp.toPx(),
            )
            drawCircle(Color.White, 6.5.dp.toPx(), Offset(center.x, EqualizerGeometry.fractionFromTop(decibels) * size.height))
        }
        Spacer(Modifier.height(8.dp))
        Text(label, style = MaterialTheme.typography.labelSmall, color = KoelColors.text, maxLines = 1, softWrap = false, modifier = Modifier.wrapContentWidth(unbounded = true))
    }
}

@Composable
private fun DecibelScale() {
    Column(
        Modifier.size(20.dp, TrackHeight).alpha(0.5f),
        verticalArrangement = Arrangement.SpaceBetween,
        horizontalAlignment = Alignment.CenterHorizontally,
    ) {
        listOf("+20", "0", "-20").forEach {
            Text(it, style = MaterialTheme.typography.labelSmall, color = KoelColors.text, maxLines = 1, softWrap = false, modifier = Modifier.wrapContentWidth(unbounded = true))
        }
    }
}

private fun DrawScope.drawBaseline() {
    val line = Color.White.copy(alpha = 0.1f)
    val y = TrackHeight.toPx() / 2
    drawLine(
        Brush.horizontalGradient(0f to Color.Transparent, 0.05f to line, 0.95f to line, 1f to Color.Transparent),
        Offset(0f, y),
        Offset(size.width, y),
        strokeWidth = 1.dp.toPx(),
    )
}

/** The web's curve through the band handles: highlight to green from top to bottom, fading out past the outer bands. */
@Composable
private fun EqualizerCurveLine(gains: List<Float>, modifier: Modifier) {
    val highlight = LocalBrandColor.current
    Canvas(modifier.graphicsLayer { compositingStrategy = CompositingStrategy.Offscreen }) {
        val handles = EqualizerGeometry.handleCenters(gains, size.width / density)
        val curve = EqualizerCurve.through(handles) ?: return@Canvas

        fun CurvePoint.toOffset() = Offset(x.toFloat().dp.toPx(), y.toFloat().dp.toPx())

        val path = Path().apply {
            val start = curve.start.toOffset()
            moveTo(start.x, start.y)
            curve.segments.forEach { segment ->
                val control1 = segment.control1.toOffset()
                val control2 = segment.control2.toOffset()
                val end = segment.end.toOffset()
                cubicTo(control1.x, control1.y, control2.x, control2.y, end.x, end.y)
            }
        }
        drawPath(
            path,
            Brush.verticalGradient(listOf(highlight, KoelColors.success).map { it.copy(alpha = 0.8f) }, startY = 0f, endY = TrackHeight.toPx()),
            style = Stroke(width = 2.dp.toPx(), cap = StrokeCap.Round),
        )

        val left = curve.start.toOffset().x
        val right = curve.segments.last().end.toOffset().x
        val firstBand = handles.first().toOffset().x
        val lastBand = handles.last().toOffset().x
        fun stop(x: Float) = (x - left) / (right - left)
        drawRect(
            Brush.horizontalGradient(
                0f to Color.Transparent,
                stop(firstBand) to Color.Black,
                stop(lastBand) to Color.Black,
                1f to Color.Transparent,
                startX = left,
                endX = right,
            ),
            blendMode = BlendMode.DstIn,
        )
    }
}
