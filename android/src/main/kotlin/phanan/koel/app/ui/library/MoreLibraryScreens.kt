package phanan.koel.app.ui.library

import androidx.compose.foundation.layout.PaddingValues
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.size
import androidx.compose.foundation.lazy.LazyColumn
import androidx.compose.foundation.lazy.items
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.filled.Add
import androidx.compose.material.icons.filled.Delete
import androidx.compose.material.icons.filled.Favorite
import androidx.compose.material.icons.filled.RemoveCircleOutline
import androidx.compose.material.icons.outlined.CellTower
import androidx.compose.material.icons.outlined.Mic
import androidx.compose.material.icons.outlined.Piano
import androidx.compose.material3.Icon
import androidx.compose.material3.IconButton
import androidx.compose.runtime.Composable
import androidx.compose.runtime.collectAsState
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableStateListOf
import androidx.compose.runtime.mutableIntStateOf
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.remember
import androidx.compose.runtime.retain.retain
import androidx.compose.runtime.saveable.rememberSaveable
import androidx.compose.runtime.setValue
import androidx.compose.ui.Modifier
import androidx.compose.ui.unit.dp
import androidx.lifecycle.compose.collectAsStateWithLifecycle
import kotlinx.coroutines.coroutineScope
import kotlinx.coroutines.launch
import phanan.koel.app.ui.LocalAppModel
import phanan.koel.app.ui.collections.CollectionHeader
import phanan.koel.app.ui.collections.CollectionScreen
import phanan.koel.app.ui.collections.SongIndex
import phanan.koel.app.ui.collections.pluralized
import phanan.koel.app.ui.components.Artwork
import phanan.koel.app.ui.components.ArtworkWithOverlay
import phanan.koel.app.ui.components.FilterField
import phanan.koel.app.ui.components.ListPlaceholder
import phanan.koel.app.ui.components.LoadMore
import phanan.koel.app.ui.components.NowPlayingIndicator
import phanan.koel.app.ui.components.PlaceholderAction
import phanan.koel.app.ui.components.PlayableRow
import phanan.koel.app.ui.components.PlayableRowArtworkCornerRadius
import phanan.koel.app.ui.components.PlayableRowArtworkSize
import phanan.koel.app.ui.components.RefreshableListScaffold
import phanan.koel.app.ui.components.ScreenBottomPadding
import phanan.koel.app.ui.components.SectionGapAboveRows
import phanan.koel.app.ui.components.SectionSpacing
import phanan.koel.app.ui.components.SectionTitle
import phanan.koel.app.ui.components.SortMenu
import phanan.koel.app.ui.components.SortOption
import phanan.koel.app.ui.components.SortOptions
import phanan.koel.app.ui.components.SortSetting
import phanan.koel.app.ui.components.SwipeAction
import phanan.koel.app.ui.components.SwipeActions
import phanan.koel.app.ui.components.playableListStates
import phanan.koel.app.ui.components.rememberLoading
import phanan.koel.app.ui.components.rememberSortSetting
import phanan.koel.app.ui.main.Route
import phanan.koel.app.ui.theme.KoelColors
import phanan.koel.shared.models.Playable
import phanan.koel.shared.models.PlayableSortField
import phanan.koel.shared.models.Podcast
import phanan.koel.shared.models.RadioStation
import phanan.koel.shared.models.SortOrder
import phanan.koel.shared.models.filtered
import phanan.koel.shared.models.sorted

@Composable
fun GenresScreen() {
    val app = LocalAppModel.current
    val genres by app.core.genres.items.collectAsStateWithLifecycle()
    val loading = rememberLoading { app.core.genres.fetch() }

    RefreshableListScaffold(
        title = "Genres",
        loading = loading,
        isEmpty = genres.isEmpty(),
        placeholder = { ListPlaceholder(loading, "No genres", emptyIcon = Icons.Outlined.Piano) },
    ) { topPadding ->
        LazyColumn(contentPadding = PaddingValues(top = topPadding, bottom = ScreenBottomPadding)) {
            items(genres, key = { it.id }) { genre ->
                val name = genre.name.ifBlank { "Unknown Genre" }
                LibraryRow(title = name, subtitle = pluralized(genre.songCount, "song")) {
                    app.navigator.push(Route.Genre(genre.id, name))
                }
            }
        }
    }
}

