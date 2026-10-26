package phanan.koel.app.ui.library

import androidx.compose.foundation.ExperimentalFoundationApi
import androidx.compose.foundation.background
import androidx.compose.foundation.combinedClickable
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.BoxScope
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.PaddingValues
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.size
import androidx.compose.foundation.lazy.LazyColumn
import androidx.compose.foundation.lazy.grid.GridCells
import androidx.compose.foundation.lazy.grid.GridItemSpan
import androidx.compose.foundation.lazy.grid.LazyVerticalGrid
import androidx.compose.foundation.lazy.grid.items
import androidx.compose.foundation.lazy.grid.rememberLazyGridState
import androidx.compose.foundation.lazy.items
import androidx.compose.foundation.lazy.rememberLazyListState
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.automirrored.filled.KeyboardArrowRight
import androidx.compose.material.icons.automirrored.filled.QueueMusic
import androidx.compose.material.icons.filled.Add
import androidx.compose.material.icons.filled.CreateNewFolder
import androidx.compose.material.icons.filled.Delete
import androidx.compose.material.icons.filled.Edit
import androidx.compose.material.icons.filled.KeyboardArrowDown
import androidx.compose.material.icons.outlined.AutoAwesomeMotion
import androidx.compose.material.icons.outlined.AutoFixHigh
import androidx.compose.material.icons.outlined.Folder
import androidx.compose.material.icons.outlined.MicExternalOn
import androidx.compose.material3.DropdownMenu
import androidx.compose.material3.Icon
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.remember
import androidx.compose.runtime.rememberCoroutineScope
import androidx.compose.runtime.saveable.rememberSaveable
import androidx.compose.runtime.setValue
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.rotate
import androidx.compose.ui.graphics.vector.ImageVector
import androidx.compose.ui.text.style.TextOverflow
import androidx.compose.ui.unit.Dp
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import androidx.lifecycle.compose.collectAsStateWithLifecycle
import kotlinx.coroutines.launch
import phanan.koel.app.ui.LocalAppModel
import phanan.koel.app.ui.components.Artwork
import phanan.koel.app.ui.components.ArtworkCard
import phanan.koel.app.ui.components.CollectionLayout
import phanan.koel.app.ui.components.ConfirmDialog
import phanan.koel.app.ui.components.FormField
import phanan.koel.app.ui.components.FormSheet
import phanan.koel.app.ui.components.ListPlaceholder
import phanan.koel.app.ui.components.LoadMore
import phanan.koel.app.ui.components.MenuAction
import phanan.koel.app.ui.components.MenuItems
import phanan.koel.app.ui.components.OverflowMenu
import phanan.koel.app.ui.components.PlaceholderAction
import phanan.koel.app.ui.components.SortMenu
import phanan.koel.app.ui.components.SortOptions
import phanan.koel.app.ui.components.SortSetting
import phanan.koel.app.ui.components.SwipeAction
import phanan.koel.app.ui.components.SwipeActions
import phanan.koel.app.ui.components.rememberLoading
import phanan.koel.app.ui.components.rowDivider
import phanan.koel.app.ui.components.RefreshableListScaffold
import phanan.koel.app.ui.components.ScreenBottomPadding
import phanan.koel.app.ui.components.rememberCollectionLayout
import phanan.koel.app.ui.components.rememberSortSetting
import phanan.koel.app.ui.collections.kindLabel
import phanan.koel.app.ui.collections.pluralized
import phanan.koel.app.ui.main.Route
import phanan.koel.app.ui.theme.KoelColors
import phanan.koel.shared.models.Album
import phanan.koel.shared.models.AlbumSortField
import phanan.koel.shared.models.Artist
import phanan.koel.shared.models.ArtistSortField
import phanan.koel.shared.models.Playlist
import phanan.koel.shared.models.PlaylistFolder

