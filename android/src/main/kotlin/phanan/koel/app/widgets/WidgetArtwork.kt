package phanan.koel.app.widgets

import android.content.Context
import android.graphics.Bitmap
import android.graphics.BitmapFactory
import android.graphics.Canvas
import android.graphics.Color
import androidx.compose.runtime.Composable
import androidx.compose.runtime.produceState
import androidx.core.graphics.scale
import coil3.SingletonImageLoader
import coil3.request.ImageRequest
import coil3.request.allowHardware
import coil3.toBitmap
import phanan.koel.app.R

/** Widgets can't load images themselves; covers are fetched into bitmaps first. */
object WidgetArtwork {
    private const val PIXEL_SIZE = 256
    private const val BACKDROP_SIZE = 160
    private const val BLUR_GRID = 24
    private const val BLUR_RADIUS = 3
    private const val BLUR_PASSES = 3
    private const val BACKDROP_ZOOM = 1.6f
    private const val BACKDROP_SHADE = 0.45f

    suspend fun load(context: Context, url: String?): Bitmap? {
        if (url.isNullOrBlank()) return null
        val request = ImageRequest.Builder(context)
            .data(url)
            .size(PIXEL_SIZE)
            .allowHardware(false)
            .build()
        return SingletonImageLoader.get(context).execute(request).image?.toBitmap()
    }

    suspend fun preload(context: Context, urls: List<String?>): Map<String?, Bitmap?> =
        urls.distinct().associateWith { load(context, it) }

    /** The cover, blurred and darkened to fill the widget, like the iOS widgets. */
    fun backdrop(context: Context, cover: Bitmap?): Bitmap {
        val source = cover ?: BitmapFactory.decodeResource(context.resources, R.drawable.default_cover)
        val cropSize = (minOf(source.width, source.height) / BACKDROP_ZOOM).toInt().coerceAtLeast(1)
        val center = Bitmap.createBitmap(source, (source.width - cropSize) / 2, (source.height - cropSize) / 2, cropSize, cropSize)
        val blurred = boxBlur(center.scale(BLUR_GRID, BLUR_GRID))
        val backdrop = blurred.scale(BACKDROP_SIZE, BACKDROP_SIZE).copy(Bitmap.Config.ARGB_8888, true)
        Canvas(backdrop).drawColor(Color.argb((BACKDROP_SHADE * 255).toInt(), 0, 0, 0))
        return backdrop
    }

    private fun boxBlur(bitmap: Bitmap): Bitmap {
        val size = bitmap.width
        var pixels = IntArray(size * size).also { bitmap.getPixels(it, 0, size, 0, 0, size, size) }
        repeat(BLUR_PASSES) {
            pixels = blurPass(pixels, size, horizontal = true)
            pixels = blurPass(pixels, size, horizontal = false)
        }
        return Bitmap.createBitmap(pixels, size, size, Bitmap.Config.ARGB_8888)
    }

    private fun blurPass(pixels: IntArray, size: Int, horizontal: Boolean): IntArray = IntArray(pixels.size) { index ->
        val row = index / size
        val column = index % size
        var red = 0
        var green = 0
        var blue = 0
        for (offset in -BLUR_RADIUS..BLUR_RADIUS) {
            val sampleRow = if (horizontal) row else (row + offset).coerceIn(0, size - 1)
            val sampleColumn = if (horizontal) (column + offset).coerceIn(0, size - 1) else column
            val pixel = pixels[sampleRow * size + sampleColumn]
            red += Color.red(pixel)
            green += Color.green(pixel)
            blue += Color.blue(pixel)
        }
        val count = BLUR_RADIUS * 2 + 1
        Color.rgb(red / count, green / count, blue / count)
    }
}

/** Covers for [urls], starting from [preloaded] and fetching any that change. */
@Composable
fun rememberWidgetCovers(context: Context, urls: List<String?>, preloaded: Map<String?, Bitmap?>): Map<String?, Bitmap?> =
    produceState(preloaded, urls) {
        value = urls.distinct().associateWith { url -> preloaded[url] ?: WidgetArtwork.load(context, url) }
    }.value
