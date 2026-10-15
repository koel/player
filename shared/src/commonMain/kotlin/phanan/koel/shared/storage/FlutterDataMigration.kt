package phanan.koel.shared.storage

import kotlinx.io.files.Path
import kotlinx.serialization.json.JsonPrimitive
import kotlinx.serialization.json.doubleOrNull
import phanan.koel.shared.player.RepeatMode

/**
 * Carries the Flutter app's preferences over, so users who update to the native app (same bundle
 * ID, same Documents directory) stay logged in. Only runs while nothing has been stored natively.
 */
internal class FlutterDataMigration(private val preferences: Preferences, documentsPath: String) {
    private val flutterPreferences = GetStorageContainer(Path(documentsPath), "Preferences")

    fun run() {
        if (preferences.host != null || preferences.apiToken != null) return

        val stored = flutterPreferences.read().mapValues { (_, value) -> value as? JsonPrimitive }
        fun string(key: String) = stored[key]?.takeIf { it.isString }?.content

        string("hostUrl")?.let { preferences.host = it }
        string("apiToken")?.let { preferences.apiToken = it }
        string("audioToken")?.let { preferences.audioToken = it }
        string("email")?.let { preferences.userEmail = it }
        stored["volume"]?.doubleOrNull?.let { preferences.volume = it }

        // Flutter stored audio_service's enum names: none, one, all, group.
        string("repeatMode")
            ?.let { name -> RepeatMode.entries.firstOrNull { it.name.equals(name, ignoreCase = true) } }
            ?.let { preferences.repeatMode = it }
    }
}
