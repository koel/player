package phanan.koel.app.ui.library

import androidx.compose.foundation.clickable
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.PaddingValues
import androidx.compose.foundation.layout.BoxWithConstraints
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.Spacer
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.size
import androidx.compose.foundation.lazy.LazyColumn
import androidx.compose.foundation.lazy.items
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.automirrored.filled.QueueMusic
import androidx.compose.material.icons.filled.CellTower
import androidx.compose.material.icons.filled.MusicNote
import androidx.compose.material.icons.outlined.ArrowCircleDown
import androidx.compose.material.icons.outlined.AutoAwesomeMotion
import androidx.compose.material.icons.outlined.FavoriteBorder
import androidx.compose.material.icons.outlined.Mic
import androidx.compose.material.icons.outlined.MicExternalOn
import androidx.compose.material.icons.outlined.Piano
import androidx.compose.material3.Icon
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.runtime.LaunchedEffect
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.remember
import androidx.compose.runtime.setValue
import androidx.lifecycle.compose.collectAsStateWithLifecycle
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.graphics.vector.ImageVector
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import phanan.koel.app.ui.LocalAppModel
import phanan.koel.app.ui.components.ArtworkCard
import phanan.koel.app.ui.components.PlayableRow
import phanan.koel.app.ui.components.RowInsets
import phanan.koel.app.ui.components.SectionContentGap
import phanan.koel.app.ui.components.SectionGapAboveRows
import phanan.koel.app.ui.components.SectionSpacing
import phanan.koel.app.ui.components.SectionTitle
import phanan.koel.app.ui.components.ScreenScaffold
import phanan.koel.app.ui.components.rowDivider
import phanan.koel.app.ui.components.ScreenBottomPadding
import phanan.koel.app.ui.main.Route
import phanan.koel.app.ui.theme.LocalBrandColor
import phanan.koel.shared.models.Album
import phanan.koel.shared.session.Feature

/** The rows at the top of the Library tab, in Flutter's order. */
enum class LibraryDestination(val title: String, val icon: ImageVector, val route: Route) {
    Songs("Songs", Icons.Default.MusicNote, Route.Songs),
    Favorites("Favorites", Icons.Outlined.FavoriteBorder, Route.Favorites),
    Playlists("Playlists", Icons.AutoMirrored.Filled.QueueMusic, Route.Playlists),
    Artists("Artists", Icons.Outlined.MicExternalOn, Route.Artists),
    Albums("Albums", Icons.Outlined.AutoAwesomeMotion, Route.Albums),
    Genres("Genres", Icons.Outlined.Piano, Route.Genres),
    Podcasts("Podcasts", Icons.Outlined.Mic, Route.Podcasts),
    Radio("Radio", Icons.Default.CellTower, Route.RadioStations),
    Downloads("Downloaded", Icons.Outlined.ArrowCircleDown, Route.Downloads);

    companion object {
        /** Podcasts and radio only show when the server has them; offline, only downloads can play. */
        fun visible(supportsPodcasts: Boolean, supportsRadio: Boolean, isOffline: Boolean): List<LibraryDestination> =
            if (isOffline) {
                listOf(Downloads)
            } else {
                entries.filter { (it != Podcasts || supportsPodcasts) && (it != Radio || supportsRadio) }
            }
    }
}

@Composable
fun LibraryScreen() {
    val app = LocalAppModel.current
    val destinations = LibraryDestination.visible(
        supportsPodcasts = app.core.session.supports(Feature.PODCASTS),
        supportsRadio = app.core.session.supports(Feature.RADIO_STATIONS),
        isOffline = app.isOffline,
    )
    val recentlyAddedAlbums by app.core.overview.recentlyAddedAlbums.collectAsStateWithLifecycle()
    val mostPlayedSongs by app.core.overview.mostPlayedSongs.collectAsStateWithLifecycle()
    var albumMenu by remember { mutableStateOf<Album?>(null) }

    albumMenu?.let { AlbumMenuSheet(it) { albumMenu = null } }

    LaunchedEffect(app.isOffline) {
        if (!app.isOffline && recentlyAddedAlbums.isEmpty()) runCatching { app.core.overview.refresh() }
    }

    ScreenScaffold(title = "Library") { padding ->
        LazyColumn(contentPadding = PaddingValues(top = padding.calculateTopPadding(), bottom = ScreenBottomPadding)) {
            items(destinations, key = { it.name }) { destination ->
                Row(
                    Modifier
                        .fillMaxWidth()
                        .clickable { app.navigator.push(destination.route) }
                        .rowDivider(RowInsets.icon)
                        .padding(horizontal = 16.dp, vertical = 14.dp),
                    horizontalArrangement = Arrangement.spacedBy(16.dp),
                    verticalAlignment = Alignment.CenterVertically,
                ) {
                    Icon(destination.icon, contentDescription = null, tint = LocalBrandColor.current, modifier = Modifier.size(24.dp))
                    Text(destination.title, fontSize = 20.sp, modifier = Modifier.weight(1f))
                    Chevron()
                }
            }
            if (!app.isOffline && recentlyAddedAlbums.isNotEmpty()) {
                item(key = "recently-added") {
                    RecentlyAddedAlbums(recentlyAddedAlbums) { albumMenu = it }
                }
            }
            if (!app.isOffline && mostPlayedSongs.isNotEmpty()) {
                item(key = "most-played") {
                    SectionTitle("Most played", Modifier.padding(top = SectionSpacing, bottom = SectionGapAboveRows))
                }
                items(mostPlayedSongs, key = { "most-played-${it.id}" }) { PlayableRow(it) }
            }
        }
    }
}

/** The albums added last, in a grid like the Albums screen. */
@Composable
private fun RecentlyAddedAlbums(albums: List<Album>, onLongClick: (Album) -> Unit) {
    val app = LocalAppModel.current

    Column(Modifier.padding(top = SectionSpacing)) {
        SectionTitle("Recently added", Modifier.padding(bottom = SectionContentGap))
        BoxWithConstraints(Modifier.padding(horizontal = 16.dp)) {
            val columnCount = AlbumGrid.columnCount(maxWidth)
            Column(verticalArrangement = Arrangement.spacedBy(AlbumGrid.rowSpacing)) {
                albums.chunked(columnCount).forEach { row ->
                    Row(horizontalArrangement = Arrangement.spacedBy(AlbumGrid.spacing)) {
                        row.forEach { album ->
                            ArtworkCard(album.cover, album.name, Modifier.weight(1f), subtitle = album.artistName, size = null, onLongClick = { onLongClick(album) }) {
                                app.navigator.push(Route.Album(album.id))
                            }
                        }
                        repeat(columnCount - row.size) { Spacer(Modifier.weight(1f)) }
                    }
                }
            }
        }
    }
}
