package phanan.koel.app.ui.collections

import androidx.compose.animation.animateContentSize
import androidx.compose.foundation.clickable
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.aspectRatio
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.lazy.LazyListScope
import androidx.compose.foundation.lazy.items
import androidx.compose.foundation.text.selection.SelectionContainer
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.automirrored.filled.QueueMusic
import androidx.compose.material.icons.filled.Mic
import androidx.compose.material.icons.filled.MusicNote
import androidx.compose.material.icons.filled.RemoveCircleOutline
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.runtime.LaunchedEffect
import androidx.compose.runtime.collectAsState
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.produceState
import androidx.compose.runtime.remember
import androidx.compose.runtime.rememberCoroutineScope
import androidx.compose.runtime.saveable.rememberSaveable
import androidx.compose.runtime.setValue
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.drawWithContent
import androidx.compose.ui.graphics.BlendMode
import androidx.compose.ui.graphics.Brush
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.graphics.CompositingStrategy
import androidx.compose.ui.graphics.Shadow
import androidx.compose.ui.graphics.graphicsLayer
import androidx.compose.ui.graphics.vector.ImageVector
import androidx.compose.ui.layout.layout
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.text.style.TextAlign
import androidx.compose.ui.text.style.TextOverflow
import androidx.compose.ui.unit.Dp
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import kotlinx.coroutines.flow.Flow
import kotlinx.coroutines.launch
import phanan.koel.app.AppModel
import phanan.koel.app.ui.LocalAppModel
import phanan.koel.app.ui.components.Artwork
import phanan.koel.app.ui.components.ArtworkCard
import phanan.koel.app.ui.components.FilterField
import phanan.koel.app.ui.components.Loading
import phanan.koel.app.ui.components.LoadingRows
import phanan.koel.app.ui.components.OverflowMenu
import phanan.koel.app.ui.components.PlayableRow
import phanan.koel.app.ui.components.PlayableRowStyle
import phanan.koel.app.ui.components.SectionContentGap
import phanan.koel.app.ui.components.SectionGapAboveRows
import phanan.koel.app.ui.components.SectionSpacing
import phanan.koel.app.ui.components.SectionTitle
import phanan.koel.app.ui.components.Shelf
import phanan.koel.app.ui.components.SortMenu
import phanan.koel.app.ui.components.SortOptions
import phanan.koel.app.ui.components.SortSetting
import phanan.koel.app.ui.components.SwipeToRemove
import phanan.koel.app.ui.components.playableListStates
import phanan.koel.app.ui.components.rememberLoading
import phanan.koel.app.ui.components.rememberSortSetting
import phanan.koel.app.ui.library.AlbumEditSheet
import phanan.koel.app.ui.library.AlphabetIndexBarWidth
import phanan.koel.app.ui.library.ArtistEditSheet
import phanan.koel.app.ui.library.EntityActions
import phanan.koel.app.ui.library.FolderPickerSheet
import phanan.koel.app.ui.library.PlaylistDeletion
import phanan.koel.app.ui.library.PlaylistFormSheet
import phanan.koel.app.ui.library.PodcastUnsubscribe
import phanan.koel.app.ui.library.AlbumMenuSheet
import phanan.koel.app.ui.main.Route
import phanan.koel.app.ui.theme.KoelColors
import phanan.koel.shared.models.Playable
import phanan.koel.shared.models.PlayableSortField
import phanan.koel.shared.models.Song
import phanan.koel.shared.models.SortOrder
import phanan.koel.shared.models.filtered
import phanan.koel.shared.models.sorted
import phanan.koel.shared.models.Album
import phanan.koel.shared.session.Feature

