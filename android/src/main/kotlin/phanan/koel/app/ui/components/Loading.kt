package phanan.koel.app.ui.components

import androidx.compose.runtime.Composable
import androidx.compose.runtime.LaunchedEffect
import androidx.compose.runtime.SideEffect
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.rememberCoroutineScope
import androidx.compose.runtime.retain.retain
import androidx.compose.runtime.setValue
import kotlinx.coroutines.CancellationException
import kotlinx.coroutines.CoroutineScope
import kotlinx.coroutines.launch

/** Loads a screen when it first shows, and again on pull to refresh or Retry. */
class Loading(internal var scope: CoroutineScope, internal var load: suspend (forceRefresh: Boolean) -> Unit) {
    var hasLoaded by mutableStateOf(false)
        private set
    var isRefreshing by mutableStateOf(false)
        private set
    var hasFailed by mutableStateOf(false)
        private set

    /** Whether to show a spinner instead of an empty or failed state. */
    val isBusy: Boolean get() = !hasLoaded || isRefreshing

    /** Whether pull to refresh shows its spinner; the first load shows its own placeholder instead. */
    val isPullRefreshing: Boolean get() = isRefreshing && hasLoaded

    suspend fun run(forceRefresh: Boolean = false) = run { load(forceRefresh) }

    /** Runs [work] with the same spinner and failure state as a load, like re-sorting a list the server sorts. */
    suspend fun run(work: suspend () -> Unit) {
        isRefreshing = true
        try {
            work()
            hasFailed = false
            hasLoaded = true
        } catch (cancellation: CancellationException) {
            throw cancellation
        } catch (error: Exception) {
            hasFailed = true
            hasLoaded = true
        } finally {
            isRefreshing = false
        }
    }

    fun refresh() {
        scope.launch { run(forceRefresh = true) }
    }

    fun retry() {
        scope.launch { run() }
    }
}

/**
 * Starts [load] the first time the screen appears, and again whenever [key] changes. Coming back
 * to the screen or recreating the activity doesn't load it again.
 */
@Composable
fun rememberLoading(key: Any = Unit, load: suspend (forceRefresh: Boolean) -> Unit): Loading {
    val scope = rememberCoroutineScope()
    val loading = retain(key) { Loading(scope, load) }
    SideEffect {
        loading.scope = scope
        loading.load = load
    }
    LaunchedEffect(loading) {
        if (!loading.hasLoaded) loading.run()
    }
    return loading
}
