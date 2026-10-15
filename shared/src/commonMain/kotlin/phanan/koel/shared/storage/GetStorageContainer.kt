package phanan.koel.shared.storage

import kotlinx.io.buffered
import kotlinx.io.files.Path
import kotlinx.io.files.SystemFileSystem
import kotlinx.io.readString
import kotlinx.io.writeString
import kotlinx.serialization.json.JsonElement
import kotlinx.serialization.json.JsonObject
import phanan.koel.shared.json.KoelJson

/**
 * A container written by the Flutter app's get_storage package: one JSON object per container,
 * stored as `<directory>/<name>.gs` with a `<name>.bak` copy that get_storage falls back to when
 * the main file is corrupt. The native app shares the Flutter app's container, so it keeps both.
 */
internal class GetStorageContainer(private val directory: Path, private val name: String) {
    private val mainFile = Path(directory, "$name.gs")
    private val backupFile = Path(directory, "$name.bak")

    operator fun get(key: String): JsonElement? = read()[key]

    operator fun set(key: String, value: JsonElement?) {
        val current = read()
        write(JsonObject(if (value == null) current - key else current + (key to value)))
    }

    fun read(): JsonObject = readFile(mainFile) ?: readFile(backupFile) ?: JsonObject(emptyMap())

    private fun write(content: JsonObject) {
        SystemFileSystem.createDirectories(directory)
        listOf(mainFile, backupFile).forEach { file ->
            SystemFileSystem.sink(file).buffered().use { it.writeString(content.toString()) }
        }
    }

    private fun readFile(file: Path): JsonObject? {
        if (!SystemFileSystem.exists(file)) return null
        return runCatching {
            val text = SystemFileSystem.source(file).buffered().use { it.readString() }
            KoelJson.parseToJsonElement(text) as? JsonObject
        }.getOrNull()
    }
}
