package phanan.koel.app.storage

import android.content.Context
import androidx.core.content.edit
import phanan.koel.shared.storage.KeyValueStore

/** The core's settings and tokens, in the app's private preferences. */
class PreferencesKeyValueStore(context: Context) : KeyValueStore {
    private val preferences = context.getSharedPreferences("koel", Context.MODE_PRIVATE)

    override fun get(key: String): String? = preferences.getString(key, null)

    override fun set(key: String, value: String?) {
        preferences.edit {
            if (value == null) remove(key) else putString(key, value)
        }
    }
}