@Composable
fun AlbumsScreen() {
    val app = LocalAppModel.current
    val store = app.core.albums
    val albums by store.items.collectAsStateWithLifecycle()
    val hasMore by store.hasMore.collectAsStateWithLifecycle()
    val scope = rememberCoroutineScope()
    var sort by rememberSortSetting("albums", SortSetting(store.sortField, store.sortOrder))
    val loading = rememberLoading { forceRefresh ->
        if (sort.needsFirstPage(SortSetting(store.sortField, store.sortOrder), store.items.value.isEmpty(), forceRefresh)) store.refresh(sort.field, sort.order)
    }
    var layout by rememberCollectionLayout("albums")
    var menuFor by remember { mutableStateOf<Album?>(null) }
    val isIndexed = SectionIndex.isShown(albums.size, sort.field == AlbumSortField.NAME)
    val isSortedByYear = sort.field == AlbumSortField.YEAR

    menuFor?.let { AlbumMenuSheet(it) { menuFor = null } }

    RefreshableListScaffold(
        title = "Albums",
        loading = loading,
        isEmpty = albums.isEmpty(),
        placeholder = { ListPlaceholder(loading, "No albums", emptyIcon = Icons.Outlined.AutoAwesomeMotion) },
        actions = {
            SortMenu(SortOptions.albums, sort, layout = layout, onLayoutChange = { layout = it }) { new ->
                sort = new
                scope.launch { loading.run { store.refresh(new.field, new.order) } }
            }
        },
    ) { topPadding ->
        when (layout) {
            CollectionLayout.Grid -> AlbumGridContent(albums, hasMore, isIndexed, isSortedByYear, topPadding, onLongClick = { menuFor = it })
            CollectionLayout.List -> AlbumListContent(albums, hasMore, isIndexed, isSortedByYear, topPadding, onLongClick = { menuFor = it })
        }
    }
}

@Composable
private fun BoxScope.AlbumGridContent(
    albums: List<Album>,
    hasMore: Boolean,
    isIndexed: Boolean,
    isSortedByYear: Boolean,
    topPadding: Dp,
    onLongClick: (Album) -> Unit,
) {
    val app = LocalAppModel.current
    val gridState = rememberLazyGridState()
    LazyVerticalGrid(
        state = gridState,
        columns = GridCells.Adaptive(AlbumGrid.minimumCardWidth),
        contentPadding = PaddingValues(
            start = 16.dp,
            end = 16.dp + if (isIndexed) AlphabetIndexBarWidth else 0.dp,
            top = topPadding + 8.dp,
            bottom = ScreenBottomPadding,
        ),
        horizontalArrangement = Arrangement.spacedBy(AlbumGrid.spacing),
        verticalArrangement = Arrangement.spacedBy(AlbumGrid.rowSpacing),
    ) {
        items(albums, key = { it.id }) { album ->
            val year = album.year
            val subtitle = if (isSortedByYear && year != null) "${album.artistName} · $year" else album.artistName
            ArtworkCard(album.cover, album.name, subtitle = subtitle, size = null, onLongClick = { onLongClick(album) }) {
                app.navigator.push(Route.Album(album.id))
            }
        }
        if (hasMore) {
            item(key = "load-more", span = { GridItemSpan(maxLineSpan) }) {
                LoadMore(albums.size) { app.core.albums.loadMore() }
            }
        }
    }
    if (isIndexed) SideIndex(albums, { it.name }) { gridState.scrollToItem(it) }
}

/** Flutter's albums list: a small cover, the album and its artist, the year when sorted by it, and a swipe to queue it. */
@Composable
private fun BoxScope.AlbumListContent(
    albums: List<Album>,
    hasMore: Boolean,
    isIndexed: Boolean,
    isSortedByYear: Boolean,
    topPadding: Dp,
    onLongClick: (Album) -> Unit,
) {
    val app = LocalAppModel.current
    val actions = remember { EntityActions(app) }
    val listState = rememberLazyListState()
    LazyColumn(state = listState, contentPadding = PaddingValues(top = topPadding, bottom = ScreenBottomPadding)) {
        items(albums, key = { it.id }) { album ->
            val year = album.year
            SwipeActions(leading = listOf(SwipeAction.queue { actions.playLast(album) })) {
                LibraryRow(
                    title = album.name,
                    subtitle = album.artistName,
                    artwork = { Artwork(album.cover, size = 40.dp) },
                    artworkWidth = 40.dp,
                    trailing = if (isSortedByYear && year != null) {
                        { Text(year.toString(), fontSize = 13.sp, color = KoelColors.secondaryText) }
                    } else {
                        null
                    },
                    onLongClick = { onLongClick(album) },
                    modifier = Modifier.padding(end = if (isIndexed) AlphabetIndexBarWidth else 0.dp),
                ) { app.navigator.push(Route.Album(album.id)) }
            }
        }
        if (hasMore) {
            item(key = "load-more") { LoadMore(albums.size) { app.core.albums.loadMore() } }
        }
    }
    if (isIndexed) SideIndex(albums, { it.name }) { listState.scrollToItem(it) }
}

