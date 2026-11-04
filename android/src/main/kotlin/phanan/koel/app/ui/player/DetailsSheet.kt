package phanan.koel.app.ui.player

import androidx.compose.foundation.clickable
import androidx.compose.foundation.gestures.animateScrollBy
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.PaddingValues
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.Spacer
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.width
import androidx.compose.foundation.lazy.LazyColumn
import androidx.compose.foundation.lazy.itemsIndexed
import androidx.compose.foundation.lazy.rememberLazyListState
import androidx.compose.foundation.rememberScrollState
import androidx.compose.foundation.text.selection.SelectionContainer
import androidx.compose.foundation.verticalScroll
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.automirrored.outlined.Chat
import androidx.compose.material.icons.outlined.Info
import androidx.compose.material3.ExperimentalMaterial3Api
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.ModalBottomSheet
import androidx.compose.material3.SegmentedButton
import androidx.compose.material3.SegmentedButtonDefaults
import androidx.compose.material3.SingleChoiceSegmentedButtonRow
import androidx.compose.material3.Text
import androidx.compose.material3.rememberModalBottomSheetState
import androidx.compose.runtime.Composable
import androidx.compose.runtime.LaunchedEffect
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableIntStateOf
import androidx.compose.runtime.produceState
import androidx.compose.runtime.remember
import androidx.compose.runtime.saveable.rememberSaveable
import androidx.compose.runtime.setValue
import androidx.compose.ui.Modifier
import androidx.compose.animation.animateColorAsState
import androidx.compose.animation.core.FastOutSlowInEasing
import androidx.compose.animation.core.animateFloatAsState
import androidx.compose.animation.core.tween
import androidx.compose.ui.draw.BlurredEdgeTreatment
import androidx.compose.ui.draw.blur
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.graphics.TransformOrigin
import androidx.compose.ui.graphics.graphicsLayer
import androidx.compose.ui.text.AnnotatedString
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.text.fromHtml
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import androidx.lifecycle.compose.collectAsStateWithLifecycle
import phanan.koel.app.ui.LocalAppModel
import phanan.koel.app.ui.components.ContentUnavailable
import phanan.koel.app.ui.components.LoadingSpinner
import phanan.koel.app.ui.components.SheetTitle
import phanan.koel.app.ui.theme.KoelColors
import phanan.koel.shared.models.Episode
import phanan.koel.shared.models.Playable
import phanan.koel.shared.models.Song
import phanan.koel.shared.stores.AlbumInfo
import phanan.koel.app.ui.theme.LocalBrandColor
import phanan.koel.shared.util.LyricLine
import phanan.koel.shared.util.Lyrics

/**
 * Lyrics plus artist and album information for songs; the description for episodes. Opens half
 * way up and can be pulled to full height, like the iOS sheet's medium and large sizes.
 */
@OptIn(ExperimentalMaterial3Api::class)
@Composable
fun DetailsSheet(playable: Playable, onDismiss: () -> Unit) {
    ModalBottomSheet(
        onDismissRequest = onDismiss,
        sheetState = rememberModalBottomSheetState(skipPartiallyExpanded = false),
        containerColor = Color.Black,
    ) {
        Column(Modifier.fillMaxSize()) {
            SheetTitle(playable.title, Modifier.padding(horizontal = 48.dp))
            when (playable) {
                is Song -> SongDetails(playable)
                is Episode -> InfoScroll { HtmlText(playable.description) }
            }
        }
    }
}

private val Panes = listOf("Lyrics", "Artist", "Album")

@OptIn(ExperimentalMaterial3Api::class)
@Composable
private fun SongDetails(song: Song) {
    var pane by rememberSaveable { mutableIntStateOf(0) }
    val brandColor = LocalBrandColor.current

    SingleChoiceSegmentedButtonRow(Modifier.fillMaxWidth().padding(16.dp)) {
        Panes.forEachIndexed { index, title ->
            SegmentedButton(
                selected = pane == index,
                onClick = { pane = index },
                shape = SegmentedButtonDefaults.itemShape(index, Panes.size),
                icon = {},
                colors = SegmentedButtonDefaults.colors(
                    activeContainerColor = brandColor,
                    activeContentColor = Color.White,
                    activeBorderColor = Color.Transparent,
                    inactiveContainerColor = Color.White.copy(alpha = 0.08f),
                    inactiveContentColor = KoelColors.text,
                    inactiveBorderColor = Color.Transparent,
                ),
            ) { Text(title, fontWeight = FontWeight.Medium) }
        }
    }
    when (pane) {
        0 -> LyricsPane(song)
        1 -> ArtistPane(song)
        else -> AlbumPane(song)
    }
}

@Composable
private fun LyricsPane(song: Song) {
    when {
        song.lyrics.isBlank() -> ContentUnavailable("No lyrics available.", Icons.AutoMirrored.Outlined.Chat)
        Lyrics.isSynced(song.lyrics) -> SyncedLyrics(song, remember(song.lyrics) { Lyrics.parseSynced(song.lyrics) })
        else -> InfoScroll { HtmlText(song.lyrics.replace("\n", "<br>")) }
    }
}

