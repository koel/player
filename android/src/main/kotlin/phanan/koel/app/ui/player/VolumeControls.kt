package phanan.koel.app.ui.player

import android.content.Context
import android.content.Intent
import android.database.ContentObserver
import android.media.AudioManager
import android.media.MediaRouter2
import android.os.Build
import android.os.Handler
import android.os.Looper
import android.provider.Settings
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.height
import androidx.compose.foundation.layout.size
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.automirrored.filled.VolumeDown
import androidx.compose.material.icons.automirrored.filled.VolumeUp
import androidx.compose.material3.Icon
import androidx.compose.runtime.Composable
import androidx.compose.runtime.DisposableEffect
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableIntStateOf
import androidx.compose.runtime.remember
import androidx.compose.runtime.setValue
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.platform.LocalContext
import androidx.compose.ui.unit.dp
import phanan.koel.app.ui.components.KoelSlider
import phanan.koel.app.ui.theme.KoelColors
import kotlin.math.roundToInt

/**
 * The system media volume, like iOS's volume slider: it follows the hardware buttons and
 * Bluetooth devices, and dragging it sets the volume. Styled like the Flutter app's sliders.
 */
@Composable
fun SystemVolumeSlider(modifier: Modifier = Modifier) {
    val context = LocalContext.current
    val audio = remember { context.getSystemService(Context.AUDIO_SERVICE) as AudioManager }
    val maxVolume = remember { audio.getStreamMaxVolume(AudioManager.STREAM_MUSIC).coerceAtLeast(1) }
    var volume by remember { mutableIntStateOf(audio.getStreamVolume(AudioManager.STREAM_MUSIC)) }

    DisposableEffect(audio) {
        val observer = object : ContentObserver(Handler(Looper.getMainLooper())) {
            override fun onChange(selfChange: Boolean) {
                volume = audio.getStreamVolume(AudioManager.STREAM_MUSIC)
            }
        }
        context.contentResolver.registerContentObserver(Settings.System.CONTENT_URI, true, observer)
        onDispose { context.contentResolver.unregisterContentObserver(observer) }
    }

    fun setVolume(fraction: Float) {
        val level = VolumeLevels.level(fraction, maxVolume)
        volume = level
        audio.setStreamVolume(AudioManager.STREAM_MUSIC, level, 0)
    }

    Row(
        modifier.fillMaxWidth().height(34.dp),
        horizontalArrangement = Arrangement.spacedBy(10.dp),
        verticalAlignment = Alignment.CenterVertically,
    ) {
        Icon(Icons.AutoMirrored.Filled.VolumeDown, contentDescription = null, tint = KoelColors.secondaryText, modifier = Modifier.size(18.dp))
        KoelSlider(
            value = volume.toFloat(),
            range = 0f..maxVolume.toFloat(),
            onValueChange = { setVolume(it / maxVolume) },
            label = "Volume",
            steps = maxVolume - 1,
            modifier = Modifier.weight(1f).height(34.dp),
        )
        Icon(Icons.AutoMirrored.Filled.VolumeUp, contentDescription = null, tint = KoelColors.secondaryText, modifier = Modifier.size(18.dp))
    }
}

object VolumeLevels {
    /** The nearest volume step to a spot along the slider. */
    fun level(fraction: Float, maxVolume: Int): Int = (fraction.coerceIn(0f, 1f) * maxVolume).roundToInt()
}

/**
 * Opens Android's output switcher, where the user picks a speaker, headphones or a Cast device,
 * like AirPlay's picker on iOS.
 */
fun showOutputSwitcher(context: Context) {
    val packageName = context.packageName
    val shown = runCatching {
        when {
            Build.VERSION.SDK_INT >= Build.VERSION_CODES.UPSIDE_DOWN_CAKE -> MediaRouter2.getInstance(context).showSystemOutputSwitcher()
            Build.VERSION.SDK_INT >= Build.VERSION_CODES.S -> {
                context.sendBroadcast(
                    Intent("com.android.systemui.action.LAUNCH_MEDIA_OUTPUT_DIALOG")
                        .setPackage("com.android.systemui")
                        .putExtra("package_name", packageName),
                )
                true
            }
            Build.VERSION.SDK_INT >= Build.VERSION_CODES.R -> {
                context.startActivity(
                    Intent("android.settings.MEDIA_OUTPUT")
                        .putExtra("com.android.settings.panel.extra.PACKAGE_NAME", packageName)
                        .addFlags(Intent.FLAG_ACTIVITY_NEW_TASK),
                )
                true
            }
            else -> false
        }
    }.getOrDefault(false)

    if (!shown) {
        runCatching { context.startActivity(Intent(Settings.ACTION_BLUETOOTH_SETTINGS).addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)) }
    }
}
