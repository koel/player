package phanan.koel.app.widgets

import android.graphics.Bitmap
import androidx.compose.runtime.Composable
import androidx.compose.ui.unit.TextUnit
import androidx.compose.ui.unit.dp
import androidx.glance.GlanceModifier
import androidx.glance.Image
import androidx.glance.ImageProvider
import androidx.glance.appwidget.cornerRadius
import androidx.glance.layout.Box
import androidx.glance.layout.ContentScale
import androidx.glance.layout.fillMaxSize
import androidx.glance.layout.padding
import androidx.glance.text.FontWeight
import androidx.glance.text.TextStyle
import androidx.glance.unit.ColorProvider
import phanan.koel.app.R
import phanan.koel.app.ui.theme.KoelColors

/** The blurred cover filling the widget, with [content] on top, as on iOS. */
@Composable
fun WidgetChrome(backdrop: Bitmap, modifier: GlanceModifier = GlanceModifier, content: @Composable () -> Unit) {
    Box(modifier.fillMaxSize().cornerRadius(24.dp)) {
        Image(ImageProvider(backdrop), contentDescription = null, contentScale = ContentScale.Crop, modifier = GlanceModifier.fillMaxSize())
        Box(GlanceModifier.fillMaxSize().padding(16.dp)) { content() }
    }
}

@Composable
fun WidgetCover(cover: Bitmap?, description: String?, modifier: GlanceModifier, cornerRadius: Int = 8) {
    Image(
        provider = cover?.let { ImageProvider(it) } ?: ImageProvider(R.drawable.default_cover),
        contentDescription = description,
        contentScale = ContentScale.Crop,
        modifier = modifier.cornerRadius(cornerRadius.dp),
    )
}

object WidgetText {
    fun primary(size: TextUnit, weight: FontWeight = FontWeight.Medium) =
        TextStyle(color = ColorProvider(KoelColors.text), fontSize = size, fontWeight = weight)

    fun secondary(size: TextUnit) = TextStyle(color = ColorProvider(KoelColors.secondaryText), fontSize = size)
}
