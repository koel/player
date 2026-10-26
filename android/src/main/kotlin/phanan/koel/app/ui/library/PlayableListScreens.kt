package phanan.koel.app.ui.library

import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.PaddingValues
import androidx.compose.foundation.layout.RowScope
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.lazy.LazyColumn
import androidx.compose.foundation.lazy.LazyListScope
import androidx.compose.foundation.lazy.items
import androidx.compose.foundation.lazy.rememberLazyListState
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.filled.FavoriteBorder
import androidx.compose.material.icons.filled.HeartBroken
import androidx.compose.material.icons.filled.History
import androidx.compose.material.icons.filled.MusicNote
import androidx.compose.material.icons.filled.RemoveCircleOutline
import androidx.compose.material.icons.outlined.ArrowCircleDown
import androidx.compose.material.icons.outlined.DownloadForOffline
import androidx.compose.material3.Icon
import androidx.compose.material3.IconButton
import androidx.compose.runtime.Composable
import androidx.compose.runtime.LaunchedEffect
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.remember
import androidx.compose.runtime.rememberCoroutineScope
import androidx.compose.runtime.saveable.rememberSaveable
import androidx.compose.runtime.setValue
import androidx.compose.ui.Modifier
import androidx.compose.ui.graphics.vector.ImageVector
import androidx.compose.ui.unit.dp
import androidx.lifecycle.compose.collectAsStateWithLifecycle
import kotlinx.coroutines.delay
import kotlinx.coroutines.launch
import phanan.koel.app.ui.LocalAppModel
import phanan.koel.app.ui.components.ConfirmDialog
import phanan.koel.app.ui.components.FilterField
import phanan.koel.app.ui.components.IconHint
import phanan.koel.app.ui.components.ListPlaceholder
import phanan.koel.app.ui.components.LoadMore
import phanan.koel.app.ui.components.PlayShuffleButtons
import phanan.koel.app.ui.components.RefreshableListScaffold
import phanan.koel.app.ui.components.rememberSortSetting
import phanan.koel.app.ui.components.LoadingRows
import phanan.koel.app.ui.components.NoResults
import phanan.koel.app.ui.components.PlayableRow
import phanan.koel.app.ui.components.SortMenu
import phanan.koel.app.ui.components.SortOption
import phanan.koel.app.ui.components.SortOptions
import phanan.koel.app.ui.components.SortSetting
import phanan.koel.app.ui.components.SwipeToRemove
import phanan.koel.app.ui.components.rememberLoading
import phanan.koel.app.ui.components.ScreenBottomPadding
import phanan.koel.app.ui.theme.KoelColors
import phanan.koel.shared.models.Playable
import phanan.koel.shared.models.PlayableSortField
import phanan.koel.shared.models.SortOrder
import phanan.koel.shared.models.filtered
import phanan.koel.shared.models.sorted
import phanan.koel.shared.session.Feature

/**
 * How a list of songs can be sorted. [fetch] gets a list the server sorts in the given sort, in
 * place of the screen's load: when the screen shows, on pull to refresh and on every change.
 * Without it, the list is sorted on the device.
 */
class ListSort(
    val options: List<SortOption>,
    val key: String,
    val default: SortSetting,
    val fetch: (suspend (SortSetting) -> Unit)? = null,
)

/** The red swipe that takes a song out of a list, e.g. "Undo Favorite" on Favorites. */
class ListRemoval(val label: String = "Remove", val icon: ImageVector = Icons.Default.RemoveCircleOutline, val onRemove: (Playable) -> Unit)

/** What a list shows when there's nothing in it, and when it couldn't load. */
class EmptyState(val title: String, val icon: ImageVector = Icons.Default.MusicNote, val description: String? = null, val hint: IconHint? = null)

/**
 * A titled screen of songs with a filter, Play and Shuffle on top, pull to refresh, and loading,
 * empty and failed states. With [searchServer], filtering searches the server instead of the
 * loaded songs. [playButtons] replaces the Play and Shuffle pills, given the current sort.
 */
