package phanan.koel.app.ui.theme

import androidx.compose.foundation.BorderStroke
import androidx.compose.foundation.shape.CircleShape
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.TextFieldDefaults
import androidx.compose.material3.Shapes
import androidx.compose.material3.darkColorScheme
import androidx.compose.runtime.Composable
import androidx.compose.runtime.compositionLocalOf
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.unit.dp

/** Koel's colors, from the Flutter app's AppColors. */
object KoelColors {
    val highlight = Color(0xFFF80A95)
    val highlightAccent = Color(0xFFC20C75)
    val red = Color(0xFFBB0054)

    /** Koel web's success green, which the equalizer curve fades into. */
    val success = Color(0xFF56A052)
    val text = Color.White.copy(alpha = 0.9f)
    val secondaryText = Color.White.copy(alpha = 0.7f)
    val faintText = Color.White.copy(alpha = 0.38f)
    val hairline = Color.White.copy(alpha = 0.1f)
    val inputFill = Color.White.copy(alpha = 0.12f)
    val inputFocusedBorder = Color.White.copy(alpha = 0.24f)

    /** The translucent brand purple of Flutter's pills, headers and mini player. */
    val pill = Color(red = 25, green = 0, blue = 64).copy(alpha = 0.5f)
    val menu = Color(0xFF1B0047)

    /** The quiet fill of placeholders, like iOS's tertiary fill. */
    val placeholder = Color.White.copy(alpha = 0.1f)

    /** iOS's swipe colors: Play Next, Play Last, Flutter's green swipe-to-queue, and anything destructive. */
    val playNextSwipe = Color(0xFFFF9500)
    val playLastSwipe = Color(0xFFAF52DE)
    val queueSwipe = Color(0xFF34C759)
    val destructiveSwipe = Color(0xFFFF3B30)
}

/** The current cover's color, or Koel pink when nothing with a usable cover is playing. */
val LocalBrandColor = compositionLocalOf { KoelColors.highlight }

/** Koel's brand backdrop, as on iOS: a 3×3 mesh of purples with one pink pool, over its darkest purple. */
object BrandMesh {
    val base = Color(red = 0.10f, green = 0.00f, blue = 0.22f)
    val colors = listOf(
        base, Color(red = 0.11f, green = 0.00f, blue = 0.27f), Color(red = 0.13f, green = 0.00f, blue = 0.32f),
        KoelColors.highlight, Color(red = 0.31f, green = 0.22f, blue = 0.53f), Color(red = 0.14f, green = 0.06f, blue = 0.27f),
        Color(red = 0.20f, green = 0.13f, blue = 0.36f), Color(red = 0.32f, green = 0.23f, blue = 0.55f), Color(red = 0.31f, green = 0.22f, blue = 0.53f),
    )
}

/** The checkmark on downloaded songs, as in the Flutter app. */
val DownloadedColor = Color(0xFFFAD763)

private val koelColorScheme = darkColorScheme(
    primary = KoelColors.highlight,
    onPrimary = Color.White,
    primaryContainer = KoelColors.highlight,
    onPrimaryContainer = Color.White,
    secondary = KoelColors.secondaryText,
    onSecondary = BrandMesh.base,
    secondaryContainer = BrandMesh.colors[6],
    onSecondaryContainer = Color.White,
    tertiary = KoelColors.highlightAccent,
    background = BrandMesh.base,
    onBackground = KoelColors.text,
    surface = BrandMesh.base,
    onSurface = KoelColors.text,
    surfaceVariant = BrandMesh.colors[5],
    onSurfaceVariant = KoelColors.secondaryText,
    surfaceContainerLowest = BrandMesh.base,
    surfaceContainerLow = BrandMesh.colors[2],
    surfaceContainer = KoelColors.menu,
    surfaceContainerHigh = BrandMesh.colors[5],
    surfaceContainerHighest = BrandMesh.colors[6],
    inverseSurface = Color.White,
    inverseOnSurface = BrandMesh.base,
    outline = KoelColors.inputFocusedBorder,
    outlineVariant = KoelColors.hairline,
    error = KoelColors.red,
    onError = Color.White,
)

/** Flutter's 10-point input and button corners. */
private val koelShapes = Shapes(
    extraSmall = RoundedCornerShape(8.dp),
    small = RoundedCornerShape(10.dp),
    medium = RoundedCornerShape(14.dp),
    large = RoundedCornerShape(20.dp),
    extraLarge = RoundedCornerShape(28.dp),
)

/** Koel's own look, the same everywhere rather than taking colors from the wallpaper. */
@Composable
fun KoelTheme(content: @Composable () -> Unit) {
    MaterialTheme(colorScheme = koelColorScheme, shapes = koelShapes, content = content)
}

object KoelInputs {
    val shape = RoundedCornerShape(10.dp)

    /** Flutter's text fields: a faint white fill that brightens a little while focused, no underline. */
    @Composable
    fun colors() = TextFieldDefaults.colors(
        focusedContainerColor = KoelColors.inputFocusedBorder,
        unfocusedContainerColor = KoelColors.inputFill,
        disabledContainerColor = KoelColors.inputFill,
        focusedIndicatorColor = Color.Transparent,
        unfocusedIndicatorColor = Color.Transparent,
        disabledIndicatorColor = Color.Transparent,
        focusedLabelColor = KoelColors.secondaryText,
        unfocusedLabelColor = KoelColors.secondaryText,
        focusedPlaceholderColor = KoelColors.faintText,
        unfocusedPlaceholderColor = KoelColors.faintText,
        cursorColor = KoelColors.highlight,
    )
}

object KoelPills {
    val shape = CircleShape
    val border = BorderStroke(0.5.dp, KoelColors.hairline)
}

/** iOS's neutral glass: a faint white fill with a hairline edge, for round buttons and frosted cards. */
object KoelGlass {
    val fill = Color.White.copy(alpha = 0.12f)
    val border = BorderStroke(0.5.dp, Color.White.copy(alpha = 0.2f))
}
