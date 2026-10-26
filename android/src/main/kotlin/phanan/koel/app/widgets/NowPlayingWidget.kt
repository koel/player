package phanan.koel.app.widgets

import android.content.Context
import android.graphics.Bitmap
import androidx.compose.runtime.Composable
import androidx.compose.runtime.collectAsState
import androidx.compose.runtime.remember
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import androidx.glance.ColorFilter
import androidx.glance.GlanceId
import androidx.glance.GlanceModifier
import androidx.glance.Image
import androidx.glance.ImageProvider
import androidx.glance.LocalContext
import androidx.glance.LocalSize
import androidx.glance.action.Action
import androidx.glance.action.ActionParameters
import androidx.glance.action.clickable
import androidx.glance.appwidget.GlanceAppWidget
import androidx.glance.appwidget.GlanceAppWidgetReceiver
import androidx.glance.appwidget.SizeMode
import androidx.glance.appwidget.action.ActionCallback
import androidx.glance.appwidget.action.actionRunCallback
import androidx.glance.appwidget.action.actionStartActivity
import androidx.glance.appwidget.cornerRadius
import androidx.glance.appwidget.provideContent
import androidx.glance.background
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
import androidx.glance.unit.ColorProvider
import androidx.compose.ui.graphics.Color
import phanan.koel.app.KoelApplication
import phanan.koel.app.LaunchAction
import phanan.koel.app.R
import phanan.koel.app.audio.PlaybackService
import phanan.koel.app.ui.theme.KoelColors

/** What's playing, with play/pause and skip, on the home screen. */
class NowPlayingWidget : GlanceAppWidget() {
    override val sizeMode = SizeMode.Exact

    override suspend fun provideGlance(context: Context, id: GlanceId) {
        val snapshots = (context.applicationContext as KoelApplication).app.widgetSnapshot
        val preloaded = WidgetArtwork.preload(context, listOf(snapshots.value.nowPlaying?.artworkUrl))

        provideContent {
            val nowPlaying = snapshots.collectAsState().value.nowPlaying
            val cover = rememberWidgetCovers(context, listOf(nowPlaying?.artworkUrl), preloaded)[nowPlaying?.artworkUrl]
            val backdrop = remember(cover) { WidgetArtwork.backdrop(context, cover) }
            WidgetChrome(backdrop, GlanceModifier.clickable(actionStartActivity(LaunchAction.OpenNowPlaying.intent(LocalContext.current)))) {
                when {
                    nowPlaying == null -> NothingPlaying()
                    LocalSize.current.width >= MEDIUM_WIDTH -> Medium(nowPlaying, cover)
                    else -> Small(nowPlaying, cover)
                }
            }
        }
    }

    companion object {
        private val MEDIUM_WIDTH = 250.dp
    }
}

@Composable
private fun Small(nowPlaying: WidgetSnapshot.NowPlaying, cover: Bitmap?) {
    Column(GlanceModifier.fillMaxWidth().fillMaxHeight()) {
        Row(GlanceModifier.fillMaxWidth()) {
            WidgetCover(cover, null, GlanceModifier.size(64.dp))
            Spacer(GlanceModifier.defaultWeight())
            PlayPauseButton(nowPlaying.isPlaying)
        }
        Spacer(GlanceModifier.defaultWeight())
        Titles(nowPlaying)
    }
}

@Composable
private fun Medium(nowPlaying: WidgetSnapshot.NowPlaying, cover: Bitmap?) {
    Row(GlanceModifier.fillMaxWidth().fillMaxHeight(), verticalAlignment = Alignment.CenterVertically) {
        WidgetCover(cover, null, GlanceModifier.size(LocalSize.current.height - 32.dp), cornerRadius = 10)
        Spacer(GlanceModifier.width(14.dp))
        Column(GlanceModifier.defaultWeight().fillMaxHeight()) {
            Titles(nowPlaying)
            Spacer(GlanceModifier.defaultWeight())
            Row(verticalAlignment = Alignment.CenterVertically) {
                PlayPauseButton(nowPlaying.isPlaying)
                if (!nowPlaying.isRadio) {
                    Spacer(GlanceModifier.width(20.dp))
                    ControlButton(R.drawable.ic_skip_next, "Next", actionRunCallback<SkipToNextAction>(), hasBackground = false)
                }
            }
        }
    }
}

@Composable
private fun Titles(nowPlaying: WidgetSnapshot.NowPlaying) {
    Column {
        Text(nowPlaying.title, maxLines = 2, style = WidgetText.primary(14.sp, FontWeight.Bold))
        Spacer(GlanceModifier.height(2.dp))
        Text(nowPlaying.subtitle, maxLines = 1, style = WidgetText.secondary(12.sp))
    }
}

@Composable
private fun NothingPlaying() {
    Column(GlanceModifier.fillMaxWidth().fillMaxHeight()) {
        WidgetCover(null, null, GlanceModifier.size(48.dp))
        Spacer(GlanceModifier.defaultWeight())
        Text("Not Playing", style = WidgetText.primary(14.sp, FontWeight.Bold))
        Text("Open Koel to start listening.", style = WidgetText.secondary(12.sp))
    }
}

@Composable
private fun PlayPauseButton(isPlaying: Boolean) {
    ControlButton(
        if (isPlaying) R.drawable.ic_pause else R.drawable.ic_play,
        if (isPlaying) "Pause" else "Play",
        actionRunCallback<TogglePlaybackAction>(),
        hasBackground = true,
    )
}

@Composable
private fun ControlButton(icon: Int, description: String, action: Action, hasBackground: Boolean) {
    val shape = if (hasBackground) GlanceModifier.background(ColorProvider(Color.White.copy(alpha = 0.2f))).cornerRadius(20.dp) else GlanceModifier
    Box(GlanceModifier.size(40.dp).then(shape).clickable(action), contentAlignment = Alignment.Center) {
        Image(
            ImageProvider(icon),
            contentDescription = description,
            colorFilter = ColorFilter.tint(ColorProvider(KoelColors.text)),
            modifier = GlanceModifier.size(22.dp),
        )
    }
}

class TogglePlaybackAction : ActionCallback {
    override suspend fun onAction(context: Context, glanceId: GlanceId, parameters: ActionParameters) {
        PlaybackService.control(context) { togglePlayPause() }
    }
}

class SkipToNextAction : ActionCallback {
    override suspend fun onAction(context: Context, glanceId: GlanceId, parameters: ActionParameters) {
        PlaybackService.control(context) { skipToNext() }
    }
}

class NowPlayingWidgetReceiver : GlanceAppWidgetReceiver() {
    override val glanceAppWidget: GlanceAppWidget = NowPlayingWidget()
}