@Composable
fun PlayableListScreen(
    title: String,
    playables: List<Playable>,
    empty: EmptyState,
    load: suspend (forceRefresh: Boolean) -> Unit = {},
    sort: ListSort? = null,
    removal: ListRemoval? = null,
    filterPrompt: String? = "Filter",
    searchServer: (suspend (String) -> List<Playable>)? = null,
    isLargeTitle: Boolean = true,
    canRefresh: Boolean = true,
    actions: @Composable RowScope.(isEmpty: Boolean) -> Unit = {},
    playButtons: (@Composable (sort: SortSetting?) -> Unit)? = null,
    footer: LazyListScope.() -> Unit = {},
) {
    val app = LocalAppModel.current
    val scope = rememberCoroutineScope()
    val settingState = sort?.let { rememberSortSetting(it.key, it.default) }
    val setting = settingState?.value
    val loading = rememberLoading { forceRefresh ->
        val fetchSorted = sort?.fetch
        val current = settingState?.value
        if (fetchSorted != null && current != null) fetchSorted(current) else load(forceRefresh)
    }
    val listState = rememberLazyListState()
    var filter by rememberSaveable { mutableStateOf("") }
    val isFiltering = filter.isNotBlank()
    val serverResults = rememberServerResults(filter, searchServer)
    val isSearchingServer = isFiltering && searchServer != null
    val source = if (isSearchingServer) serverResults.orEmpty() else playables
    val isSortedOnDevice = sort?.fetch == null || isSearchingServer
    val sorted = if (setting == null || !isSortedOnDevice) source else source.sorted(setting.field, setting.order)
    val shown = if (searchServer != null) sorted else sorted.filtered(filter)
    val isIndexed = SectionIndex.isShown(shown.size, setting?.field == PlayableSortField.TITLE)

    RefreshableListScaffold(
        title = title,
        loading = loading,
        isEmpty = playables.isEmpty() && !isFiltering,
        isLargeTitle = isLargeTitle,
        canRefresh = canRefresh,
        placeholder = { topPadding ->
            if (loading.hasLoaded) {
                ListPlaceholder(loading, empty.title, empty.icon, empty.description, empty.hint)
            } else {
                Box(Modifier.padding(top = topPadding)) { LoadingRows() }
            }
        },
        actions = {
            if (sort != null && settingState != null && setting != null && playables.isNotEmpty()) {
                SortMenu(sort.options, setting) { new ->
                    settingState.value = new
                    sort.fetch?.let { fetchSorted -> scope.launch { loading.run { fetchSorted(new) } } }
                }
            }
            actions(playables.isEmpty())
        },
    ) { topPadding ->
        val headerCount = (if (filterPrompt != null) 1 else 0) + 1
        LazyColumn(state = listState, contentPadding = PaddingValues(top = topPadding, bottom = ScreenBottomPadding)) {
            if (filterPrompt != null) item(key = "filter") { FilterField(filter, { filter = it }, prompt = filterPrompt) }
            item(key = "buttons") {
                when {
                    shown.isEmpty() && (!isSearchingServer || serverResults != null) -> NoResults(filter)
                    shown.isEmpty() -> Unit
                    playButtons != null -> if (!isFiltering) playButtons(setting)
                    else -> PlayShuffleButtons(
                        onPlay = { app.actions.play(shown) },
                        onShuffle = { app.actions.play(shown, shuffled = true) },
                    )
                }
            }
            items(shown, key = { it.id }) { playable ->
                SwipeToRemove(
                    enabled = removal != null,
                    onRemove = { removal?.onRemove?.invoke(playable) },
                    label = removal?.label ?: "Remove",
                    icon = removal?.icon ?: Icons.Default.RemoveCircleOutline,
                ) {
                    PlayableRow(playable, modifier = Modifier.padding(end = if (isIndexed) AlphabetIndexBarWidth else 0.dp))
                }
            }
            if (!isFiltering) footer()
        }
        if (isIndexed) SideIndex(shown, { it.title }) { listState.scrollToItem(headerCount + it) }
    }
}

/** Server search results for [keywords], or null while they load. */
@Composable
private fun rememberServerResults(keywords: String, search: (suspend (String) -> List<Playable>)?): List<Playable>? {
    var results by remember { mutableStateOf<List<Playable>?>(null) }
    LaunchedEffect(keywords, search) {
        results = null
        if (search == null || keywords.isBlank()) return@LaunchedEffect
        delay(300)
        results = runCatching { search(keywords.trim()) }.getOrDefault(emptyList())
    }
    return results
}

@Composable
fun FavoritesScreen() {
    val app = LocalAppModel.current
    val favorites by app.core.favorites.items.collectAsStateWithLifecycle()
    val supportsCustomOrder = app.core.session.supports(Feature.CUSTOM_FAVORITES_ORDER)
    val scope = rememberCoroutineScope()
    PlayableListScreen(
        "Favorites",
        favorites,
        EmptyState("No favorites", Icons.Default.FavoriteBorder, hint = IconHint(Icons.Default.FavoriteBorder, "icon in a song’s menu to mark it as favorite.")),
        load = { forceRefresh -> app.core.favorites.fetch(forceRefresh) },
        sort = ListSort(
            SortOptions.favorites(supportsCustomOrder),
            key = "favorites.sort",
            default = SortSetting(if (supportsCustomOrder) PlayableSortField.POSITION else PlayableSortField.TITLE, SortOrder.ASC),
        ),
        removal = if (app.isOffline) null else ListRemoval("Undo Favorite", Icons.Default.HeartBroken) { playable ->
            scope.launch { runCatching { app.core.favorites.unlike(playable) }.onFailure { app.messages.showError() } }
        },
    )
}