@Composable
fun ArtistsScreen() {
    val app = LocalAppModel.current
    val store = app.core.artists
    val artists by store.items.collectAsStateWithLifecycle()
    val hasMore by store.hasMore.collectAsStateWithLifecycle()
    val scope = rememberCoroutineScope()
    var sort by rememberSortSetting("artists", SortSetting(store.sortField, store.sortOrder))
    val loading = rememberLoading { forceRefresh ->
        if (sort.needsFirstPage(SortSetting(store.sortField, store.sortOrder), store.items.value.isEmpty(), forceRefresh)) store.refresh(sort.field, sort.order)
    }
    var menuFor by remember { mutableStateOf<Artist?>(null) }
    val listState = rememberLazyListState()
    val actions = remember { EntityActions(app) }
    val isIndexed = SectionIndex.isShown(artists.size, sort.field == ArtistSortField.NAME)

    menuFor?.let { ArtistMenuSheet(it) { menuFor = null } }

    RefreshableListScaffold(
        title = "Artists",
        loading = loading,
        isEmpty = artists.isEmpty(),
        placeholder = { ListPlaceholder(loading, "No artists", emptyIcon = Icons.Outlined.MicExternalOn) },
        actions = {
            SortMenu(SortOptions.artists, sort) { new ->
                sort = new
                scope.launch { loading.run { store.refresh(new.field, new.order) } }
            }
        },
    ) { topPadding ->
        LazyColumn(state = listState, contentPadding = PaddingValues(top = topPadding, bottom = ScreenBottomPadding)) {
            items(artists, key = { it.id }) { artist ->
                SwipeActions(trailing = listOf(SwipeAction.playLast { actions.playLast(artist) })) {
                    LibraryRow(
                        title = artist.name,
                        artwork = { Artwork(artist.imageUrl, size = 44.dp, isCircle = true) },
                        onLongClick = { menuFor = artist },
                        modifier = Modifier.padding(end = if (isIndexed) AlphabetIndexBarWidth else 0.dp),
                    ) { app.navigator.push(Route.Artist(artist.id)) }
                }
            }
            if (hasMore) {
                item(key = "load-more") { LoadMore(artists.size) { store.loadMore() } }
            }
        }
        if (isIndexed) SideIndex(artists, { it.name }) { listState.scrollToItem(it) }
    }
}

/**
 * A row in a library list, as iOS draws them: 44dp artwork, the title (and maybe a subtitle), a
 * trailing disclosure chevron, and a hairline under the text.
 */
@OptIn(ExperimentalFoundationApi::class)
@Composable
fun LibraryRow(
    title: String,
    modifier: Modifier = Modifier,
    subtitle: String? = null,
    titleLines: Int = 1,
    artwork: (@Composable () -> Unit)? = null,
    artworkWidth: Dp = 44.dp,
    trailing: (@Composable () -> Unit)? = null,
    showsChevron: Boolean = true,
    onLongClick: (() -> Unit)? = null,
    onClick: () -> Unit,
) {
    val textStart = if (artwork != null) 16.dp + artworkWidth + 12.dp else 16.dp
    Row(
        modifier
            .fillMaxWidth()
            .combinedClickable(onClick = onClick, onLongClick = onLongClick)
            .rowDivider(textStart)
            .padding(horizontal = 16.dp, vertical = 8.dp),
        horizontalArrangement = Arrangement.spacedBy(12.dp),
        verticalAlignment = Alignment.CenterVertically,
    ) {
        artwork?.invoke()
        Column(Modifier.weight(1f).padding(vertical = 4.dp), verticalArrangement = Arrangement.spacedBy(2.dp)) {
            Text(title, fontSize = 16.sp, maxLines = titleLines, overflow = TextOverflow.Ellipsis)
            subtitle?.takeIf { it.isNotBlank() }?.let {
                Text(it, fontSize = 14.sp, color = KoelColors.secondaryText, maxLines = 1, overflow = TextOverflow.Ellipsis)
            }
        }
        trailing?.invoke()
        if (showsChevron) Chevron()
    }
}

@Composable
fun Chevron() {
    Icon(Icons.AutoMirrored.Filled.KeyboardArrowRight, contentDescription = null, tint = KoelColors.faintText, modifier = Modifier.size(20.dp))
}

