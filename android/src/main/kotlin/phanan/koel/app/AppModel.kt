package phanan.koel.app

import android.content.Context
import android.net.ConnectivityManager
import android.net.Network
import android.net.NetworkCapabilities
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.setValue
import androidx.glance.appwidget.updateAll
import androidx.lifecycle.Lifecycle
import androidx.lifecycle.ProcessLifecycleOwner
import kotlinx.coroutines.CancellationException
import kotlinx.coroutines.Deferred
import kotlinx.coroutines.Job
import kotlinx.coroutines.MainScope
import kotlinx.coroutines.flow.MutableStateFlow
import kotlinx.coroutines.flow.SharingStarted
import kotlinx.coroutines.flow.StateFlow
import kotlinx.coroutines.flow.asStateFlow
import kotlinx.coroutines.flow.combine
import kotlinx.coroutines.flow.stateIn
import kotlinx.coroutines.flow.distinctUntilChanged
import kotlinx.coroutines.flow.distinctUntilChangedBy
import kotlinx.coroutines.flow.drop
import kotlinx.coroutines.flow.map
import kotlinx.coroutines.async
import kotlinx.coroutines.launch
import phanan.koel.app.audio.ExoPlayerEngine
import phanan.koel.app.storage.PreferencesKeyValueStore
import phanan.koel.app.ui.main.Navigator
import phanan.koel.app.widgets.NowPlayingWidget
import phanan.koel.app.widgets.PlaybackTileService
import phanan.koel.app.widgets.RecentlyPlayedWidget
import phanan.koel.app.widgets.WidgetSnapshot
import phanan.koel.app.ui.components.SortSetting
import phanan.koel.shared.KoelCore
import phanan.koel.shared.createKoelCore
import phanan.koel.shared.models.Playable
import phanan.koel.shared.models.User

/** App-wide state: which stage of launch the app is in, plus the core and the player. */
class AppModel(private val context: Context) {
    enum class Phase { Launching, NoConnection, Login, Loading, Main, Offline }

    val engine = ExoPlayerEngine(context)

    /** Shares the Flutter app's documents directory, so its login and downloads carry over. */
    val core: KoelCore = createKoelCore(
        keyValueStore = PreferencesKeyValueStore(context),
        documentsPath = context.getDir("flutter", Context.MODE_PRIVATE).path,
        audioEngine = engine,
    )

    val navigator = Navigator(PreferencesKeyValueStore(context))

    init {
        SortSetting.store = PreferencesKeyValueStore(context)
    }
    val messages = Messages()
    val actions = PlayableActions(this)

    var sheet by mutableStateOf<AppSheet?>(null)
    var isNowPlayingShown by mutableStateOf(false)

    /** Waits here until the main screen is up to carry it out. */
    var pendingLaunch by mutableStateOf<LaunchAction.Request?>(null)

    private val widgetStore = PreferencesKeyValueStore(context)
    private val widgetSnapshotState = MutableStateFlow(WidgetSnapshot.read(widgetStore).stopped())

    /** What the widgets show, saved so they keep showing it after Android closes the app. */
    val widgetSnapshot: StateFlow<WidgetSnapshot> = widgetSnapshotState.asStateFlow()

    private val phaseState = MutableStateFlow(Phase.Launching)
    val phase: StateFlow<Phase> = phaseState.asStateFlow()

    val isOffline: Boolean get() = phase.value == Phase.Offline

    /** Without a connection, only downloaded songs can play. */
    val playsDownloadsOnly: Boolean get() = phase.value == Phase.Offline || phase.value == Phase.NoConnection

    private val isOnlineState = MutableStateFlow(hasConnection())

    /** Whether the device has an internet connection, kept up to date as networks come and go. */
    val isOnline: StateFlow<Boolean> = isOnlineState.asStateFlow()

    /** Logged in, with the library loaded (or browsing downloads offline). */
    val isReady: Boolean get() = phase.value == Phase.Main || phase.value == Phase.Offline

    private val scope = MainScope()

    /** True while browsing downloads offline after the connection has come back, so the app can offer to refresh. */
    val connectionRestored: StateFlow<Boolean> = combine(phaseState, isOnlineState) { phase, isOnline ->
        phase == Phase.Offline && isOnline
    }.stateIn(scope, SharingStarted.Eagerly, false)

    init {
        watchConnectivity()
        scope.launch {
            isOnlineState.collect { isOnline ->
                if (isOnline && reconnectsOnceOnline(phase.value, isScreenShown)) reconnectWhenOnline()
            }
        }
        scope.launch {
            core.player.state
                .distinctUntilChangedBy { listOf(it.current?.id, it.radioStation?.id, it.radioStreamTitle) }
                .collect { state ->
                    val station = state.radioStation
                    when {
                        station != null -> engine.describe(state.radioStreamTitle ?: station.name, station.name, station.logo)
                        state.current != null -> state.current?.let { engine.describe(it.title, it.subtitle, it.artworkUrl) }
                    }
                }
        }
        scope.launch { keepWidgetsCurrent() }
        scope.launch { phase.collect { core.isOffline = playsDownloadsOnly } }
        scope.launch {
            core.player.state
                .map { it.current != null }
                .distinctUntilChanged()
                .drop(1)
                .collect { hasRecent -> AppShortcuts.publish(context, hasRecent) }
        }
    }

