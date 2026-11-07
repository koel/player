package phanan.koel.app.ui.player

import android.os.Build
import androidx.compose.animation.Crossfade
import androidx.compose.animation.core.animateFloatAsState
import androidx.compose.animation.core.spring
import androidx.compose.animation.core.tween
import androidx.compose.foundation.background
import androidx.compose.foundation.border
import androidx.compose.foundation.clickable
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.BoxWithConstraints
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.PaddingValues
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.Spacer
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.height
import androidx.compose.foundation.layout.heightIn
import androidx.compose.foundation.layout.navigationBarsPadding
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.size
import androidx.compose.foundation.lazy.LazyColumn
import androidx.compose.foundation.lazy.items
import androidx.compose.foundation.lazy.rememberLazyListState
import androidx.compose.foundation.pager.HorizontalPager
import androidx.compose.foundation.pager.rememberPagerState
import androidx.compose.foundation.shape.CircleShape
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.automirrored.outlined.Chat
import androidx.compose.material.icons.filled.FastForward
import androidx.compose.material.icons.filled.FastRewind
import androidx.compose.material.icons.filled.Menu
import androidx.compose.material.icons.filled.MoreHoriz
import androidx.compose.material.icons.filled.Repeat
import androidx.compose.material.icons.filled.RepeatOne
import androidx.compose.material.icons.filled.Sensors
import androidx.compose.material.icons.filled.SpeakerGroup
import androidx.compose.material3.ExperimentalMaterial3Api
import androidx.compose.material3.Icon
import androidx.compose.material3.IconButton
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.ModalBottomSheet
import androidx.compose.material3.Text
import androidx.compose.material3.rememberModalBottomSheetState
import androidx.compose.runtime.Composable
import androidx.compose.runtime.LaunchedEffect
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.produceState
import androidx.compose.runtime.remember
import androidx.compose.runtime.setValue
import androidx.compose.runtime.snapshotFlow
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.blur
import androidx.compose.ui.draw.shadow
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.graphics.FilterQuality
import androidx.compose.ui.graphics.graphicsLayer
import androidx.compose.ui.graphics.vector.ImageVector
import androidx.compose.ui.layout.ContentScale
import androidx.compose.ui.layout.layout
import androidx.compose.ui.platform.LocalConfiguration
import androidx.compose.ui.platform.LocalContext
import androidx.compose.ui.res.painterResource
import androidx.compose.ui.semantics.contentDescription
import androidx.compose.ui.semantics.semantics
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.unit.Dp
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import androidx.lifecycle.compose.collectAsStateWithLifecycle
import coil3.compose.AsyncImage
import coil3.request.ImageRequest
import kotlinx.coroutines.flow.drop
import phanan.koel.app.AppSheet
import phanan.koel.app.R
import phanan.koel.app.ui.LocalAppModel
import phanan.koel.app.ui.components.Artwork
import phanan.koel.app.ui.components.DownloadButton
import phanan.koel.app.ui.components.FavoriteIcon
import phanan.koel.app.ui.components.GlassCircle
import phanan.koel.app.ui.components.PlayPauseIcon
import phanan.koel.app.ui.components.PlayableRow
import phanan.koel.app.ui.components.PlayableRowStyle
import phanan.koel.app.ui.components.SectionClearButton
import phanan.koel.app.ui.components.SectionTitle
import phanan.koel.app.ui.components.SheetDragHandle
import phanan.koel.app.ui.components.SwipeToRemove
import phanan.koel.app.ui.components.ToastHost
import phanan.koel.app.ui.components.ToastSpacing
import phanan.koel.app.ui.theme.KoelColors
import phanan.koel.app.ui.theme.LocalBrandColor
import phanan.koel.shared.models.Playable
import phanan.koel.shared.models.Song
import phanan.koel.shared.player.PlaybackState
import phanan.koel.shared.player.RepeatMode
import sh.calvin.reorderable.ReorderableItem
import sh.calvin.reorderable.rememberReorderableLazyListState
import kotlin.math.abs

/** How much of the queue's heading shows below the player, hinting that it scrolls. */
private val QueuePeek = 56.dp