/** A symbol on the faint placeholder fill, standing in for missing artwork. */
@Composable
fun PlaceholderArtwork(icon: ImageVector, size: Dp, cornerRadius: Dp = 6.dp) {
    Box(Modifier.size(size).background(KoelColors.placeholder, RoundedCornerShape(cornerRadius)), contentAlignment = Alignment.Center) {
        Icon(icon, contentDescription = null, tint = KoelColors.secondaryText, modifier = Modifier.size(size * 0.4f))
    }
}

@Composable
fun PlaylistsScreen() {
    val app = LocalAppModel.current
    val store = app.core.playlists
    val folderStore = app.core.playlistFolders
    val playlists by store.playlists.collectAsStateWithLifecycle()
    val folders by folderStore.folders.collectAsStateWithLifecycle()
    val scope = rememberCoroutineScope()
    val actions = remember { EntityActions(app) }
    val loading = rememberLoading {
        store.fetchAll()
        folderStore.fetchAll()
    }
    var isCreatingPlaylist by remember { mutableStateOf(false) }
    var isCreatingFolder by remember { mutableStateOf(false) }
    var menuFor by remember { mutableStateOf<Playlist?>(null) }
    var pendingDeletion by remember { mutableStateOf<Playlist?>(null) }
    var renamingFolder by remember { mutableStateOf<PlaylistFolder?>(null) }
    var removingFolder by remember { mutableStateOf<PlaylistFolder?>(null) }
    var expandedFolders by rememberSaveable { mutableStateOf(emptySet<String>()) }

    if (isCreatingPlaylist) PlaylistFormSheet(null, onDismiss = { isCreatingPlaylist = false })
    if (isCreatingFolder) FolderFormSheet(onDismiss = { isCreatingFolder = false })
    menuFor?.let { PlaylistMenuSheet(it) { menuFor = null } }
    pendingDeletion?.let { playlist -> PlaylistDeletion(playlist, { pendingDeletion = null }) { actions.delete(playlist) } }
    renamingFolder?.let { folder ->
        FormSheet(title = "Rename Folder", fields = listOf(FormField("Folder Name", folder.name, isRequired = true)), onDismiss = { renamingFolder = null }) { (name) ->
            runCatching { folderStore.rename(folder, name) }.getOrElse { throw Exception("Could not rename folder.") }
            app.messages.show("Folder renamed")
        }
    }
    removingFolder?.let { folder ->
        ConfirmDialog(
            title = "Delete folder?",
            message = "Delete “${folder.name}”? Its playlists stay in your library.",
            confirmLabel = "Delete",
            onDismiss = { removingFolder = null },
        ) {
            scope.launch {
                runCatching {
                    folderStore.remove(folder)
                    store.fetchAll()
                }
                    .onSuccess { app.messages.show("Folder deleted", icon = Icons.Default.Delete) }
                    .onFailure { app.messages.showError(message = "Could not delete folder.") }
            }
        }
    }

    RefreshableListScaffold(
        title = "Playlists",
        loading = loading,
        isEmpty = playlists.isEmpty() && folders.isEmpty(),
        placeholder = {
            ListPlaceholder(
                loading,
                emptyTitle = "No playlists",
                emptyIcon = Icons.AutoMirrored.Filled.QueueMusic,
                emptyDescription = "Create a playlist to organize your favorite songs.",
                emptyAction = PlaceholderAction("Create Playlist") { isCreatingPlaylist = true },
            )
        },
        actions = {
            OverflowMenu(
                listOf(
                    MenuAction("New Playlist", Icons.AutoMirrored.Filled.QueueMusic) { isCreatingPlaylist = true },
                    MenuAction("New Folder", Icons.Default.CreateNewFolder) { isCreatingFolder = true },
                ),
                icon = Icons.Default.Add,
                label = "Add",
            )
        },
    ) { topPadding ->
        val sortedFolders = folders.sortedBy { it.name.lowercase() }
        val folderIds = folders.map { it.id }.toSet()
        LazyColumn(contentPadding = PaddingValues(top = topPadding, bottom = ScreenBottomPadding)) {
            sortedFolders.forEach { folder ->
                val inFolder = playlists.filter { it.folderId == folder.id }.sortedBy { it.name.lowercase() }
                val isExpanded = folder.id in expandedFolders
                item(key = "folder-${folder.id}") {
                    FolderRow(
                        folder,
                        playlistCount = inFolder.size,
                        isExpanded = isExpanded,
                        onToggle = { expandedFolders = if (isExpanded) expandedFolders - folder.id else expandedFolders + folder.id },
                        onQueue = { actions.queue(inFolder) },
                        onRename = { renamingFolder = folder },
                        onRemove = { removingFolder = folder },
                    )
                }
                if (isExpanded) {
                    items(inFolder, key = { it.id }) { playlist ->
                        SwipeablePlaylistRow(playlist, Modifier.padding(start = 16.dp), onMenu = { menuFor = playlist }, onDelete = { pendingDeletion = playlist })
                    }
                }
            }
            items(playlists.filter { it.folderId !in folderIds }.sortedBy { it.name.lowercase() }, key = { it.id }) { playlist ->
                SwipeablePlaylistRow(playlist, onMenu = { menuFor = playlist }, onDelete = { pendingDeletion = playlist })
            }
        }
    }
}