@Composable
fun AlbumScreen(albumId: String) {
    val app = LocalAppModel.current
    val actions = remember { EntityActions(app) }
    val album by remember(albumId) { app.core.albums.observe(albumId) }.collectAsState(app.core.albums.byId(albumId))
    val songs by rememberSongs(remember(albumId) { app.core.playables.albumSongs(albumId) })
    var sort by rememberSortSetting("album", SortSetting(PlayableSortField.TRACK, SortOrder.ASC))
    var filter by rememberSaveable { mutableStateOf("") }
    val displayed = songs.sorted(sort.field, sort.order).filtered(filter)
    var isEditing by remember { mutableStateOf(false) }
    val loading = rememberLoading(albumId) { forceRefresh ->
        app.core.albums.resolve(albumId, forceRefresh)
        app.core.playables.fetchForAlbum(albumId, forceRefresh)
    }

    val current = album
    if (isEditing && current != null) AlbumEditSheet(current) { isEditing = false }

    CollectionScreen(
        title = current?.name.orEmpty(),
        isLoading = current == null,
        coverUrl = current?.cover,
        hasFailed = loading.hasFailed,
        onRetry = loading::retry,
        onRefresh = { loading.run(forceRefresh = true) },
        actions = {
            SortMenu(SortOptions.albumSongs, sort) { sort = it }
            if (current != null) OverflowMenu(actions.albumMenu(current, onEdit = { isEditing = true }, playables = songs))
        },
    ) {
        if (current == null) return@CollectionScreen
        item(key = "header") {
            CollectionHeader(
                artworkUrl = current.cover,
                title = current.name,
                subtitle = current.artistName,
                onSubtitleClick = if (current.hasBrowsableArtist && !app.isOffline) ({ app.navigator.push(Route.Artist(current.artistId)) }) else null,
                detail = collectionDetail(current.year, displayed.size, displayed.sumOf { it.length }),
                favorite = favoriteToggle(app, current.favorite) { app.core.albums.toggleFavorite(current) },
                canPlay = displayed.isNotEmpty(),
                onPlay = { app.actions.play(displayed) },
                onShuffle = { app.actions.play(displayed, shuffled = true) },
            )
        }
        songList(songs, displayed, filter, { filter = it }, loading, emptyTitle = null) { song ->
            PlayableRow(song, style = PlayableRowStyle.Album)
        }
        item(key = "about") {
            About(remember(albumId) { suspend { app.core.mediaInfo.fetchForAlbum(albumId).information } })
        }
    }
}

@Composable
fun ArtistScreen(artistId: String) {
    val app = LocalAppModel.current
    val actions = remember { EntityActions(app) }
    val artist by remember(artistId) { app.core.artists.observe(artistId) }.collectAsState(app.core.artists.byId(artistId))
    val songs by rememberSongs(remember(artistId) { app.core.playables.artistSongs(artistId) })
    val topSongs = songs.sortedByDescending { it.playCount }.take(TOP_SONG_COUNT)
    var isEditing by remember { mutableStateOf(false) }
    var isShowingInfo by remember { mutableStateOf(false) }
    val loading = rememberLoading(artistId) { forceRefresh ->
        app.core.artists.resolve(artistId, forceRefresh)
        app.core.playables.fetchForArtist(artistId, forceRefresh)
    }

    var albumMenu by remember { mutableStateOf<Album?>(null) }
    val scope = rememberCoroutineScope()

    val current = artist
    if (isEditing && current != null) ArtistEditSheet(current) { isEditing = false }
    if (isShowingInfo && current != null) ArtistInfoSheet(current) { isShowingInfo = false }
    albumMenu?.let { AlbumMenuSheet(it) { albumMenu = null } }

    CollectionScreen(
        title = current?.name.orEmpty(),
        isLoading = current == null,
        coverUrl = current?.imageUrl,
        isHeroUnderBar = true,
        hasFailed = loading.hasFailed,
        onRetry = loading::retry,
        onRefresh = { loading.run(forceRefresh = true) },
        actions = {
            if (current != null) {
                OverflowMenu(actions.artistMenu(current, onInfo = { isShowingInfo = true }, onEdit = { isEditing = true }, playables = songs))
            }
        },
    ) {
        if (current == null) return@CollectionScreen
        item(key = "header") {
            ArtistHero(
                imageUrl = current.imageUrl,
                name = current.name,
                favorite = favoriteToggle(app, current.favorite) { app.core.artists.toggleFavorite(current) },
                canPlay = songs.isNotEmpty(),
                onPlay = { app.actions.play(songs) },
                onShuffle = { app.actions.play(songs, shuffled = true) },
            )
        }
        item(key = "top-songs") {
            SectionTitle("Top Songs", Modifier.padding(top = SectionSpacing, bottom = SectionGapAboveRows), onShowAll = { app.navigator.push(Route.ArtistSongs(artistId)) })
        }
        if (songs.isEmpty() && loading.isBusy) {
            item(key = "top-songs-loading") { LoadingRows(TOP_SONG_COUNT) }
        }
        items(topSongs, key = { "top-${it.id}" }) { song ->
            PlayableRow(song, style = PlayableRowStyle.Artist)
        }
        val albums = songs.filterIsInstance<Song>()
            .filter { it.albumId.isNotEmpty() }
            .distinctBy { it.albumId }
            .sortedByDescending { it.year ?: 0 }
        if (albums.isNotEmpty()) {
            item(key = "albums") {
                Box(Modifier.padding(top = SectionSpacing)) {
                    Shelf("Albums", albums, key = { it.albumId }) { song ->
                        ArtworkCard(
                            song.albumCover,
                            song.albumName,
                            subtitle = song.year?.toString(),
                            onLongClick = { scope.launch { albumMenu = runCatching { app.core.albums.resolve(song.albumId) }.getOrNull() } },
                        ) {
                            app.navigator.push(Route.Album(song.albumId))
                        }
                    }
                }
            }
        }
        item(key = "about") {
            About(remember(artistId) { suspend { app.core.mediaInfo.fetchForArtist(artistId).biography } })
        }
    }
}