/** The full player, with the queue below it. */
@OptIn(ExperimentalMaterial3Api::class)
@Composable
fun NowPlayingSheet(onDismiss: () -> Unit) {
    val app = LocalAppModel.current
    val state by app.core.player.state.collectAsStateWithLifecycle()
    val sheetState = rememberModalBottomSheetState(skipPartiallyExpanded = true)
    val listState = rememberLazyListState()
    val playerHeight = LocalConfiguration.current.screenHeightDp.dp - QueuePeek

    val queue = state.queue
    val reorderState = rememberReorderableLazyListState(listState) { from, to ->
        val fromIndex = queue.indexOfFirst { it.id == from.key }
        val toIndex = queue.indexOfFirst { it.id == to.key }
        val insertionIndex = if (fromIndex < toIndex) toIndex + 1 else toIndex
        if (fromIndex >= 0 && toIndex >= 0) app.core.player.move(fromIndex, insertionIndex)
    }

    LaunchedEffect(state.hasFailed) {
        if (state.hasFailed) app.messages.showError("Couldn't play this item")
    }

    ModalBottomSheet(
        onDismissRequest = onDismiss,
        sheetState = sheetState,
        containerColor = Color.Black,
        dragHandle = null,
    ) {
        Box(Modifier.fillMaxSize()) {
            CoverBackdrop(state.radioStation?.logo ?: state.current?.artworkUrl)
            LazyColumn(state = listState, modifier = Modifier.fillMaxSize()) {
                item(key = "player") {
                    Player(state, Modifier.height(if (queue.isEmpty()) playerHeight + QueuePeek else playerHeight))
                }
                if (queue.isNotEmpty()) {
                    item(key = "queue-heading") {
                        SectionTitle("Queued") { SectionClearButton { app.core.player.clearQueue() } }
                    }
                    items(queue, key = { it.id }) { playable ->
                        ReorderableItem(reorderState, key = playable.id) {
                            SwipeToRemove(onRemove = { app.actions.removeFromQueue(playable) }) {
                                PlayableRow(
                                    playable,
                                    style = PlayableRowStyle.Queue,
                                    trailing = {
                                        Box(
                                            Modifier.size(32.dp).draggableHandle().semantics { contentDescription = "Reorder" },
                                            contentAlignment = Alignment.Center,
                                        ) {
                                            Icon(Icons.Default.Menu, contentDescription = null, tint = KoelColors.secondaryText, modifier = Modifier.size(20.dp))
                                        }
                                    },
                                )
                            }
                        }
                    }
                }
            }
            ToastHost(app.messages, Modifier.navigationBarsPadding().padding(bottom = ToastSpacing.bottom))
        }
    }
}

@Composable
private fun Player(state: PlaybackState, modifier: Modifier) {
    val current = state.current
    val station = state.radioStation

    Column(
        modifier = modifier.fillMaxWidth().padding(horizontal = 28.dp).padding(top = 8.dp, bottom = 12.dp),
        horizontalAlignment = Alignment.CenterHorizontally,
    ) {
        SheetDragHandle()
        Spacer(Modifier.weight(1f).heightIn(min = 16.dp))
        if (station != null) {
            PlayingArtwork(station.logo, isCurrent = true, isPlaying = state.isPlaying)
        } else {
            QueueArtworkCarousel(state, Modifier.bleed(28.dp))
        }
        Spacer(Modifier.weight(1f).heightIn(min = 24.dp))

        TitleRow(state)
        Spacer(Modifier.height(20.dp))

        if (station != null) {
            Row(verticalAlignment = Alignment.CenterVertically) {
                Icon(Icons.Default.Sensors, contentDescription = null, tint = KoelColors.secondaryText, modifier = Modifier.size(16.dp))
                Text("Live", style = MaterialTheme.typography.labelLarge.copy(fontWeight = FontWeight.SemiBold), color = KoelColors.secondaryText, modifier = Modifier.padding(start = 6.dp))
            }
            Spacer(Modifier.height(20.dp))
        } else if (current != null) {
            Progress(current, state.isPlaying)
            Spacer(Modifier.height(16.dp))
        }

        TransportControls(state)
        Spacer(Modifier.height(24.dp))
        SystemVolumeSlider()
        Spacer(Modifier.height(16.dp))
        BottomBar(state)
    }
}

