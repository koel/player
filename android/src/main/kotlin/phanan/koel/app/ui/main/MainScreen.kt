package phanan.koel.app.ui.main

import androidx.compose.material3.Button
import androidx.compose.material.icons.filled.WifiOff
import androidx.compose.material.icons.filled.Wifi
import androidx.compose.foundation.shape.CircleShape
import androidx.compose.foundation.layout.size
import androidx.compose.foundation.layout.navigationBarsPadding
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Box
import phanan.koel.app.ui.theme.LocalBrandColor
import phanan.koel.app.ui.theme.KoelColors
import phanan.koel.app.ui.theme.BrandMesh
import phanan.koel.app.ui.components.ToastHost
import phanan.koel.app.ui.components.ToastSpacing
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.remember
import androidx.compose.runtime.setValue
import androidx.compose.ui.layout.onSizeChanged
import androidx.compose.ui.platform.LocalDensity
import phanan.koel.app.ui.components.ProvideNowPlayingBrandColor
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.geometry.Offset
import androidx.compose.ui.draw.drawBehind
import androidx.compose.material3.NavigationBarItemDefaults
import androidx.compose.material.icons.filled.LibraryMusic
import androidx.activity.compose.BackHandler
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.padding
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.filled.Home
import androidx.compose.material.icons.filled.Search
import androidx.compose.material3.Icon
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.NavigationBar
import androidx.compose.material3.NavigationBarItem
import androidx.compose.material3.Scaffold
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.runtime.LaunchedEffect
import androidx.compose.runtime.snapshotFlow
import androidx.compose.runtime.getValue
import androidx.compose.runtime.saveable.rememberSaveableStateHolder
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.unit.dp
import androidx.compose.ui.graphics.vector.ImageVector
import androidx.lifecycle.compose.collectAsStateWithLifecycle
import androidx.navigation3.runtime.NavEntry
import androidx.navigation3.runtime.rememberSaveableStateHolderNavEntryDecorator
import androidx.navigation3.ui.NavDisplay
import phanan.koel.app.AppModel
import phanan.koel.app.AppSheet
import kotlinx.coroutines.flow.filterNotNull
import phanan.koel.app.perform
import phanan.koel.app.ui.LocalAppModel
import phanan.koel.app.ui.collections.AlbumScreen
import phanan.koel.app.ui.collections.ArtistScreen
import phanan.koel.app.ui.collections.PlaylistScreen
import phanan.koel.app.ui.collections.PodcastScreen
import phanan.koel.app.ui.components.AddToPlaylistSheet
import phanan.koel.app.ui.components.PlayableActionsSheet
import phanan.koel.app.ui.home.HomeScreen
import phanan.koel.app.ui.library.AlbumsScreen
import phanan.koel.app.ui.library.ArtistSongsScreen
import phanan.koel.app.ui.library.GenreScreen
import phanan.koel.app.ui.library.GenresScreen
import phanan.koel.app.ui.library.PodcastsScreen
import phanan.koel.app.ui.library.RadioStationsScreen
import phanan.koel.app.ui.library.SearchSongsScreen
import phanan.koel.app.ui.library.ArtistsScreen
import phanan.koel.app.ui.library.DownloadsScreen
import phanan.koel.app.ui.library.FavoritesScreen
import phanan.koel.app.ui.library.LibraryScreen
import phanan.koel.app.ui.library.PlaylistsScreen
import phanan.koel.app.ui.library.RecentlyPlayedScreen
import phanan.koel.app.ui.library.SongsScreen
import phanan.koel.app.ui.player.DetailsSheet
import phanan.koel.app.ui.player.MiniPlayer
import phanan.koel.app.ui.player.NowPlayingSheet
import phanan.koel.app.ui.player.PlaybackSettingsSheet
import phanan.koel.app.ui.search.SearchScreen

@Composable
fun MainScreen() {
    val app = LocalAppModel.current
    val navigator = app.navigator
    val state by app.core.player.state.collectAsStateWithLifecycle()
    val hasSomethingToShow = state.current != null || state.isRadioMode
    val phase by app.phase.collectAsStateWithLifecycle()
    val isOffline = phase == AppModel.Phase.Offline
    val tabStates = rememberSaveableStateHolder()
    val density = LocalDensity.current
    var bottomBarHeight by remember { mutableStateOf(0.dp) }

    LaunchedEffect(Unit) {
        snapshotFlow { app.pendingLaunch }.filterNotNull().collect { request ->
            app.pendingLaunch = null
            app.perform(request)
        }
    }

    ProvideNowPlayingBrandColor {
    BackHandler(enabled = !isOffline && navigator.stack(navigator.selectedTab).size > 1) { navigator.pop() }

    Scaffold(
        bottomBar = {
            Column(Modifier.onSizeChanged { size -> bottomBarHeight = with(density) { size.height.toDp() } }) {
                if (hasSomethingToShow) MiniPlayer(onOpen = { app.isNowPlayingShown = true })
                if (isOffline) ConnectivityBanner() else TabBar()
            }
        },
    ) { padding ->
        if (isOffline) {
            OfflineDownloads(Modifier.padding(padding))
            return@Scaffold
        }
        val tab = navigator.selectedTab
        tabStates.SaveableStateProvider(tab) {
            NavDisplay(
                backStack = navigator.stack(tab),
                onBack = { navigator.pop() },
                entryDecorators = listOf(rememberSaveableStateHolderNavEntryDecorator()),
                modifier = Modifier.padding(bottom = padding.calculateBottomPadding()),
                entryProvider = { route -> NavEntry(route) { Destination(route) } },
            )
        }
    }

    val isNowPlayingShown = app.isNowPlayingShown && hasSomethingToShow
    if (isNowPlayingShown) {
        NowPlayingSheet(onDismiss = { app.isNowPlayingShown = false })
    }

    when (val sheet = app.sheet) {
        is AppSheet.Actions -> PlayableActionsSheet(sheet.playable, onDismiss = { app.sheet = null })
        is AppSheet.AddToPlaylist -> AddToPlaylistSheet(sheet.playables, onDismiss = { app.sheet = null })
        is AppSheet.Details -> DetailsSheet(sheet.playable, onDismiss = { app.sheet = null })
        AppSheet.PlaybackSettings -> PlaybackSettingsSheet(onDismiss = { app.sheet = null })
        null -> Unit
    }

    if (!isNowPlayingShown) ToastHost(app.messages, Modifier.padding(bottom = bottomBarHeight + ToastSpacing.aboveBars))
    }
}