/** A genre's songs under a collection header, a page at a time, sorted by the server and filtered here. */
@Composable
fun GenreScreen(genreId: String, name: String) {
    val app = LocalAppModel.current
    val songs = retain(genreId) { mutableStateListOf<Playable>() }
    var nextPage by retain(genreId) { mutableStateOf<Int?>(1) }
    var sortChanges by retain(genreId) { mutableIntStateOf(0) }
    var sort by rememberSortSetting("genre.sort", SortSetting(PlayableSortField.TITLE, SortOrder.ASC))
    var filter by rememberSaveable { mutableStateOf("") }
    val shown = songs.toList().filtered(filter)
    val songIndex = SongIndex.ifSortedByTitle(shown, sort)
    val songCount = app.core.genres.byId(genreId)?.songCount

    suspend fun loadNextPage() {
        val page = nextPage ?: return
        val sortChangesAtRequest = sortChanges
        val result = app.core.playables.fetchPageForGenre(genreId, page, sort.field, sort.order)
        if (sortChanges != sortChangesAtRequest) return
        songs.addAll(result.items.filter { new -> songs.none { it.id == new.id } })
        nextPage = result.nextPage
    }

    val loading = rememberLoading(genreId to sortChanges) { loadNextPage() }

    CollectionScreen(
        title = name,
        isLoading = false,
        coverUrl = songs.firstOrNull()?.artworkUrl,
        songIndex = songIndex,
        actions = {
            SortMenu(SortOptions.genreSongs, sort) { new ->
                sort = new
                songs.clear()
                nextPage = 1
                sortChanges++
            }
        },
    ) {
        if (songs.isNotEmpty()) {
            item(key = "header") {
                CollectionHeader(
                    artworkUrl = songs.firstOrNull()?.artworkUrl,
                    title = name,
                    detail = songCount?.let { pluralized(it, "song") },
                    canPlay = shown.isNotEmpty(),
                    onPlay = { app.actions.play(shown) },
                    onShuffle = { app.actions.play(shown, shuffled = true) },
                )
            }
            item(key = "filter") { FilterField(filter, { filter = it }) }
        }
        playableListStates(songs.isEmpty(), loading, emptyTitle = "No songs", filter = filter, hasNoResults = shown.isEmpty())
        items(shown, key = { it.id }) { song ->
            PlayableRow(song, modifier = Modifier.padding(end = if (songIndex != null) AlphabetIndexBarWidth else 0.dp))
        }
        if (songs.isNotEmpty() && nextPage != null) {
            item(key = "load-more") { LoadMore(songs.size) { loadNextPage() } }
        }
    }
}

@Composable
fun PodcastsScreen() {
    val app = LocalAppModel.current
    val podcasts by app.core.podcasts.podcasts.collectAsStateWithLifecycle()
    val newEpisodes by app.core.overview.recentlyAddedEpisodes.collectAsStateWithLifecycle()
    val loading = rememberLoading { forceRefresh ->
        coroutineScope {
            launch { runCatching { app.core.overview.refresh() } }
            if (forceRefresh) app.core.podcasts.refresh() else app.core.podcasts.fetchAll()
        }
    }
    val actions = remember { EntityActions(app) }
    var isAdding by remember { mutableStateOf(false) }
    var menuFor by remember { mutableStateOf<Podcast?>(null) }
    var pendingUnsubscribe by remember { mutableStateOf<Podcast?>(null) }
    var sort by rememberSortSetting("podcasts.sort", SortSetting(PodcastSortOption.LastPlayed.name, SortOrder.DESC))
    val sorted = podcasts.sorted(PodcastSortOption.named(sort.field).field, sort.order)

    if (isAdding) AddPodcastSheet(onDismiss = { isAdding = false })
    menuFor?.let { PodcastMenuSheet(it) { menuFor = null } }
    pendingUnsubscribe?.let { podcast -> PodcastUnsubscribe(podcast, { pendingUnsubscribe = null }) { actions.unsubscribe(podcast) } }

    RefreshableListScaffold(
        title = "Podcasts",
        loading = loading,
        isEmpty = podcasts.isEmpty(),
        placeholder = {
            ListPlaceholder(
                loading,
                emptyTitle = "No podcasts",
                emptyIcon = Icons.Outlined.Mic,
                emptyDescription = "Subscribe to a podcast and it'll show up here.",
                emptyAction = PlaceholderAction("Add a Podcast") { isAdding = true },
            )
        },
        actions = {
            SortMenu(PodcastSortOption.entries.map { SortOption(it.name, it.label) }, sort) { sort = it }
            IconButton(onClick = { isAdding = true }) { Icon(Icons.Default.Add, contentDescription = "Add Podcast") }
        },
    ) { topPadding ->
        LazyColumn(contentPadding = PaddingValues(top = topPadding, bottom = ScreenBottomPadding)) {
            if (newEpisodes.isNotEmpty()) {
                item(key = "new-episodes") {
                    SectionTitle("New Episodes", Modifier.padding(top = 8.dp, bottom = SectionGapAboveRows))
                }
                items(newEpisodes, key = { "episode-${it.id}" }) { PlayableRow(it) }
                if (sorted.isNotEmpty()) {
                    item(key = "podcasts-title") {
                        SectionTitle("All Podcasts", Modifier.padding(top = SectionSpacing, bottom = SectionGapAboveRows))
                    }
                }
            }
            items(sorted, key = { it.id }) { podcast ->
                SwipeActions(
                    trailing = if (app.isOffline) emptyList() else listOf(
                        SwipeAction.destructive("Unsubscribe", Icons.Default.RemoveCircleOutline) { pendingUnsubscribe = podcast },
                    ),
                ) {
                    LibraryRow(
                        title = podcast.title,
                        subtitle = podcast.author,
                        titleLines = 2,
                        artwork = { Artwork(podcast.imageUrl, size = PlayableRowArtworkSize, cornerRadius = PlayableRowArtworkCornerRadius) },
                        onLongClick = { menuFor = podcast },
                    ) { app.navigator.push(Route.Podcast(podcast.id)) }
                }
            }
        }
    }
}