@Composable
private fun TitleRow(state: PlaybackState) {
    val app = LocalAppModel.current
    val current = state.current
    val station = state.radioStation
    val brandColor = LocalBrandColor.current

    Row(verticalAlignment = Alignment.CenterVertically, horizontalArrangement = Arrangement.spacedBy(8.dp)) {
        Column(Modifier.weight(1f), verticalArrangement = Arrangement.spacedBy(4.dp)) {
            MarqueeText(
                station?.let { state.radioStreamTitle ?: it.name } ?: current?.title.orEmpty(),
                style = MaterialTheme.typography.titleLarge.copy(fontSize = 20.sp, fontWeight = FontWeight.Bold),
                color = Color.White,
            )
            val subtitle = station?.let { if (state.radioStreamTitle == null) null else it.name } ?: current?.subtitle
            subtitle?.let {
                MarqueeText(
                    it,
                    style = MaterialTheme.typography.bodyLarge.copy(fontSize = 17.sp),
                    color = KoelColors.secondaryText,
                    modifier = Modifier.clickable(enabled = current != null && station == null && !app.isOffline) {
                        current?.let { playable ->
                            app.isNowPlayingShown = false
                            app.actions.goToArtist(playable)
                        }
                    },
                )
            }
        }
        if (current != null && station == null) {
            IconButton(onClick = { app.actions.toggleFavorite(current) }, enabled = !app.isOffline) {
                FavoriteIcon(
                    current.favorite,
                    size = 26.dp,
                    tint = if (current.favorite) brandColor else Color.White,
                    contentDescription = if (current.favorite) "Undo Favorite" else "Favorite",
                )
            }
            DownloadButton(current)
            IconButton(onClick = { app.sheet = AppSheet.Actions(current) }) {
                Box(
                    Modifier.size(26.dp).border(1.5.dp, Color.White, CircleShape),
                    contentAlignment = Alignment.Center,
                ) {
                    Icon(Icons.Default.MoreHoriz, contentDescription = "More", tint = Color.White, modifier = Modifier.size(18.dp))
                }
            }
        }
    }
}

@Composable
private fun TransportControls(state: PlaybackState) {
    val app = LocalAppModel.current
    val isRadio = state.isRadioMode

    Row(
        modifier = Modifier.fillMaxWidth().padding(horizontal = 24.dp),
        horizontalArrangement = if (isRadio) Arrangement.Center else Arrangement.SpaceBetween,
        verticalAlignment = Alignment.CenterVertically,
    ) {
        if (!isRadio) TransportButton(Icons.Default.FastRewind, "Previous") { app.core.player.skipToPrevious() }
        GlassCircle(84.dp, onClick = { app.core.player.togglePlayPause() }, Modifier.semantics { contentDescription = if (state.isPlaying) "Pause" else "Play" }) {
            PlayPauseIcon(state.isPlaying, size = 36.dp)
        }
        if (!isRadio) TransportButton(Icons.Default.FastForward, "Next") { app.core.player.skipToNext() }
    }
}

@Composable
private fun TransportButton(icon: ImageVector, label: String, onClick: () -> Unit) {
    IconButton(onClick = onClick, modifier = Modifier.size(56.dp)) {
        Icon(icon, contentDescription = label, tint = Color.White, modifier = Modifier.size(40.dp))
    }
}