/** The tabs over the brand's darkest purple, tinted with the playing cover's color like iOS. */
@Composable
private fun TabBar() {
    NavigationBar(
        containerColor = BrandMesh.base.copy(alpha = 0.92f),
        tonalElevation = 0.dp,
        modifier = Modifier.drawBehind {
            drawLine(KoelColors.hairline, Offset.Zero, Offset(size.width, 0f), 0.5.dp.toPx())
        },
    ) {
        TabItem(AppTab.Home, "Home", Icons.Default.Home)
        TabItem(AppTab.Library, "Library", Icons.Default.LibraryMusic)
        TabItem(AppTab.Search, "Search", Icons.Default.Search)
    }
}

@Composable
private fun androidx.compose.foundation.layout.RowScope.TabItem(tab: AppTab, label: String, icon: ImageVector) {
    val navigator = LocalAppModel.current.navigator
    val brandColor = LocalBrandColor.current
    NavigationBarItem(
        selected = navigator.selectedTab == tab,
        onClick = { navigator.select(tab) },
        icon = { Icon(icon, contentDescription = null) },
        label = { Text(label) },
        colors = NavigationBarItemDefaults.colors(
            selectedIconColor = brandColor,
            selectedTextColor = brandColor,
            indicatorColor = Color.Transparent,
            unselectedIconColor = Color.White.copy(alpha = 0.54f),
            unselectedTextColor = Color.White.copy(alpha = 0.54f),
        ),
    )
}

@Composable
private fun Destination(route: Route) {
    when (route) {
        Route.Home -> HomeScreen()
        Route.Library -> LibraryScreen()
        Route.Search -> SearchScreen()
        Route.Songs -> SongsScreen()
        Route.Albums -> AlbumsScreen()
        Route.Artists -> ArtistsScreen()
        Route.Playlists -> PlaylistsScreen()
        Route.Favorites -> FavoritesScreen()
        Route.Downloads -> DownloadsScreen()
        Route.RecentlyPlayed -> RecentlyPlayedScreen()
        is Route.Album -> AlbumScreen(route.id)
        is Route.Artist -> ArtistScreen(route.id)
        is Route.Playlist -> PlaylistScreen(route.id)
        is Route.Podcast -> PodcastScreen(route.id)
        is Route.ArtistSongs -> ArtistSongsScreen(route.id)
        is Route.Genre -> GenreScreen(route.id, route.name)
        is Route.SearchSongs -> SearchSongsScreen(route.keywords)
        Route.Genres -> GenresScreen()
        Route.Podcasts -> PodcastsScreen()
        Route.RadioStations -> RadioStationsScreen()
    }
}

/** Without a connection, only downloaded songs can play. */
@Composable
private fun OfflineDownloads(modifier: Modifier) {
    Box(modifier) { DownloadsScreen() }
}

/** Under the mini player while offline, like iOS: a quiet notice, then a way back in once the connection returns. */
@Composable
private fun ConnectivityBanner() {
    val app = LocalAppModel.current
    val isRestored by app.connectionRestored.collectAsStateWithLifecycle()
    Box(Modifier.fillMaxWidth().navigationBarsPadding().padding(horizontal = 16.dp, vertical = 8.dp), contentAlignment = Alignment.Center) {
        if (isRestored) {
            Button(onClick = app::reconnect, shape = CircleShape) {
                Icon(Icons.Default.Wifi, contentDescription = null, modifier = Modifier.size(18.dp))
                Text("Connection restored! Tap to refresh.", modifier = Modifier.padding(start = 8.dp))
            }
        } else {
            Row(verticalAlignment = Alignment.CenterVertically, horizontalArrangement = Arrangement.spacedBy(6.dp)) {
                Icon(Icons.Default.WifiOff, contentDescription = null, tint = KoelColors.secondaryText, modifier = Modifier.size(16.dp))
                Text("No internet connection", style = MaterialTheme.typography.bodyMedium, color = KoelColors.secondaryText)
            }
        }
    }
}