@Composable
fun RadioStationsScreen() {
    val app = LocalAppModel.current
    val stations by app.core.radioStations.stations.collectAsStateWithLifecycle()
    val user by app.core.auth.currentUser.collectAsStateWithLifecycle()
    val canAddStations = user?.canManageRadioStations == true
    val state by app.core.player.state.collectAsStateWithLifecycle()
    val loading = rememberLoading { app.core.radioStations.fetchAll() }
    val actions = remember { EntityActions(app) }
    var isAdding by remember { mutableStateOf(false) }
    var menuFor by remember { mutableStateOf<RadioStation?>(null) }
    var pendingDeletion by remember { mutableStateOf<RadioStation?>(null) }

    if (isAdding) RadioStationFormSheet(null, onDismiss = { isAdding = false })
    menuFor?.let { RadioStationMenuSheet(it) { menuFor = null } }
    pendingDeletion?.let { station -> RadioStationDeletion(station, { pendingDeletion = null }) { actions.delete(station) } }

    RefreshableListScaffold(
        title = "Radio",
        loading = loading,
        isEmpty = stations.isEmpty(),
        placeholder = {
            ListPlaceholder(
                loading,
                emptyTitle = "No radio stations",
                emptyIcon = Icons.Outlined.CellTower,
                emptyDescription = "No radio stations available.",
                emptyAction = if (canAddStations) PlaceholderAction("Add a Station") { isAdding = true } else null,
            )
        },
        actions = {
            if (canAddStations) {
                IconButton(onClick = { isAdding = true }) { Icon(Icons.Default.Add, contentDescription = "New Station") }
            }
        },
    ) { topPadding ->
        LazyColumn(contentPadding = PaddingValues(top = topPadding, bottom = ScreenBottomPadding)) {
            items(stations.sortedBy { it.name.lowercase() }, key = { it.id }) { station ->
                SwipeActions(
                    trailing = if (station.canDelete && !app.isOffline) {
                        listOf(SwipeAction.destructive("Delete", Icons.Default.Delete) { pendingDeletion = station })
                    } else {
                        emptyList()
                    },
                ) {
                    LibraryRow(
                        title = station.name,
                        subtitle = station.description,
                        artwork = {
                            ArtworkWithOverlay(size = 44.dp, isOverlaid = state.radioStation?.id == station.id, artwork = { StationLogo(station, 44) }) {
                                NowPlayingIndicator(isPlaying = state.isPlaying || state.isBuffering)
                            }
                        },
                        trailing = {
                            if (station.favorite) {
                                Icon(Icons.Default.Favorite, contentDescription = "Favorite", tint = KoelColors.secondaryText, modifier = Modifier.size(14.dp))
                            }
                        },
                        showsChevron = false,
                        onLongClick = { menuFor = station },
                    ) { actions.play(station) }
                }
            }
        }
    }
}

/** The station's logo, or an antenna on the placeholder fill when it has none. */
@Composable
fun StationLogo(station: RadioStation, size: Int) {
    val logo = station.logo
    if (logo.isNullOrBlank()) {
        PlaceholderArtwork(Icons.Outlined.CellTower, size.dp)
    } else {
        Artwork(logo, size = size.dp, cornerRadius = 6.dp)
    }
}

@Composable
fun ArtistSongsScreen(artistId: String) {
    val app = LocalAppModel.current
    val artist by remember(artistId) { app.core.artists.observe(artistId) }.collectAsState(app.core.artists.byId(artistId))
    val songs by remember(artistId) { app.core.playables.artistSongs(artistId) }.collectAsState(emptyList())

    PlayableListScreen(
        title = artist?.name ?: "Songs",
        playables = songs,
        empty = EmptyState("No songs"),
        load = { app.core.playables.fetchForArtist(artistId, forceRefresh = true) },
        sort = ListSort(SortOptions.artistSongs, "artist.sort", SortSetting(PlayableSortField.TITLE, SortOrder.ASC)),
        isLargeTitle = false,
    )
}

@Composable
fun SearchSongsScreen(keywords: String) {
    val app = LocalAppModel.current
    var songs by retain(keywords) { mutableStateOf(emptyList<Playable>()) }

    PlayableListScreen(
        title = keywords,
        playables = songs,
        empty = EmptyState("No songs"),
        load = { songs = app.core.search.searchPlayables(keywords) },
        filterPrompt = null,
        isLargeTitle = false,
        canRefresh = false,
    )
}
