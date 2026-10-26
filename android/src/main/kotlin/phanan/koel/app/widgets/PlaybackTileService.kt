package phanan.koel.app.widgets

import android.content.ComponentName
import android.content.Context
import android.graphics.drawable.Icon
import android.service.quicksettings.Tile
import android.service.quicksettings.TileService
import kotlinx.coroutines.MainScope
import kotlinx.coroutines.launch
import phanan.koel.app.KoelApplication
import phanan.koel.app.R
import phanan.koel.app.audio.PlaybackService

/** A Quick Settings tile that plays or pauses, showing what's playing. */
class PlaybackTileService : TileService() {
    private val app get() = (application as KoelApplication).app

    override fun onStartListening() {
        super.onStartListening()
        render()
    }

    override fun onClick() {
        super.onClick()
        MainScope().launch { PlaybackService.control(this@PlaybackTileService) { togglePlayPause() } }
    }

    private fun render() {
        val tile = qsTile ?: return
        val nowPlaying = app.widgetSnapshot.value.nowPlaying
        tile.label = nowPlaying?.title ?: getString(R.string.app_name)
        tile.subtitle = nowPlaying?.subtitle
        tile.icon = Icon.createWithResource(this, if (nowPlaying?.isPlaying == true) R.drawable.ic_pause else R.drawable.ic_play)
        tile.state = when {
            nowPlaying == null -> Tile.STATE_UNAVAILABLE
            nowPlaying.isPlaying -> Tile.STATE_ACTIVE
            else -> Tile.STATE_INACTIVE
        }
        tile.updateTile()
    }

    companion object {
        fun refresh(context: Context) {
            requestListeningState(context, ComponentName(context, PlaybackTileService::class.java))
        }
    }
}
