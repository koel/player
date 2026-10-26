package phanan.koel.app.ui.collections

import androidx.compose.ui.graphics.lerp
import androidx.compose.ui.semantics.contentDescription
import androidx.compose.ui.semantics.semantics
import androidx.compose.foundation.background
import androidx.compose.foundation.clickable
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.ColumnScope
import androidx.compose.foundation.layout.PaddingValues
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.RowScope
import androidx.compose.foundation.layout.WindowInsets
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.height
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.size
import androidx.compose.foundation.layout.statusBars
import androidx.compose.foundation.lazy.LazyColumn
import androidx.compose.foundation.lazy.LazyListScope
import androidx.compose.foundation.lazy.rememberLazyListState
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.automirrored.filled.ArrowBack
import androidx.compose.material.icons.filled.PlayArrow
import androidx.compose.material.icons.filled.Shuffle
import androidx.compose.material3.Button
import androidx.compose.material3.ButtonDefaults
import androidx.compose.material3.ExperimentalMaterial3Api
import androidx.compose.material3.Icon
import androidx.compose.material3.IconButton
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.Scaffold
import androidx.compose.material3.Text
import androidx.compose.material3.TopAppBar
import androidx.compose.material3.TopAppBarDefaults
import androidx.compose.material3.pulltorefresh.PullToRefreshBox
import androidx.compose.runtime.Composable
import androidx.compose.runtime.CompositionLocalProvider
import androidx.compose.runtime.derivedStateOf
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.remember
import androidx.compose.runtime.rememberCoroutineScope
import androidx.compose.runtime.setValue
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.shadow
import androidx.compose.ui.graphics.Brush
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.graphics.compositeOver
import androidx.compose.ui.platform.LocalDensity
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.text.style.TextAlign
import androidx.compose.ui.text.style.TextOverflow
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import kotlinx.coroutines.launch
import phanan.koel.app.ui.LocalAppModel
import phanan.koel.app.ui.components.Artwork
import phanan.koel.app.ui.components.FailedState
import phanan.koel.app.ui.components.FavoriteIcon
import phanan.koel.app.ui.components.GlassCircle
import phanan.koel.app.ui.components.LoadingRows
import phanan.koel.app.ui.components.ScreenBottomPadding
import phanan.koel.app.ui.components.SortSetting
import phanan.koel.app.ui.library.SectionIndex
import phanan.koel.app.ui.library.SideIndex
import phanan.koel.app.ui.theme.KoelColors
import phanan.koel.shared.models.Playable
import phanan.koel.shared.models.PlayableSortField
import phanan.koel.shared.models.Playlist

class FavoriteToggle(val isFavorite: Boolean, val toggle: () -> Unit)

/**
 * The top of an album, playlist or podcast as on iOS: a large cover with a shadow, the title,
 * a subtitle in the cover's color, a detail line, then Favorite, Play and Shuffle. [accessory]
 * goes between the text and the buttons, like a podcast's description.
 */
@Composable
fun CollectionHeader(
    artworkUrl: String?,
    title: String,
    subtitle: String? = null,
    onSubtitleClick: (() -> Unit)? = null,
    detail: String? = null,
    favorite: FavoriteToggle? = null,
    canPlay: Boolean,
    onPlay: () -> Unit,
    onShuffle: () -> Unit,
    accessory: @Composable ColumnScope.() -> Unit = {},
) {
    val tint = LocalCoverTint.current?.takeIf { it.alpha > 0f }

    Column(
        modifier = Modifier.fillMaxWidth().padding(horizontal = 16.dp, vertical = 8.dp),
        horizontalAlignment = Alignment.CenterHorizontally,
        verticalArrangement = Arrangement.spacedBy(16.dp),
    ) {
        Artwork(
            artworkUrl,
            size = CoverSize,
            cornerRadius = 12.dp,
            modifier = Modifier.shadow(20.dp, RoundedCornerShape(12.dp), ambientColor = Color.Black.copy(alpha = 0.4f), spotColor = Color.Black.copy(alpha = 0.4f)),
        )
        Column(horizontalAlignment = Alignment.CenterHorizontally, verticalArrangement = Arrangement.spacedBy(4.dp)) {
            Text(
                title,
                style = MaterialTheme.typography.titleLarge.copy(fontSize = 22.sp, fontWeight = FontWeight.Bold),
                textAlign = TextAlign.Center,
            )
            subtitle?.let {
                Text(
                    it,
                    style = MaterialTheme.typography.titleMedium.copy(fontSize = 20.sp),
                    color = tint?.copy(alpha = 1f) ?: KoelColors.secondaryText,
                    textAlign = TextAlign.Center,
                    modifier = if (onSubtitleClick != null) Modifier.clickable(onClick = onSubtitleClick) else Modifier,
                )
            }
            detail?.let {
                Text(it, style = MaterialTheme.typography.bodySmall.copy(fontSize = 13.sp), color = KoelColors.secondaryText, textAlign = TextAlign.Center)
            }
        }
        accessory()
        CollectionActions(favorite, canPlay, onPlay, onShuffle)
    }
}