/** Lines light up as the song plays and the current one stays centered; tapping one jumps there. */
@Composable
private fun SyncedLyrics(song: Song, lines: List<LyricLine>) {
    val app = LocalAppModel.current
    val state by app.core.player.state.collectAsStateWithLifecycle()
    val position by app.core.player.position.collectAsStateWithLifecycle()
    val isCurrent = state.current?.id == song.id
    val currentIndex = if (isCurrent) Lyrics.currentLineIndex(lines, position) else -1
    val listState = rememberLazyListState()
    val brandColor = LocalBrandColor.current

    LaunchedEffect(currentIndex) {
        if (currentIndex < 0) return@LaunchedEffect
        if (listState.layoutInfo.visibleItemsInfo.none { it.index == currentIndex }) listState.scrollToItem(currentIndex)
        val item = listState.layoutInfo.visibleItemsInfo.firstOrNull { it.index == currentIndex } ?: return@LaunchedEffect
        val viewportCenter = (listState.layoutInfo.viewportStartOffset + listState.layoutInfo.viewportEndOffset) / 2
        listState.animateScrollBy((item.offset + item.size / 2 - viewportCenter).toFloat())
    }

    LazyColumn(
        state = listState,
        modifier = Modifier.fillMaxSize(),
        contentPadding = PaddingValues(16.dp),
        verticalArrangement = Arrangement.spacedBy(20.dp),
    ) {
        itemsIndexed(lines) { index, line ->
            val look = Lyrics.lineLook(index, currentIndex)
            val opacity by animateFloatAsState(look.opacity.toFloat(), LyricTransition, label = "lyricOpacity")
            val blur by animateFloatAsState(look.blur.toFloat(), LyricTransition, label = "lyricBlur")
            val scale by animateFloatAsState(look.scale.toFloat(), LyricTransition, label = "lyricScale")
            val color by animateColorAsState(if (index == currentIndex) brandColor else Color.White, tween(450), label = "lyricColor")
            Text(
                line.text,
                style = MaterialTheme.typography.titleLarge.copy(fontSize = 24.sp, fontWeight = FontWeight.Bold),
                color = color,
                modifier = Modifier
                    .fillMaxWidth()
                    .clickable(enabled = isCurrent) { app.core.player.seek(line.time) }
                    .graphicsLayer {
                        alpha = opacity
                        scaleX = scale
                        scaleY = scale
                        transformOrigin = TransformOrigin(0f, 0.5f)
                    }
                    .blur(blur.dp, BlurredEdgeTreatment.Unbounded),
            )
        }
    }
}

private val LyricTransition = tween<Float>(durationMillis = 450, easing = FastOutSlowInEasing)

@Composable
private fun ArtistPane(song: Song) {
    val app = LocalAppModel.current
    val biography by produceState<Result<String>?>(null, song.artistId) {
        value = runCatching { app.core.mediaInfo.fetchForArtist(song.artistId).biography }
    }
    InfoPane(biography, emptyTitle = "No artist information available.", isEmpty = { it.isBlank() }) { HtmlText(it) }
}

@Composable
private fun AlbumPane(song: Song) {
    val app = LocalAppModel.current
    val info by produceState<Result<AlbumInfo>?>(null, song.albumId) {
        value = runCatching { app.core.mediaInfo.fetchForAlbum(song.albumId) }
    }
    InfoPane(info, emptyTitle = "No album information available.", isEmpty = { it.information.isBlank() && it.tracks.isEmpty() }) { album ->
        Column(verticalArrangement = Arrangement.spacedBy(20.dp)) {
            if (album.information.isNotBlank()) HtmlText(album.information)
            if (album.tracks.isNotEmpty()) {
                Column(verticalArrangement = Arrangement.spacedBy(8.dp)) {
                    Text("Tracks", style = MaterialTheme.typography.titleMedium.copy(fontSize = 17.sp, fontWeight = FontWeight.SemiBold))
                    val trackStyle = MaterialTheme.typography.bodyMedium.copy(fontSize = 15.sp, fontFeatureSettings = "tnum")
                    album.tracks.forEachIndexed { index, track ->
                        Row {
                            Text("${index + 1}", style = trackStyle, color = KoelColors.secondaryText, modifier = Modifier.width(28.dp))
                            Text(track.title, style = trackStyle, modifier = Modifier.weight(1f))
                            Spacer(Modifier.width(8.dp))
                            Text(track.length.toDouble().playbackTime, style = trackStyle, color = KoelColors.secondaryText)
                        }
                    }
                }
            }
        }
    }
}

@Composable
private fun <T> InfoPane(result: Result<T>?, emptyTitle: String, isEmpty: (T) -> Boolean, content: @Composable (T) -> Unit) {
    val value = result?.getOrNull()
    when {
        result == null -> LoadingSpinner(Modifier.fillMaxSize())
        value == null || isEmpty(value) -> ContentUnavailable(emptyTitle, Icons.Outlined.Info)
        else -> InfoScroll { content(value) }
    }
}

@Composable
private fun InfoScroll(content: @Composable () -> Unit) {
    Box(Modifier.fillMaxSize().verticalScroll(rememberScrollState()).padding(16.dp)) { content() }
}

/** Server HTML as selectable text with a little extra line spacing, like the iOS app's. */
@Composable
fun HtmlText(html: String, modifier: Modifier = Modifier) {
    val text = remember(html) { AnnotatedString.fromHtml(html) }
    val style = MaterialTheme.typography.bodyLarge
    SelectionContainer(modifier) {
        Text(text, style = style.copy(lineHeight = (style.fontSize.value * 1.2f + 4f).sp))
    }
}