private const val TOP_SONG_COUNT = 5

@Composable
fun PlaylistScreen(playlistId: String) {
    val app = LocalAppModel.current
    val scope = rememberCoroutineScope()
    val actions = remember { EntityActions(app) }
    val playlists by app.core.playlists.playlists.collectAsState()
    val playlist = playlists.firstOrNull { it.id == playlistId }
    val allSongs by rememberSongs(remember(playlistId) { app.core.playables.playlistSongs(playlistId) })
    val sortOptions = SortOptions.playlistSongs(app.core.session.supports(Feature.CUSTOM_PLAYLIST_ORDER))
    var sort by rememberSortSetting("playlist", SortSetting(sortOptions.first().field, SortOrder.ASC))
    var filter by rememberSaveable { mutableStateOf("") }
    val displayed = allSongs.sorted(sort.field, sort.order).filtered(filter)
    val songIndex = SongIndex.ifSortedByTitle(displayed, sort)
    var isEditing by remember { mutableStateOf(false) }
    var isMoving by remember { mutableStateOf(false) }
    var isConfirmingDelete by remember { mutableStateOf(false) }
    val canRemoveSongs = playlist != null && playlist.canEdit && !playlist.isSmart && !app.isOffline
    val loading = rememberLoading(playlistId) { forceRefresh ->
        val store = app.core.playlists
        if (store.byId(playlistId) == null) store.fetchAll()
        if (store.byId(playlistId) != null) app.core.playables.fetchForPlaylist(playlistId, forceRefresh)
    }
    val isGone = loading.hasLoaded && !loading.hasFailed && app.core.playlists.byId(playlistId) == null

    LaunchedEffect(isGone) {
        if (isGone) app.navigator.pop()
    }

    if (playlist != null) {
        if (isEditing) PlaylistFormSheet(playlist, onDismiss = { isEditing = false })
        if (isMoving) FolderPickerSheet(playlist, onDismiss = { isMoving = false }) { actions.move(playlist, it) }
        if (isConfirmingDelete) PlaylistDeletion(playlist, onDismiss = { isConfirmingDelete = false }) { actions.delete(playlist) }
    }

    CollectionScreen(
        title = playlist?.name.orEmpty(),
        isLoading = playlist == null,
        coverUrl = playlist?.cover ?: allSongs.firstOrNull()?.artworkUrl,
        hasFailed = loading.hasFailed,
        onRetry = loading::retry,
        onRefresh = { loading.run(forceRefresh = true) },
        songIndex = songIndex,
        actions = {
            SortMenu(sortOptions, sort) { sort = it }
            if (playlist != null) {
                OverflowMenu(
                    actions.playlistMenu(
                        playlist,
                        onEdit = { isEditing = true },
                        onMove = { isMoving = true },
                        onDelete = { isConfirmingDelete = true },
                        playables = displayed,
                    ),
                )
            }
        },
    ) {
        if (playlist == null) return@CollectionScreen
        item(key = "header") {
            CollectionHeader(
                artworkUrl = playlist.cover ?: allSongs.firstOrNull()?.artworkUrl,
                title = playlist.name,
                subtitle = playlist.description?.takeIf { it.isNotBlank() },
                detail = playlistDetail(playlist, displayed.size, displayed.sumOf { it.length }),
                canPlay = displayed.isNotEmpty(),
                onPlay = { app.actions.play(displayed) },
                onShuffle = { app.actions.play(displayed, shuffled = true) },
            )
        }
        songList(allSongs, displayed, filter, { filter = it }, loading, emptyTitle = "The playlist is empty.", emptyIcon = Icons.AutoMirrored.Filled.QueueMusic) { song ->
            SwipeToRemove(
                enabled = canRemoveSongs,
                onRemove = {
                    scope.launch {
                        runCatching { app.core.playlists.removeFromPlaylist(listOf(song), playlist) }
                            .onSuccess { app.messages.show("Removed from Playlist", icon = Icons.Default.RemoveCircleOutline) }
                            .onFailure { app.messages.showError(message = "Could not remove from playlist.") }
                    }
                },
            ) {
                PlayableRow(song, modifier = Modifier.padding(end = if (songIndex != null) AlphabetIndexBarWidth else 0.dp))
            }
        }
    }
}