@Composable
fun RecentlyPlayedScreen() {
    val app = LocalAppModel.current
    val recent by app.core.recentlyPlayed.items.collectAsStateWithLifecycle()
    PlayableListScreen(
        "Recently Played",
        recent,
        EmptyState("No recently played songs", Icons.Default.History, "You have not played any songs yet."),
        load = { app.core.recentlyPlayed.fetchUnlessLoaded() },
        canRefresh = false,
    )
}

@Composable
fun DownloadsScreen() {
    val app = LocalAppModel.current
    val downloads by app.core.downloads.playables.collectAsStateWithLifecycle()
    var isConfirmingRemoveAll by remember { mutableStateOf(false) }

    if (isConfirmingRemoveAll) RemoveAllDownloadsConfirmation { isConfirmingRemoveAll = false }

    PlayableListScreen(
        "Downloaded",
        downloads,
        EmptyState("No downloaded songs", Icons.Outlined.ArrowCircleDown, hint = IconHint(Icons.Outlined.ArrowCircleDown, "icon next to a song to download it for offline playback.")),
        load = {},
        canRefresh = false,
        sort = ListSort(SortOptions.songs, key = "downloads", default = SortSetting(PlayableSortField.TITLE, SortOrder.ASC)),
        removal = ListRemoval { app.actions.removeDownload(it) },
        actions = { isEmpty ->
            if (!isEmpty) {
                IconButton(onClick = { isConfirmingRemoveAll = true }) {
                    Icon(Icons.Outlined.DownloadForOffline, contentDescription = "Remove all", tint = KoelColors.destructiveSwipe)
                }
            }
        },
    )
}

@Composable
fun RemoveAllDownloadsConfirmation(onDismiss: () -> Unit) {
    val app = LocalAppModel.current
    ConfirmDialog(
        title = "Remove all downloads?",
        message = "Downloaded songs will no longer play without a connection.",
        confirmLabel = "Remove all downloads",
        onDismiss = onDismiss,
    ) { app.core.downloads.clear() }
}

/** Every song, a page at a time; the next page loads as the end of the list comes into view. */
@Composable
fun SongsScreen() {
    val app = LocalAppModel.current
    val store = app.core.playables
    val songs by store.songs.collectAsStateWithLifecycle()
    val hasMore by store.hasMoreSongs.collectAsStateWithLifecycle()

    PlayableListScreen(
        title = "All songs",
        playables = songs,
        empty = EmptyState("No songs"),
        sort = ListSort(
            SortOptions.songs,
            key = "songs",
            default = SortSetting(store.songSortField, store.songSortOrder),
            fetch = { store.refreshSongs(it.field, it.order) },
        ),
        filterPrompt = "Search Songs",
        searchServer = { app.core.search.searchPlayables(it) },
        playButtons = { sort -> AllSongsPlayButtons(sort) },
    ) {
        if (hasMore) {
            item(key = "load-more") { LoadMore(songs.size) { store.loadMoreSongs() } }
        }
    }
}

/** Plays every song in the library in the current order, or shuffles a random selection, as Flutter did. */
@Composable
private fun AllSongsPlayButtons(sort: SortSetting?) {
    val app = LocalAppModel.current
    val scope = rememberCoroutineScope()
    var isFetching by remember { mutableStateOf(false) }

    fun fetchAndPlay(shuffled: Boolean, fetch: suspend () -> List<Playable>) {
        isFetching = true
        scope.launch {
            runCatching { fetch() }
                .onSuccess { app.actions.play(it, shuffled) }
                .onFailure { app.messages.showError() }
            isFetching = false
        }
    }

    PlayShuffleButtons(
        onPlay = {
            fetchAndPlay(shuffled = false) {
                val current = sort ?: SortSetting(app.core.playables.songSortField, app.core.playables.songSortOrder)
                app.core.playables.fetchInOrder(current.field, current.order)
            }
        },
        onShuffle = { fetchAndPlay(shuffled = true) { app.core.playables.fetchRandom() } },
        enabled = !isFetching,
    )
}