@Composable
private fun SwipeablePlaylistRow(playlist: Playlist, modifier: Modifier = Modifier, onMenu: () -> Unit, onDelete: () -> Unit) {
    val app = LocalAppModel.current
    val actions = remember { EntityActions(app) }
    SwipeActions(
        leading = listOf(SwipeAction.playLast { actions.queue(listOf(playlist)) }),
        trailing = if (playlist.canDelete && !app.isOffline) listOf(SwipeAction.destructive("Delete", Icons.Default.Delete, onDelete)) else emptyList(),
    ) {
        PlaylistRow(playlist, modifier, onLongClick = onMenu) { app.navigator.push(Route.Playlist(playlist.id)) }
    }
}

/** A folder heading: tap to show or hide its playlists, swipe to queue them all, long-press to rename or delete. */
@Composable
private fun FolderRow(
    folder: PlaylistFolder,
    playlistCount: Int,
    isExpanded: Boolean,
    onToggle: () -> Unit,
    onQueue: () -> Unit,
    onRename: () -> Unit,
    onRemove: () -> Unit,
) {
    var isMenuShown by remember { mutableStateOf(false) }
    Box {
        SwipeActions(leading = listOf(SwipeAction.playLast(onQueue))) {
            LibraryRow(
                title = folder.name,
                subtitle = pluralized(playlistCount, "playlist"),
                artwork = {
                    Box(Modifier.size(44.dp), contentAlignment = Alignment.Center) {
                        Icon(Icons.Outlined.Folder, contentDescription = null, tint = KoelColors.secondaryText, modifier = Modifier.size(26.dp))
                    }
                },
                trailing = {
                    Icon(
                        Icons.Default.KeyboardArrowDown,
                        contentDescription = if (isExpanded) "Collapse" else "Expand",
                        tint = KoelColors.faintText,
                        modifier = Modifier.size(22.dp).rotate(if (isExpanded) 0f else -90f),
                    )
                },
                showsChevron = false,
                onLongClick = { isMenuShown = true },
                onClick = onToggle,
            )
        }
        DropdownMenu(expanded = isMenuShown, onDismissRequest = { isMenuShown = false }) {
            MenuItems(
                listOf(
                    MenuAction("Rename…", Icons.Default.Edit, onClick = onRename),
                    MenuAction("Delete", Icons.Default.Delete, isDestructive = true, onClick = onRemove),
                ),
            ) { isMenuShown = false }
        }
    }
}

@Composable
fun PlaylistRow(playlist: Playlist, modifier: Modifier = Modifier, onLongClick: (() -> Unit)? = null, onClick: () -> Unit) {
    LibraryRow(
        title = playlist.name,
        subtitle = playlist.kindLabel,
        artwork = { PlaylistArtwork(playlist, size = 44) },
        onLongClick = onLongClick,
        modifier = modifier,
        onClick = onClick,
    )
}

/** The playlist's cover, or a symbol telling smart and standard playlists apart. */
@Composable
fun PlaylistArtwork(playlist: Playlist, size: Int) {
    val cover = playlist.cover
    if (!cover.isNullOrBlank()) {
        Artwork(cover, size = size.dp, cornerRadius = 6.dp)
    } else {
        PlaceholderArtwork(if (playlist.isSmart) Icons.Outlined.AutoFixHigh else Icons.AutoMirrored.Filled.QueueMusic, size.dp)
    }
}
