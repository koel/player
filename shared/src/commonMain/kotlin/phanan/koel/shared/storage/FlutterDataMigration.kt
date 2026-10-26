package phanan.koel.shared.storage

import kotlinx.io.files.Path
import kotlinx.serialization.json.JsonPrimitive
import kotlinx.serialization.json.doubleOrNull
import phanan.koel.shared.player.RepeatMode

/**
 * Carries the Flutter app's preferences over, so users who update to the native app (same bundle
 * ID, same Documents directory) stay logged in. Only runs while no host has been stored natively;
 * a token without a host is left over from an earlier install, as the iOS Keychain outlives the app.
 */
internal class FlutterDataMigration(private val preferences: Preferences, documentsPath: String) {
    private val flutterPreferences = GetStorageContainer(Path(documentsPath), "Preferences")

    fun run() {
        if (preferences.host != null) return

        val stored = flutterPreferences.read().mapValues { (_, value) -> value as? JsonPrimitive }
        fun string(key: String) = stored[key]?.takeIf { it.isString }?.content

        preferences.host = string("hostUrl") ?: return
        preferences.apiToken = string("apiToken")
        preferences.audioToken = string("audioToken")
        string("email")?.let { preferences.userEmail = it }
        if (preferences.apiToken != null) preferences.flutterDownloadsEmail = string("email") ?: MISSING_EMAIL
        stored["volume"]?.doubleOrNull?.let { preferences.volume = it }

        // Flutter stored audio_service's enum names: none, one, all, group.
        string("repeatMode")
            ?.let { name -> RepeatMode.entries.firstOrNull { it.name.equals(name, ignoreCase = true) } }
            ?.let { preferences.repeatMode = it }
    }

    private companion object {
        /** Flutter built download paths by string interpolation, which spells a missing email (QR logins) "null". */
        const val MISSING_EMAIL = "null"
    }
}