/** Playback settings, the output switcher, lyrics and details, and repeat, spread across the bottom. */
@Composable
private fun BottomBar(state: PlaybackState) {
    val app = LocalAppModel.current
    val context = LocalContext.current
    val current = state.current

    Row(Modifier.fillMaxWidth(), horizontalArrangement = Arrangement.SpaceBetween, verticalAlignment = Alignment.CenterVertically) {
        IconButton(onClick = { app.sheet = AppSheet.PlaybackSettings }) {
            Icon(PlaybackSettingsEntry.icon, contentDescription = PlaybackSettingsEntry.LABEL, tint = KoelColors.secondaryText)
        }
        IconButton(onClick = { showOutputSwitcher(context) }) {
            Icon(Icons.Default.SpeakerGroup, contentDescription = "Choose Output", tint = KoelColors.secondaryText)
        }
        if (current != null && !state.isRadioMode) {
            IconButton(onClick = { app.sheet = AppSheet.Details(current) }) {
                Icon(Icons.AutoMirrored.Outlined.Chat, contentDescription = "Lyrics and Details", tint = KoelColors.secondaryText)
            }
        } else {
            Spacer(Modifier.size(BottomBarButtonSize))
        }
        if (!state.isRadioMode) RepeatButton(state.repeatMode) else Spacer(Modifier.size(BottomBarButtonSize))
    }
}

private val BottomBarButtonSize = 48.dp

/** A cover that shrinks a little while paused, like the iOS player. */
@Composable
private fun PlayingArtwork(url: String?, isCurrent: Boolean, isPlaying: Boolean, modifier: Modifier = Modifier) {
    val scale by animateFloatAsState(if (isPlaying) 1f else 0.86f, spring(dampingRatio = 0.6f, stiffness = 300f), label = "artworkScale")
    Artwork(
        url,
        cornerRadius = 14.dp,
        modifier = modifier
            .size(ArtworkSize)
            .graphicsLayer {
                scaleX = scale
                scaleY = scale
            }
            .shadow(if (isCurrent) 30.dp else 12.dp, RoundedCornerShape(14.dp), ambientColor = Color.Black, spotColor = Color.Black),
    )
}

private val ArtworkSize = 320.dp

/** Lets content reach past the parent's side padding, so neighbor covers peek from the screen edges. */
private fun Modifier.bleed(horizontal: Dp) = layout { measurable, constraints ->
    val extra = horizontal.roundToPx() * 2
    val placeable = measurable.measure(constraints.copy(minWidth = constraints.maxWidth + extra, maxWidth = constraints.maxWidth + extra))
    layout(constraints.maxWidth, placeable.height) { placeable.place(-extra / 2, 0) }
}

/** The current cover with the previous and next ones peeking at the edges. Swiping to a neighbor plays it. */
@Composable
private fun QueueArtworkCarousel(state: PlaybackState, modifier: Modifier = Modifier) {
    val app = LocalAppModel.current
    val queue = state.queue
    val currentIndex = state.currentIndex.coerceIn(0, (queue.size - 1).coerceAtLeast(0))
    val pagerState = rememberPagerState(initialPage = currentIndex) { queue.size.coerceAtLeast(1) }

    LaunchedEffect(currentIndex) {
        if (pagerState.currentPage != currentIndex) pagerState.animateScrollToPage(currentIndex)
    }
    LaunchedEffect(pagerState) {
        snapshotFlow { pagerState.settledPage }.drop(1).collect { page ->
            val latest = app.core.player.state.value
            val isCurrentQueued = latest.currentIndex >= 0
            if (isCurrentQueued && page != latest.currentIndex) latest.queue.getOrNull(page)?.let(app.core.player::play)
        }
    }

    BoxWithConstraints(modifier.fillMaxWidth()) {
        val sidePadding = ((maxWidth - ArtworkSize) / 2).coerceAtLeast(0.dp)
        HorizontalPager(
            state = pagerState,
            contentPadding = PaddingValues(horizontal = sidePadding),
            pageSpacing = (-28).dp,
            beyondViewportPageCount = 1,
            key = { page -> queue.getOrNull(page)?.id ?: page },
        ) { page ->
            val offset = abs(pagerState.currentPage - page + pagerState.currentPageOffsetFraction).coerceIn(0f, 1f)
            Box(
                Modifier.graphicsLayer {
                    val scale = 1f - 0.3f * offset
                    scaleX = scale
                    scaleY = scale
                },
            ) {
                PlayingArtwork(queue.getOrNull(page)?.artworkUrl ?: state.current?.artworkUrl, isCurrent = page == currentIndex, isPlaying = state.isPlaying)
                Box(Modifier.matchParentSize().background(Color.Black.copy(alpha = 0.4f * offset), RoundedCornerShape(14.dp)))
            }
        }
    }
}

