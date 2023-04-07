package phanan.koel.app

import androidx.annotation.NonNull
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

import com.ryanheise.audioservice.AudioServiceActivity;


class MainActivity: AudioServiceActivity() {
    private val CHANNEL = "dev.koel.app"

    override fun configureFlutterEngine(@NonNull flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL).apply {
            setMethodCallHandler { method, result ->
                if (method.method == "minimize") {
                    moveTaskToBack(true)
                }
            }
        }
    }
}