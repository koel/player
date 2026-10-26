package phanan.koel.app.ui.collections

import android.graphics.Bitmap
import androidx.compose.animation.animateColorAsState
import androidx.compose.animation.core.FastOutSlowInEasing
import androidx.compose.animation.core.tween
import androidx.compose.foundation.background
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.runtime.Composable
import androidx.compose.runtime.State
import androidx.compose.runtime.compositionLocalOf
import androidx.compose.runtime.getValue
import androidx.compose.runtime.produceState
import androidx.compose.ui.Modifier
import androidx.compose.ui.graphics.Brush
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.platform.LocalContext
import androidx.compose.ui.graphics.luminance
import coil3.SingletonImageLoader
import coil3.request.ImageRequest
import coil3.request.SuccessResult
import coil3.request.allowHardware
import coil3.toBitmap

/** The cover color of the collection on screen, for its Play button. */
val LocalCoverTint = compositionLocalOf<Color?> { null }

/**
 * The main color of a cover, eased in over 0.8 seconds when it changes, like the iOS app.
 * Transparent while there's none.
 */
@Composable
fun rememberCoverColor(url: String?): State<Color> {
    val context = LocalContext.current
    val target by produceState<Color?>(null, url) {
        val remote = url?.takeIf { it.isNotBlank() } ?: return@produceState
        val result = SingletonImageLoader.get(context).execute(
            ImageRequest.Builder(context).data(remote).size(40).allowHardware(false).build(),
        )
        value = (result as? SuccessResult)?.image?.toBitmap()?.let(CoverColor::of)
    }
    return animateColorAsState(target ?: Color.Transparent, tween(800, easing = FastOutSlowInEasing), label = "coverColor")
}

/** A wash of the cover color fading into the dark background from the top. */
@Composable
fun CoverBackground(color: Color) {
    Box(
        Modifier
            .fillMaxSize()
            .background(Brush.verticalGradient(0f to color.copy(alpha = 0.45f * color.alpha), 0.5f to Color.Transparent)),
    )
}

object CoverColor {
    /** Luminance where the tint reads both as text on black and as a fill behind white glyphs. */
    private const val TARGET_LUMINANCE = 0.18f

    /** Nearly gray covers would only produce a gray tint; leave those neutral. */
    private const val MINIMUM_SATURATION = 0.15f

    fun of(bitmap: Bitmap): Color? {
        val pixels = IntArray(bitmap.width * bitmap.height)
        bitmap.getPixels(pixels, 0, bitmap.width, 0, 0, bitmap.width, bitmap.height)
        if (pixels.isEmpty()) return null
        val red = pixels.sumOf { (it shr 16) and 0xFF } / pixels.size
        val green = pixels.sumOf { (it shr 8) and 0xFF } / pixels.size
        val blue = pixels.sumOf { it and 0xFF } / pixels.size
        return legibleTint(red, green, blue)
    }

    fun legibleTint(red: Int, green: Int, blue: Int): Color? {
        val max = maxOf(red, green, blue) / 255f
        val min = minOf(red, green, blue) / 255f
        val saturation = if (max == 0f) 0f else (max - min) / max
        if (saturation < MINIMUM_SATURATION) return null

        val hue = hue(red / 255f, green / 255f, blue / 255f, max, min)
        val boostedSaturation = (saturation * 1.2f).coerceIn(0.45f, 0.9f)
        var lower = 0f
        var upper = 1f
        repeat(16) {
            val middle = (lower + upper) / 2
            if (Color.hsv(hue, boostedSaturation, middle).luminance() < TARGET_LUMINANCE) lower = middle else upper = middle
        }
        return Color.hsv(hue, boostedSaturation, lower)
    }

    private fun hue(red: Float, green: Float, blue: Float, max: Float, min: Float): Float {
        val delta = max - min
        if (delta == 0f) return 0f
        val sector = when (max) {
            red -> ((green - blue) / delta).mod(6f)
            green -> (blue - red) / delta + 2
            else -> (red - green) / delta + 4
        }
        return sector * 60
    }
}
