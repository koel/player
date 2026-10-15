package phanan.koel.shared.storage

import phanan.koel.shared.player.RepeatMode

/** Implemented natively (UserDefaults/Keychain on iOS); in-memory in tests. */
interface KeyValueStore {
    fun get(key: String): String?
    fun set(key: String, value: String?)
}

class Preferences(private val store: KeyValueStore) {
    var host: String?
        get() = store.get("hostUrl")
        set(value) = store.set("hostUrl", value?.trimEnd('/'))

    val apiBaseUrl: String? get() = host?.let { "$it/api" }

    var apiToken: String?
        get() = store.get("apiToken")
        set(value) = store.set("apiToken", value)

    var audioToken: String?
        get() = store.get("audioToken")
        set(value) = store.set("audioToken", value)

    var userEmail: String?
        get() = store.get("email")
        set(value) = store.set("email", value)

    var repeatMode: RepeatMode
        get() = RepeatMode.entries.firstOrNull { it.name == store.get("repeatMode") } ?: RepeatMode.NONE
        set(value) = store.set("repeatMode", value.name)

    var volume: Double
        get() = store.get("volume")?.toDoubleOrNull() ?: 0.7
        set(value) = store.set("volume", value.toString())
}

class InMemoryKeyValueStore : KeyValueStore {
    private val values = mutableMapOf<String, String>()

    override fun get(key: String): String? = values[key]

    override fun set(key: String, value: String?) {
        if (value == null) values.remove(key) else values[key] = value
    }
}