    /** The first, empty state on startup is skipped so it doesn't wipe what was saved before. */
    private suspend fun keepWidgetsCurrent() {
        combine(core.player.state, core.recentlyPlayed.items, WidgetSnapshot::of)
            .distinctUntilChanged()
            .drop(1)
            .collect { current ->
                val previous = widgetSnapshotState.value
                val snapshot = current.keepingOlderRecent(previous)
                widgetSnapshotState.value = snapshot
                WidgetSnapshot.write(widgetStore, snapshot)
                if (snapshot.nowPlaying != previous.nowPlaying) {
                    NowPlayingWidget().updateAll(context)
                    PlaybackTileService.refresh(context)
                }
                if (snapshot.recentlyPlayed != previous.recentlyPlayed) RecentlyPlayedWidget().updateAll(context)
            }
    }

    private var launching: Deferred<Unit>? = null
    private var loading: Deferred<Unit>? = null

    /** Callers share one launch, which runs on the app's scope so a caller leaving can't cut it short. */
    suspend fun launch() = launching.activeOr { checkLogin() }.also { launching = it }.await()

    /** Loads the library and moves on to the main screen, or to the login when the server no longer knows the token. */
    suspend fun loadData() = loading.activeOr { loadLibrary() }.also { loading = it }.await()

    private suspend fun checkLogin() {
        core.migrateFlutterData()
        val next = when {
            !hasConnection() -> Phase.NoConnection
            else -> try {
                if (fetchUserOrEndSession() == null) Phase.Login else Phase.Loading
            } catch (cancellation: CancellationException) {
                throw cancellation
            } catch (error: Exception) {
                Phase.Loading
            }
        }
        moveOn(from = Phase.Launching, to = next)
    }

    private suspend fun loadLibrary() {
        val startedIn = phase.value
        val isLoggedIn = core.auth.currentUser.value != null || fetchUserOrEndSession() != null
        if (isLoggedIn) core.loadData()
        moveOn(from = startedIn, to = if (isLoggedIn) Phase.Main else Phase.Login)
    }

    /** A token the server rejects logs the core out; this also clears what the app kept for that session, as logging out does. */
    private suspend fun fetchUserOrEndSession(): User? {
        val hadToken = core.auth.hasToken
        val user = core.auth.fetchCurrentUser()
        if (user == null && hadToken) clearSession()
        return user
    }

    /** Leaves [from] only if nothing else, like logging out, has moved the app on in the meantime. */
    private fun moveOn(from: Phase, to: Phase) {
        if (phase.value == from) phaseState.value = to
    }

    private fun <T> Deferred<T>?.activeOr(start: suspend () -> T): Deferred<T> =
        this?.takeIf { it.isActive } ?: scope.async { start() }

    /**
     * Android Auto can start the app with no screen to run the usual launch and library load,
     * so it runs them itself. While the server fails it offers the downloads and tries again on the next browse.
     */
    suspend fun launchWithoutScreen() {
        if (phase.value == Phase.Launching) launch()
        val retriesServer = phase.value == Phase.Offline && !isScreenShown && hasConnection()
        if (phase.value != Phase.Loading && !retriesServer) return

        try {
            loadData()
        } catch (cancellation: CancellationException) {
            throw cancellation
        } catch (error: Exception) {
            if (phase.value == Phase.Loading && !isScreenShown) goOffline()
        }
    }

    fun didLogIn() {
        phaseState.value = Phase.Loading
    }

    fun goOffline() {
        phaseState.value = Phase.Offline
    }

    fun reconnect() {
        phaseState.value = Phase.Launching
    }

    /** With a screen, the launch screen takes over from here; Android Auto alone has to launch by itself. */
    private fun reconnectWhenOnline() {
        reconnect()
        if (!isScreenShown) scope.launch { launchWithoutScreen() }
    }

    private val isScreenShown: Boolean
        get() = ProcessLifecycleOwner.get().lifecycle.currentState.isAtLeast(Lifecycle.State.STARTED)

    /** Runs on the app's scope, so leaving the screen that started it can't stop it halfway. */
    fun logOut(): Job = scope.launch {
        launching?.cancel()
        loading?.cancel()
        runCatching { core.logout() }
        clearSession()
        phaseState.value = Phase.Login
    }

    private suspend fun clearSession() {
        widgetSnapshotState.value = WidgetSnapshot()
        WidgetSnapshot.write(widgetStore, WidgetSnapshot())
        NowPlayingWidget().updateAll(context)
        RecentlyPlayedWidget().updateAll(context)
        navigator.reset()
        sheet = null
        isNowPlayingShown = false
        pendingLaunch = null
    }

    private fun watchConnectivity() {
        val connectivity = context.getSystemService(ConnectivityManager::class.java)
        connectivity.registerDefaultNetworkCallback(object : ConnectivityManager.NetworkCallback() {
            override fun onCapabilitiesChanged(network: Network, capabilities: NetworkCapabilities) {
                isOnlineState.value = capabilities.hasCapability(NetworkCapabilities.NET_CAPABILITY_INTERNET)
            }

            override fun onLost(network: Network) {
                isOnlineState.value = false
            }
        })
    }

    private fun hasConnection(): Boolean {
        val connectivity = context.getSystemService(ConnectivityManager::class.java)
        val capabilities = connectivity.getNetworkCapabilities(connectivity.activeNetwork) ?: return false
        return capabilities.hasCapability(NetworkCapabilities.NET_CAPABILITY_INTERNET)
    }

    companion object {
        /** The phone screen shows its own "Connection restored" prompt while offline. */
        fun reconnectsOnceOnline(phase: Phase, isScreenShown: Boolean): Boolean =
            phase == Phase.NoConnection || (phase == Phase.Offline && !isScreenShown)
    }
}

/** Sheets any screen can open; the main screen shows them. */
sealed interface AppSheet {
    data class Actions(val playable: Playable) : AppSheet
    data class AddToPlaylist(val playables: List<Playable>) : AppSheet
    data class Details(val playable: Playable) : AppSheet
    data object PlaybackSettings : AppSheet
}
