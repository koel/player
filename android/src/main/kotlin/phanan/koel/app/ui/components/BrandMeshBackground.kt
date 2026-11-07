package phanan.koel.app.ui.components

import android.provider.Settings
import androidx.compose.foundation.Canvas
import androidx.compose.foundation.background
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.fillMaxHeight
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.runtime.Composable
import androidx.compose.runtime.getValue
import androidx.compose.runtime.produceState
import androidx.compose.runtime.remember
import androidx.compose.ui.Modifier
import androidx.compose.ui.geometry.Offset
import androidx.compose.ui.graphics.BlendMode
import androidx.compose.ui.graphics.Brush
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.graphics.CompositingStrategy
import androidx.compose.ui.graphics.drawscope.DrawScope
import androidx.compose.ui.graphics.graphicsLayer
import androidx.compose.ui.platform.LocalContext
import androidx.compose.ui.draw.drawWithContent
import androidx.compose.animation.core.withInfiniteAnimationFrameMillis
import androidx.lifecycle.Lifecycle
import androidx.lifecycle.compose.LocalLifecycleOwner
import androidx.lifecycle.repeatOnLifecycle
import kotlinx.coroutines.delay
import phanan.koel.app.ui.theme.BrandMesh
import kotlin.math.PI
import kotlin.math.max
import kotlin.math.sin
import kotlin.time.Duration.Companion.milliseconds

/** Koel's purple-and-pink brand backdrop, slowly drifting, as on iOS. */
@Composable
fun BrandMeshBackground(modifier: Modifier = Modifier) {
    val seconds by rememberDriftSeconds()
    Canvas(modifier.fillMaxSize().background(BrandMesh.base)) { drawMesh(seconds) }
}

/**
 * The brand mesh across the top half of a screen, fading into the brand's darkest color below.
 * It moves up by [scrolledDistance] so it scrolls away with the content.
 */
@Composable
fun BrandMeshHeaderBackground(scrolledDistance: () -> Float, modifier: Modifier = Modifier) {
    val seconds by rememberDriftSeconds()
    Box(modifier.fillMaxSize().background(BrandMesh.base)) {
        Canvas(
            Modifier
                .fillMaxWidth()
                .fillMaxHeight(0.5f)
                .graphicsLayer {
                    translationY = -max(scrolledDistance(), 0f)
                    compositingStrategy = CompositingStrategy.Offscreen
                }
                .drawWithContent {
                    drawContent()
                    drawRect(Brush.verticalGradient(0f to Color.Black, 0.5f to Color.Black, 1f to Color.Transparent), blendMode = BlendMode.DstIn)
                },
        ) { drawMesh(seconds) }
    }
}

/** The drift is slow, so ten frames a second look smooth and spare the battery. */
private val FrameInterval = 100.milliseconds

/**
 * Seconds the backdrop has drifted, counted only while the app is the active one, and frozen
 * at zero when the system turns animations off.
 */
@Composable
private fun rememberDriftSeconds() = run {
    val context = LocalContext.current
    val lifecycle = LocalLifecycleOwner.current.lifecycle
    val isMotionReduced = remember { Settings.Global.getFloat(context.contentResolver, Settings.Global.ANIMATOR_DURATION_SCALE, 1f) == 0f }
    produceState(0.0, lifecycle) {
        if (isMotionReduced) return@produceState
        lifecycle.repeatOnLifecycle(Lifecycle.State.RESUMED) {
            val driftedBefore = value
            val start = withInfiniteAnimationFrameMillis { it }
            while (true) {
                withInfiniteAnimationFrameMillis { value = driftedBefore + (it - start) / 1000.0 }
                delay(FrameInterval)
            }
        }
    }
}

/**
 * A 3×3 mesh drawn as soft color pools. Corners stay pinned; edge midpoints slide along their
 * edge and the center wanders, each on its own slow period so the pattern never visibly repeats.
 */
private fun DrawScope.drawMesh(seconds: Double) {
    fun drift(period: Double, amplitude: Double, phase: Double = 0.0) = (sin(seconds * 2 * PI / period + phase) * amplitude).toFloat()

    val points = listOf(
        0f to 0f, 0.5f + drift(11.0, 0.3) to 0f, 1f to 0f,
        0f to 0.5f + drift(13.0, 0.3, 1.0), 0.5f + drift(10.0, 0.28, 2.0) to 0.5f + drift(14.0, 0.28), 1f to 0.5f + drift(12.0, 0.3, 3.0),
        0f to 1f, 0.5f + drift(16.0, 0.3, 4.0) to 1f, 1f to 1f,
    )
    val radius = max(size.width, size.height) * 0.6f
    points.zip(BrandMesh.colors).forEach { (point, color) ->
        val center = Offset(point.first * size.width, point.second * size.height)
        drawCircle(Brush.radialGradient(listOf(color, color.copy(alpha = 0f)), center, radius), radius, center)
    }
}