@Composable
fun PodcastScreen(podcastId: String) {
    val app = LocalAppModel.current
    val actions = remember { EntityActions(app) }
    val podcast by remember(podcastId) { app.core.podcasts.observe(podcastId) }.collectAsState(app.core.podcasts.byId(podcastId))
    val allEpisodes by rememberSongs(remember(podcastId) { app.core.playables.podcastEpisodes(podcastId) })
    var sort by rememberSortSetting("podcast", SortSetting(PlayableSortField.CREATED_AT, SortOrder.DESC))
    var filter by rememberSaveable { mutableStateOf("") }
    val displayed = allEpisodes.sorted(sort.field, sort.order).filtered(filter)
    var isConfirmingUnsubscribe by remember { mutableStateOf(false) }
    val loading = rememberLoading(podcastId) { forceRefresh ->
        app.core.podcasts.resolve(podcastId, forceRefresh)
        app.core.playables.fetchForPodcast(podcastId, forceRefresh)
    }

    val current = podcast
    if (isConfirmingUnsubscribe && current != null) {
        PodcastUnsubscribe(current, onDismiss = { isConfirmingUnsubscribe = false }) {
            app.navigator.pop()
            actions.unsubscribe(current)
        }
    }

    CollectionScreen(
        title = current?.title.orEmpty(),
        isLoading = current == null,
        coverUrl = current?.imageUrl,
        hasFailed = loading.hasFailed,
        onRetry = loading::retry,
        onRefresh = {
            runCatching { app.core.podcasts.resolve(podcastId, forceRefresh = true) }
            current?.let { actions.checkForNewEpisodes(it) }
        },
        actions = {
            SortMenu(SortOptions.episodes, sort) { sort = it }
            if (current != null) {
                OverflowMenu(actions.podcastMenu(current, onUnsubscribe = { isConfirmingUnsubscribe = true }, episodes = displayed))
            }
        },
    ) {
        if (current == null) return@CollectionScreen
        item(key = "header") {
            CollectionHeader(
                artworkUrl = current.imageUrl,
                title = current.title,
                subtitle = current.author.takeIf { it.isNotBlank() },
                detail = if (allEpisodes.isEmpty()) null else pluralized(allEpisodes.size, "episode"),
                canPlay = displayed.isNotEmpty(),
                onPlay = { app.actions.play(displayed) },
                onShuffle = { app.actions.play(displayed, shuffled = true) },
            ) {
                PodcastDescription(current.description.plainText)
            }
        }
        songList(allEpisodes, displayed, filter, { filter = it }, loading, emptyTitle = "No episodes", emptyIcon = Icons.Default.Mic) { episode ->
            PlayableRow(episode, style = PlayableRowStyle.Episode) { app.actions.play(episode) }
        }
    }
}

/** The filter, the rows, and what shows instead of them while loading, empty, failed or filtered to nothing. */
private fun LazyListScope.songList(
    all: List<Playable>,
    displayed: List<Playable>,
    filter: String,
    onFilterChange: (String) -> Unit,
    loading: Loading,
    emptyTitle: String?,
    emptyIcon: ImageVector = Icons.Default.MusicNote,
    row: @Composable (Playable) -> Unit,
) {
    if (all.isNotEmpty()) item(key = "filter") { FilterField(filter, onFilterChange) }
    playableListStates(all.isEmpty(), loading, emptyTitle, emptyIcon, filter, hasNoResults = displayed.isEmpty())
    items(displayed, key = { it.id }) { row(it) }
}

