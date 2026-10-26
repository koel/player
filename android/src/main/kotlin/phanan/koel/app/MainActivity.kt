package phanan.koel.app

import android.content.Intent
import android.graphics.Color
import android.os.Bundle
import androidx.activity.ComponentActivity
import androidx.activity.SystemBarStyle
import androidx.activity.compose.setContent
import androidx.activity.enableEdgeToEdge
import androidx.media3.session.MediaController
import com.google.common.util.concurrent.ListenableFuture
import phanan.koel.app.audio.PlaybackService
import phanan.koel.app.ui.Root
import phanan.koel.app.ui.theme.KoelTheme

class MainActivity : ComponentActivity() {
    private var sessionConnection: ListenableFuture<MediaController>? = null

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        enableEdgeToEdge(
            statusBarStyle = SystemBarStyle.dark(Color.TRANSPARENT),
            navigationBarStyle = SystemBarStyle.dark(Color.TRANSPARENT),
        )

        val app = (application as KoelApplication).app
        if (savedInstanceState == null) app.pendingLaunch = LaunchAction.Request.of(intent)
        setContent {
            KoelTheme {
                Root(app)
            }
        }
    }

    override fun onNewIntent(intent: Intent) {
        super.onNewIntent(intent)
        LaunchAction.Request.of(intent)?.let { (application as KoelApplication).app.pendingLaunch = it }
    }

    override fun onStart() {
        super.onStart()
        sessionConnection = PlaybackService.connect(this)
    }

    override fun onStop() {
        sessionConnection?.let(MediaController::releaseFuture)
        sessionConnection = null
        super.onStop()
    }
}