private val CoverSize = 260.dp

/** Favorite, Play and Shuffle under a collection's title; Play takes the cover's color. */
@Composable
fun CollectionActions(favorite: FavoriteToggle?, canPlay: Boolean, onPlay: () -> Unit, onShuffle: () -> Unit) {
    val tint = LocalCoverTint.current?.takeIf { it.alpha > 0f }
    val playColor = tint?.let { lerp(KoelColors.highlight, it.copy(alpha = 1f), it.alpha) } ?: KoelColors.highlight

    Row(verticalAlignment = Alignment.CenterVertically, horizontalArrangement = Arrangement.spacedBy(16.dp, Alignment.CenterHorizontally)) {
        if (favorite != null) {
            GlassCircle(48.dp, onClick = favorite.toggle, Modifier.semantics { contentDescription = if (favorite.isFavorite) "Undo Favorite" else "Favorite" }) {
                FavoriteIcon(favorite.isFavorite, size = 22.dp)
            }
        }
        Button(
            onClick = onPlay,
            enabled = canPlay,
            colors = ButtonDefaults.buttonColors(containerColor = playColor, contentColor = Color.White),
            contentPadding = PaddingValues(horizontal = 36.dp),
            modifier = Modifier.height(48.dp),
        ) {
            Icon(Icons.Default.PlayArrow, contentDescription = null, modifier = Modifier.size(ButtonDefaults.IconSize))
            Text("Play", fontWeight = FontWeight.SemiBold, fontSize = 16.sp, modifier = Modifier.padding(start = ButtonDefaults.IconSpacing))
        }
        GlassCircle(48.dp, onClick = onShuffle, Modifier.semantics { contentDescription = "Shuffle" }, enabled = canPlay) {
            Icon(Icons.Default.Shuffle, contentDescription = null, modifier = Modifier.size(22.dp))
        }
    }
}

/**
 * A collection screen: the header scrolls with the list, and the app bar shows the title once
 * the header has scrolled away. Pull down to [onRefresh]. While the collection itself
 * [isLoading], placeholder rows show, or a failure with Retry when it [hasFailed].
 * With [isHeroUnderBar], the header runs under the app bar, which stays clear, as on the iOS
 * artist screen. With [songIndex], the side letter index runs down the list.
 */