/** The artist's photo across the full width, fading into the page, with the name and actions over its bottom. */
@Composable
private fun ArtistHero(
    imageUrl: String?,
    name: String,
    favorite: FavoriteToggle?,
    canPlay: Boolean,
    onPlay: () -> Unit,
    onShuffle: () -> Unit,
) {
    Column(Modifier.fillMaxWidth(), horizontalAlignment = Alignment.CenterHorizontally) {
        Artwork(
            imageUrl,
            cornerRadius = 0.dp,
            modifier = Modifier
                .fillMaxWidth()
                .aspectRatio(1f)
                .graphicsLayer { compositingStrategy = CompositingStrategy.Offscreen }
                .drawWithContent {
                    drawContent()
                    drawRect(Brush.verticalGradient(0.6f to Color.Black, 1f to Color.Transparent), blendMode = BlendMode.DstIn)
                },
        )
        Column(
            Modifier.overlapAbove(HeroOverlap),
            horizontalAlignment = Alignment.CenterHorizontally,
            verticalArrangement = Arrangement.spacedBy(20.dp),
        ) {
            Text(
                name,
                style = MaterialTheme.typography.headlineLarge.copy(
                    fontWeight = FontWeight.Bold,
                    shadow = Shadow(Color.Black.copy(alpha = 0.5f), blurRadius = 16f),
                ),
                textAlign = TextAlign.Center,
                maxLines = 2,
                modifier = Modifier.padding(horizontal = 16.dp),
            )
            CollectionActions(favorite, canPlay, onPlay, onShuffle)
        }
    }
}

/** Moves the content up over whatever is above it by [distance], taking that much less room. */
private fun Modifier.overlapAbove(distance: Dp) = layout { measurable, constraints ->
    val placeable = measurable.measure(constraints)
    val overlap = distance.roundToPx().coerceAtMost(placeable.height)
    layout(placeable.width, placeable.height - overlap) { placeable.place(0, -overlap) }
}

private val HeroOverlap = 96.dp

/** The podcast's blurb, three lines until tapped. */
@Composable
private fun PodcastDescription(text: String) {
    if (text.isBlank()) return
    var isExpanded by remember { mutableStateOf(false) }
    Text(
        text,
        style = MaterialTheme.typography.bodySmall.copy(fontSize = 13.sp),
        color = KoelColors.secondaryText,
        textAlign = TextAlign.Center,
        maxLines = if (isExpanded) Int.MAX_VALUE else 3,
        overflow = TextOverflow.Ellipsis,
        modifier = Modifier.animateContentSize().clickable { isExpanded = !isExpanded },
    )
}

/** Album or artist information from the server: four lines until More is tapped. */
@Composable
private fun About(load: suspend () -> String) {
    val html by produceState<String?>(null, load) { value = runCatching { load() }.getOrNull() }
    val text = html?.plainText?.takeIf { it.isNotBlank() } ?: return
    var isExpanded by remember { mutableStateOf(false) }

    Column(
        Modifier.fillMaxWidth().padding(top = SectionSpacing).animateContentSize(),
        verticalArrangement = Arrangement.spacedBy(SectionContentGap),
    ) {
        SectionTitle("About")
        Column(Modifier.padding(horizontal = 16.dp), verticalArrangement = Arrangement.spacedBy(8.dp)) {
            SelectionContainer {
                Text(
                    text,
                    style = MaterialTheme.typography.bodyLarge.copy(fontSize = 17.sp, lineHeight = 24.sp),
                    maxLines = if (isExpanded) Int.MAX_VALUE else 4,
                    overflow = TextOverflow.Ellipsis,
                )
            }
            Text(
                if (isExpanded) "Less" else "More",
                style = MaterialTheme.typography.bodyMedium.copy(fontSize = 15.sp, fontWeight = FontWeight.SemiBold),
                color = KoelColors.highlight,
                modifier = Modifier.clickable { isExpanded = !isExpanded },
            )
        }
    }
}

@Composable
private fun rememberSongs(flow: Flow<List<Playable>>) = flow.collectAsState(emptyList())

@Composable
private fun favoriteToggle(app: AppModel, isFavorite: Boolean, toggle: suspend () -> Unit): FavoriteToggle? {
    val scope = rememberCoroutineScope()
    if (app.isOffline || !app.core.session.supports(Feature.FAVORITE_ENTITIES)) return null
    return FavoriteToggle(isFavorite) {
        scope.launch { runCatching { toggle() }.onFailure { app.messages.showError() } }
    }
}
