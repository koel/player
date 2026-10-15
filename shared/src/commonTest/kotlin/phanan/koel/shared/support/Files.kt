package phanan.koel.shared.support

import kotlinx.io.buffered
import kotlinx.io.files.Path
import kotlinx.io.files.SystemFileSystem
import kotlinx.io.files.SystemTemporaryDirectory
import kotlinx.io.readString
import kotlinx.io.writeString
import kotlin.random.Random

fun temporaryDirectory(): Path =
    Path(SystemTemporaryDirectory, "koel-test-${Random.nextLong().toULong()}").also(SystemFileSystem::createDirectories)

fun Path.writeText(text: String) {
    parent?.let(SystemFileSystem::createDirectories)
    SystemFileSystem.sink(this).buffered().use { it.writeString(text) }
}

fun Path.readText(): String = SystemFileSystem.source(this).buffered().use { it.readString() }

fun Path.exists(): Boolean = SystemFileSystem.exists(this)