@OptIn(ExperimentalMaterial3Api::class)
@Composable
fun CollectionScreen(
    title: String,
    isLoading: Boolean,
    coverUrl: String?,
    isHeroUnderBar: Boolean = false,
    hasFailed: Boolean = false,
    onRetry: () -> Unit = {},
    onRefresh: (suspend () -> Unit)? = null,
    actions: @Composable RowScope.() -> Unit = {},
    songIndex: SongIndex? = null,
    content: LazyListScope.() -> Unit,
) {
    val navigator = LocalAppModel.current.navigator
    val scope = rememberCoroutineScope()
    val listState = rememberLazyListState()
    val density = LocalDensity.current
    val barBottom = WindowInsets.statusBars.getTop(density) + with(density) { TopAppBarDefaults.TopAppBarExpandedHeight.roundToPx() }
    val actionsHeight = with(density) { 72.dp.roundToPx() }
    val isHeaderScrolledAway by remember(barBottom) {
        derivedStateOf {
            val header = listState.layoutInfo.visibleItemsInfo.firstOrNull { it.index == 0 } ?: return@derivedStateOf true
            val headerBottom = (if (isHeroUnderBar) 0 else barBottom) + header.size - listState.firstVisibleItemScrollOffset
            headerBottom < barBottom + actionsHeight
        }
    }
    val coverColor by rememberCoverColor(coverUrl)
    var isRefreshing by remember { mutableStateOf(false) }
    val barColor = when {
        isHeroUnderBar -> Color.Transparent
        isHeaderScrolledAway -> MaterialTheme.colorScheme.surfaceContainer.compositeOver(coverColor)
        else -> Color.Transparent
    }

    Box(Modifier.fillMaxSize()) {
        CoverBackground(coverColor)
        CompositionLocalProvider(LocalCoverTint provides coverColor) {
            Scaffold(
                contentWindowInsets = WindowInsets(0),
                containerColor = Color.Transparent,
                topBar = {
                    Box {
                        if (isHeroUnderBar) {
                            Box(
                                Modifier
                                    .matchParentSize()
                                    .background(Brush.verticalGradient(listOf(Color.Black.copy(alpha = 0.45f), Color.Transparent))),
                            )
                        }
                        TopAppBar(
                            title = { if (isHeaderScrolledAway) Text(title, maxLines = 1, overflow = TextOverflow.Ellipsis) },
                            navigationIcon = {
                                IconButton(onClick = { navigator.pop() }) {
                                    Icon(Icons.AutoMirrored.Filled.ArrowBack, contentDescription = "Back")
                                }
                            },
                            actions = actions,
                            colors = TopAppBarDefaults.topAppBarColors(containerColor = barColor),
                        )
                    }
                },
            ) { padding ->
                val topPadding = if (isHeroUnderBar && !isLoading) 0.dp else padding.calculateTopPadding()
                when {
                    isLoading && hasFailed -> Box(Modifier.fillMaxSize(), contentAlignment = Alignment.Center) {
                        FailedState(onRetry)
                    }
                    isLoading -> Column(Modifier.padding(top = topPadding)) { LoadingRows() }
                    else -> {
                        val list = @Composable {
                            Box(Modifier.fillMaxSize()) {
                                LazyColumn(
                                    state = listState,
                                    contentPadding = PaddingValues(top = topPadding, bottom = ScreenBottomPadding),
                                    modifier = Modifier.fillMaxSize(),
                                    content = content,
                                )
                                songIndex?.let { index ->
                                    SideIndex(index.songs, Playable::title) { position -> listState.scrollToItem(index.firstRow + position) }
                                }
                            }
                        }
                        if (onRefresh == null) {
                            list()
                        } else {
                            PullToRefreshBox(
                                isRefreshing = isRefreshing,
                                onRefresh = {
                                    scope.launch {
                                        isRefreshing = true
                                        try {
                                            onRefresh()
                                        } finally {
                                            isRefreshing = false
                                        }
                                    }
                                },
                                modifier = Modifier.fillMaxSize(),
                            ) { list() }
                        }
                    }
                }
            }
        }
    }
}

/** The songs a collection's side index covers, and the list position of the first one. */
class SongIndex(val songs: List<Playable>, val firstRow: Int) {
    companion object {
        private const val HEADER_AND_FILTER_ROWS = 2

        /** Shown under the same rules as every other indexed list. */
        fun ifSortedByTitle(songs: List<Playable>, sort: SortSetting): SongIndex? =
            if (SectionIndex.isShown(songs.size, sort.field == PlayableSortField.TITLE)) SongIndex(songs, HEADER_AND_FILTER_ROWS) else null
    }
}

/** "2019 · 12 songs · 48 min", skipping whatever is unknown. */
fun collectionDetail(year: Int? = null, songCount: Int, totalSeconds: Double): String? {
    val yearLabel = year?.toString()
    if (songCount == 0) return yearLabel
    return listOfNotNull(yearLabel, pluralized(songCount, "song"), totalLength(totalSeconds)).joinToString(" · ")
}

/** "Standard playlist • 12 songs • 48 min", or just the kind while it has no songs, as on iOS. */
fun playlistDetail(playlist: Playlist, songCount: Int, totalSeconds: Double): String {
    if (songCount == 0) return playlist.kindLabel
    return "${playlist.kindLabel} • ${pluralized(songCount, "song")} • ${totalLength(totalSeconds)}"
}

fun pluralized(count: Int, singular: String): String = "$count ${if (count == 1) singular else "${singular}s"}"

private fun totalLength(seconds: Double): String {
    val minutes = (seconds / 60).toInt()
    return if (minutes >= 60) "${minutes / 60} hr ${minutes % 60} min" else "$minutes min"
}
