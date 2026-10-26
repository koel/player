package phanan.koel.app.widgets

import android.content.Context
import android.graphics.Bitmap
import androidx.compose.runtime.Composable
import androidx.compose.runtime.collectAsState
import androidx.compose.runtime.remember
import androidx.compose.ui.unit.Dp
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import androidx.glance.GlanceId
import androidx.glance.GlanceModifier
import androidx.glance.LocalContext
import androidx.glance.LocalSize
import androidx.glance.action.clickable
import androidx.glance.appwidget.GlanceAppWidget
import androidx.glance.appwidget.GlanceAppWidgetReceiver
import androidx.glance.appwidget.SizeMode
import androidx.glance.appwidget.action.actionStartActivity
import androidx.glance.appwidget.provideContent
import androidx.glance.layout.Alignment
import androidx.glance.layout.Box
import androidx.glance.layout.Column
import androidx.glance.layout.Row
import androidx.glance.layout.Spacer
import androidx.glance.layout.fillMaxHeight
import androidx.glance.layout.fillMaxWidth
import androidx.glance.layout.height
import androidx.glance.layout.size
import androidx.glance.layout.width
import androidx.glance.text.FontWeight
import androidx.glance.text.Text
import phanan.koel.app.KoelApplication
import phanan.koel.app.LaunchAction

/** The songs played last; tapping one plays it right from the home screen. */
class RecentlyPlayedWidget : GlanceAppWidget() {
    override val sizeMode = SizeMode.Exact

    override suspend fun provideGlance(context: Context, id: GlanceId) {
        val snapshots = (context.applicationContext as KoelApplication).app.widgetSnapshot
        val preloaded = WidgetArtwork.preload(context, snapshots.value.recentlyPlayed.map { it.artworkUrl })

        provideContent {
            val recent = snapshots.collectAsState().value.recentlyPlayed
            val covers = rememberWidgetCovers(context, recent.map { it.artworkUrl }, preloaded)
            val firstCover = recent.firstOrNull()?.let { covers[it.artworkUrl] }
            val backdrop = remember(firstCover) { WidgetArtwork.backdrop(context, firstCover) }
            WidgetChrome(backdrop) { RecentlyPlayedContent(recent, covers) }
        }
    }
}

private const val COLUMN_COUNT = 4
private const val MAX_ROWS = 3
private val Spacing = 10.dp
private val Padding = 16.dp
private val HeaderHeight = 28.dp

@Composable
private fun RecentlyPlayedContent(recent: List<WidgetSnapshot.RecentItem>, covers: Map<String?, Bitmap?>) {
    val size = LocalSize.current
    val showsSubtitles = size.height >= 250.dp
    val labelHeight = if (showsSubtitles) 33.dp else 19.dp
    val cellWidth = (size.width - Padding * 2 - Spacing * (COLUMN_COUNT - 1)) / COLUMN_COUNT
    val gridHeight = size.height - Padding * 2 - HeaderHeight
    val rowCount = ((gridHeight + Spacing) / (cellWidth + labelHeight + Spacing)).toInt().coerceIn(1, MAX_ROWS)
    val rowHeight = (gridHeight - Spacing * (rowCount - 1)) / rowCount
    val coverSize = minOf(cellWidth, rowHeight - labelHeight)

    Column(GlanceModifier.fillMaxWidth().fillMaxHeight()) {
        Text("Recently Played", style = WidgetText.primary(14.sp, FontWeight.Bold), modifier = GlanceModifier.height(HeaderHeight))
        if (recent.isEmpty()) {
            Box(GlanceModifier.fillMaxWidth().defaultWeight(), contentAlignment = Alignment.Center) {
                Text("Songs you play show up here.", style = WidgetText.secondary(12.sp))
            }
            return@Column
        }
        recent.chunked(COLUMN_COUNT).take(rowCount).forEachIndexed { rowIndex, row ->
            if (rowIndex > 0) Spacer(GlanceModifier.height(Spacing))
            Row(GlanceModifier.fillMaxWidth()) {
                row.forEachIndexed { index, item ->
                    if (index > 0) Spacer(GlanceModifier.width(Spacing))
                    Cell(item, covers[item.artworkUrl], cellWidth, coverSize, showsSubtitles)
                }
            }
        }
    }
}

@Composable
private fun Cell(item: WidgetSnapshot.RecentItem, cover: Bitmap?, width: Dp, coverSize: Dp, showsSubtitle: Boolean) {
    Column(
        GlanceModifier
            .width(width)
            .clickable(actionStartActivity(LaunchAction.PlayRecentItem.intent(LocalContext.current, item.id))),
    ) {
        WidgetCover(cover, item.title, GlanceModifier.size(coverSize), cornerRadius = 6)
        Spacer(GlanceModifier.height(3.dp))
        Text(item.title, maxLines = 1, style = WidgetText.primary(11.sp))
        if (showsSubtitle) Text(item.subtitle, maxLines = 1, style = WidgetText.secondary(11.sp))
    }
}

class RecentlyPlayedWidgetReceiver : GlanceAppWidgetReceiver() {
    override val glanceAppWidget: GlanceAppWidget = RecentlyPlayedWidget()
}
