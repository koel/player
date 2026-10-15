package phanan.koel.shared

import io.ktor.client.engine.darwin.Darwin
import phanan.koel.shared.player.AudioEngine
import phanan.koel.shared.storage.KeyValueStore

fun createKoelCore(keyValueStore: KeyValueStore, documentsPath: String, audioEngine: AudioEngine): KoelCore =
    KoelCore(keyValueStore, documentsPath, audioEngine, Darwin.create())
