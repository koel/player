package phanan.koel.app.ui.components

import androidx.compose.foundation.ExperimentalFoundationApi
import androidx.compose.foundation.clickable
import androidx.compose.foundation.combinedClickable
import androidx.compose.foundation.gestures.snapping.SnapPosition
import androidx.compose.foundation.gestures.snapping.rememberSnapFlingBehavior
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Column
import phanan.koel.shared.models.Playable
import androidx.compose.foundation.layout.PaddingValues
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.Spacer
import androidx.compose.foundation.layout.aspectRatio
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.height
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.size
import androidx.compose.foundation.layout.width
import androidx.compose.foundation.lazy.LazyRow
import androidx.compose.foundation.lazy.items
import androidx.compose.foundation.lazy.rememberLazyListState
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.automirrored.filled.ArrowForwardIos
import androidx.compose.material3.Icon
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.Text
import androidx.compose.material3.TextButton
import androidx.compose.runtime.Composable
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.semantics.Role
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.text.style.TextOverflow
import androidx.compose.ui.unit.Dp
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import phanan.koel.app.ui.theme.KoelColors

/**
 * Square artwork with two lines below, for album, artist and podcast grids and carousels.
 * With a null [size] the card fills the width it's given, as grid cells do.
 */
@OptIn(ExperimentalFoundationApi::class)
@Composable
fun ArtworkCard(
    artworkUrl: String?,
    title: String,
    modifier: Modifier = Modifier,
    subtitle: String? = null,
    size: Dp? = 144.dp,
    isCircular: Boolean = false,
    onLongClick: (() -> Unit)? = null,
    onClick: () -> Unit,
) {
    Column(
        modifier = modifier
            .then(if (size != null) Modifier.width(size) else Modifier.fillMaxWidth())
            .combinedClickable(onClick = onClick, onLongClick = onLongClick),
        horizontalAlignment = if (isCircular) Alignment.CenterHorizontally else Alignment.Start,
    ) {
        Artwork(
            artworkUrl,
            size = size,
            cornerRadius = 10.dp,
            isCircle = isCircular,
            modifier = if (size == null) Modifier.fillMaxWidth().aspectRatio(1f) else Modifier,
        )
        Spacer(Modifier.height(6.dp))
        Text(title, style = MaterialTheme.typography.bodyMedium.copy(fontSize = 15.sp), maxLines = 1, overflow = TextOverflow.Ellipsis)
        subtitle?.let {
            Spacer(Modifier.height(1.dp))
            Text(
                it,
                style = MaterialTheme.typography.bodySmall.copy(fontSize = 13.sp),
                color = KoelColors.secondaryText,
                maxLines = 1,
                overflow = TextOverflow.Ellipsis,
            )
        }
    }
}

/** A heading over song rows, like Search's songs and the New tab's New Songs. */
@Composable
fun PlayableSection(title: String, playables: List<Playable>, onShowAll: () -> Unit) {
    Column {
        SectionTitle(title, Modifier.padding(bottom = SectionGapAboveRows), onShowAll = onShowAll)
        playables.forEach { PlayableRow(it, hasQueueSwipes = false) }
    }
}

/** A titled, horizontally scrolling row that snaps to its cards, like the shelves on Home. */
@Composable
fun <T> Shelf(
    title: String,
    items: List<T>,
    key: (T) -> Any,
    onShowAll: (() -> Unit)? = null,
    content: @Composable (T) -> Unit,
) {
    if (items.isEmpty()) return
    val listState = rememberLazyListState()
    Column(Modifier.fillMaxWidth(), verticalArrangement = Arrangement.spacedBy(SectionContentGap)) {
        SectionTitle(title, onShowAll = onShowAll)
        LazyRow(
            state = listState,
            flingBehavior = rememberSnapFlingBehavior(listState, SnapPosition.Start),
            contentPadding = PaddingValues(horizontal = 16.dp),
            horizontalArrangement = Arrangement.spacedBy(16.dp),
        ) {
            items(items, key = key) { content(it) }
        }
    }
}

/** From a section heading to the top of the content below it, whether cards, rows or text. */
val SectionContentGap = 16.dp

/** Between one section of a screen and the next. */
val SectionSpacing = 32.dp

/** Space to leave under a heading when rows follow, since rows already pad their own top. */
val SectionGapAboveRows = SectionContentGap - PlayableRowVerticalPadding

/**
 * The one section heading used across the app. The screen decides the gaps around it.
 * With [onShowAll], a small chevron follows it and the two open the full list. [trailing] sits at
 * the far end, like the queue's Clear button.
 */
@Composable
fun SectionTitle(
    title: String,
    modifier: Modifier = Modifier,
    onShowAll: (() -> Unit)? = null,
    trailing: (@Composable () -> Unit)? = null,
) {
    Row(modifier.fillMaxWidth().padding(horizontal = 16.dp), verticalAlignment = Alignment.CenterVertically) {
        Row(
            modifier = if (onShowAll != null) Modifier.clickable(role = Role.Button, onClickLabel = "Show All", onClick = onShowAll) else Modifier,
            verticalAlignment = Alignment.CenterVertically,
            horizontalArrangement = Arrangement.spacedBy(4.dp),
        ) {
            Text(title, style = MaterialTheme.typography.titleLarge.copy(fontSize = 20.sp, fontWeight = FontWeight.Bold))
            if (onShowAll != null) {
                Icon(
                    Icons.AutoMirrored.Filled.ArrowForwardIos,
                    contentDescription = null,
                    tint = KoelColors.secondaryText,
                    modifier = Modifier.size(13.dp),
                )
            }
        }
        if (trailing != null) {
            Spacer(Modifier.weight(1f))
            trailing()
        }
    }
}

/** Empties the list under a section title, like the queue. */
@Composable
fun SectionClearButton(onClick: () -> Unit) {
    TextButton(onClick = onClick) {
        Text("Clear", color = KoelColors.destructiveSwipe, fontSize = 17.sp)
    }
}
