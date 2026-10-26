package phanan.koel.app.ui.components

import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.drawBehind
import androidx.compose.ui.geometry.Offset
import androidx.compose.ui.unit.Dp
import androidx.compose.ui.unit.dp
import phanan.koel.app.ui.theme.KoelColors

/** Flutter's hairline between list rows, starting where the row's text does. */
fun Modifier.rowDivider(startInset: Dp) = drawBehind {
    val thickness = 0.5.dp.toPx()
    val y = size.height - thickness / 2
    drawLine(KoelColors.hairline, Offset(startInset.toPx(), y), Offset(size.width, y), thickness)
}

object RowInsets {
    val plain = 16.dp
    val icon = 56.dp
    val trackNumber = 52.dp
    val song = 72.dp
    val artwork = 80.dp
    val largeArtwork = 88.dp
}
