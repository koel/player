package phanan.koel.shared

import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.withContext

/**
 * SKIE starts suspend functions called from Swift on `Dispatchers.Default`, but the core's state
 * is confined to the main thread (the native callbacks it calls require it too). Every public
 * suspend function hops here first.
 */
internal suspend fun <T> onMain(block: suspend () -> T): T =
    withContext(Dispatchers.Main.immediate) { block() }