@Composable
private fun RepeatButton(mode: RepeatMode) {
    val app = LocalAppModel.current
    IconButton(onClick = { app.core.player.rotateRepeatMode() }) {
        Icon(
            if (mode == RepeatMode.ONE) Icons.Default.RepeatOne else Icons.Default.Repeat,
            contentDescription = "Repeat: ${repeatLabel(mode)}",
            tint = if (mode == RepeatMode.NONE) KoelColors.secondaryText else LocalBrandColor.current,
        )
    }
}

/** How iOS names the repeat modes to VoiceOver. */
fun repeatLabel(mode: RepeatMode): String = when (mode) {
    RepeatMode.ALL -> "All"
    RepeatMode.ONE -> "One"
    else -> "Off"
}

@Composable
private fun Progress(current: Playable, isPlaying: Boolean) {
    val app = LocalAppModel.current
    val position by app.core.player.position.collectAsStateWithLifecycle()
    var scrubbing by remember { mutableStateOf<Double?>(null) }
    val length = current.length.coerceAtLeast(1.0)
    val shown = scrubbing ?: position
    val waveform by produceState(emptyList<Double>(), current.id) {
        value = emptyList()
        if (current is Song) value = runCatching { app.core.mediaInfo.fetchWaveform(current.id) }.getOrDefault(emptyList())
    }

    Column(Modifier.fillMaxWidth(), verticalArrangement = Arrangement.spacedBy(4.dp)) {
        PlaybackScrubber(
            position = shown.coerceAtMost(length),
            length = length,
            waveform = waveform,
            isPlaying = isPlaying,
            accent = LocalBrandColor.current,
            onScrub = { scrubbing = it },
            onCommit = {
                app.core.player.seek(it)
                scrubbing = null
            },
        )
        Row(Modifier.fillMaxWidth()) {
            val timeStyle = MaterialTheme.typography.labelMedium.copy(fontSize = 12.sp, fontFeatureSettings = "tnum")
            Text(shown.playbackTime, style = timeStyle, color = KoelColors.secondaryText)
            Spacer(Modifier.weight(1f))
            Text("-" + (length - shown).coerceAtLeast(0.0).playbackTime, style = timeStyle, color = KoelColors.secondaryText)
        }
    }
}

/**
 * The cover, blurred across the whole sheet and drawn larger than the screen so the blur's faded
 * edges stay off it; a new cover fades in over 0.6 s. Before Android 12, which can't blur, a
 * tiny copy of the cover stretched across the screen gives the same soft wash.
 */
@Composable
private fun CoverBackdrop(url: String?) {
    val context = LocalContext.current
    Crossfade(url, animationSpec = tween(600), label = "backdrop") { coverUrl ->
        Box(Modifier.fillMaxSize()) {
            val placeholder = painterResource(R.drawable.default_cover)
            val remote = coverUrl?.takeIf { it.isNotBlank() }
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.S) {
                AsyncImage(
                    model = remote,
                    contentDescription = null,
                    placeholder = placeholder,
                    error = placeholder,
                    contentScale = ContentScale.Crop,
                    modifier = Modifier
                        .fillMaxSize()
                        .graphicsLayer {
                            scaleX = 1.6f
                            scaleY = 1.6f
                        }
                        .blur(70.dp),
                )
            } else {
                AsyncImage(
                    model = ImageRequest.Builder(context).data(remote).size(12).build(),
                    contentDescription = null,
                    placeholder = placeholder,
                    error = placeholder,
                    contentScale = ContentScale.Crop,
                    filterQuality = FilterQuality.High,
                    modifier = Modifier.fillMaxSize(),
                )
            }
            Box(Modifier.fillMaxSize().background(Color.Black.copy(alpha = 0.4f)))
        }
    }
}

/** "3:07", or "1:02:45" past an hour. */
val Double.playbackTime: String
    get() {
        val total = toInt().coerceAtLeast(0)
        val hours = total / 3600
        val minutes = (total % 3600) / 60
        val seconds = total % 60
        return if (hours > 0) "%d:%02d:%02d".format(hours, minutes, seconds) else "%d:%02d".format(minutes, seconds)
    }
