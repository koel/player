package phanan.koel.app.ui.components

import androidx.compose.animation.core.Animatable
import androidx.compose.animation.core.spring
import androidx.compose.foundation.background
import androidx.compose.foundation.clickable
import androidx.compose.foundation.gestures.detectHorizontalDragGestures
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.fillMaxHeight
import androidx.compose.foundation.layout.offset
import androidx.compose.foundation.layout.size
import androidx.compose.foundation.layout.width
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.automirrored.filled.PlaylistAdd
import androidx.compose.material.icons.automirrored.filled.PlaylistPlay
import androidx.compose.material.icons.automirrored.filled.QueueMusic
import androidx.compose.material.icons.filled.RemoveCircleOutline
import androidx.compose.material3.Icon
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.runtime.CompositionLocalProvider
import androidx.compose.runtime.compositionLocalOf
import androidx.compose.runtime.getValue
import androidx.compose.foundation.layout.BoxScope
import androidx.compose.runtime.mutableIntStateOf
import androidx.compose.runtime.remember
import androidx.compose.runtime.rememberCoroutineScope
import androidx.compose.runtime.setValue
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.clipToBounds
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.graphics.vector.ImageVector
import androidx.compose.ui.input.pointer.pointerInput
import androidx.compose.ui.layout.onSizeChanged
import androidx.compose.ui.platform.LocalDensity
import androidx.compose.ui.text.style.TextOverflow
import androidx.compose.ui.unit.IntOffset
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import kotlinx.coroutines.launch
import phanan.koel.app.ui.theme.KoelColors
import kotlin.math.abs
import kotlin.math.roundToInt

class SwipeAction(val label: String, val icon: ImageVector, val color: Color, val onClick: () -> Unit) {
    companion object {
        fun playNext(onClick: () -> Unit) = SwipeAction("Play Next", Icons.AutoMirrored.Filled.PlaylistPlay, KoelColors.playNextSwipe, onClick)
        fun playLast(onClick: () -> Unit) = SwipeAction("Play Last", Icons.AutoMirrored.Filled.QueueMusic, KoelColors.playLastSwipe, onClick)
        fun queue(onClick: () -> Unit) = SwipeAction("Queue", Icons.AutoMirrored.Filled.PlaylistAdd, KoelColors.queueSwipe, onClick)
        fun destructive(label: String, icon: ImageVector, onClick: () -> Unit) = SwipeAction(label, icon, KoelColors.destructiveSwipe, onClick)
    }
}

/** Where a released swipe ends up: closed, showing its buttons, or running its first action. */
enum class SwipeOutcome { Close, Reveal, Trigger }

object SwipeSettling {
    /** A swipe past this share of the row runs the side's first action, like a full swipe on iOS. */
    const val FULL_SWIPE_FRACTION = 0.55f

    fun outcome(distance: Float, revealWidth: Float, rowWidth: Float): SwipeOutcome = when {
        revealWidth <= 0f -> SwipeOutcome.Close
        abs(distance) >= rowWidth * FULL_SWIPE_FRACTION -> SwipeOutcome.Trigger
        abs(distance) >= revealWidth / 2 -> SwipeOutcome.Reveal
        else -> SwipeOutcome.Close
    }
}

private val ActionWidth = 76.dp

/**
 * iOS-style swipe actions: dragging the row reveals [leading] actions on the left and [trailing]
 * ones on the right; a long swipe runs the side's first action straight away.
 */
@Composable
fun SwipeActions(
    leading: List<SwipeAction> = emptyList(),
    trailing: List<SwipeAction> = emptyList(),
    content: @Composable () -> Unit,
) {
    if (leading.isEmpty() && trailing.isEmpty()) {
        content()
        return
    }
    val scope = rememberCoroutineScope()
    val offset = remember { Animatable(0f) }
    var rowWidth by remember { mutableIntStateOf(0) }
    val actionWidth = with(LocalDensity.current) { ActionWidth.toPx() }
    val leadingWidth = leading.size * actionWidth
    val trailingWidth = trailing.size * actionWidth

    fun settle(to: Float) = scope.launch { offset.animateTo(to, spring(dampingRatio = 0.85f)) }
    fun run(action: SwipeAction) {
        settle(0f)
        action.onClick()
    }

    Box(Modifier.clipToBounds().onSizeChanged { rowWidth = it.width }) {
        if (offset.value > 0f) ActionStrip(leading, Alignment.CenterStart, offset.value, ::run)
        if (offset.value < 0f) ActionStrip(trailing, Alignment.CenterEnd, -offset.value, ::run)

        Box(
            Modifier
                .offset { IntOffset(offset.value.roundToInt(), 0) }
                .pointerInput(leading.size, trailing.size, rowWidth) {
                    var dragged = 0f
                    detectHorizontalDragGestures(
                        onDragStart = { dragged = offset.value },
                        onDragEnd = {
                            val distance = dragged
                            val side = if (distance > 0) leading else trailing
                            val revealWidth = if (distance > 0) leadingWidth else trailingWidth
                            when (SwipeSettling.outcome(distance, revealWidth, rowWidth.toFloat())) {
                                SwipeOutcome.Trigger -> side.firstOrNull()?.let(::run) ?: settle(0f)
                                SwipeOutcome.Reveal -> settle(if (distance > 0) revealWidth else -revealWidth)
                                SwipeOutcome.Close -> settle(0f)
                            }
                        },
                        onDragCancel = { settle(0f) },
                    ) { change, dragAmount ->
                        change.consume()
                        val upper = if (leading.isEmpty()) 0f else rowWidth.toFloat()
                        val lower = if (trailing.isEmpty()) 0f else -rowWidth.toFloat()
                        dragged = (dragged + dragAmount).coerceIn(lower, upper)
                        scope.launch { offset.snapTo(dragged) }
                    }
                }
                .then(if (offset.value != 0f) Modifier.clickable { settle(0f) } else Modifier),
        ) { content() }
    }
}

@Composable
private fun BoxScope.ActionStrip(
    actions: List<SwipeAction>,
    alignment: Alignment,
    revealed: Float,
    onClick: (SwipeAction) -> Unit,
) {
    val revealedWidth = with(LocalDensity.current) { revealed.toDp() }
    Row(
        Modifier.matchParentSize(),
        horizontalArrangement = if (alignment == Alignment.CenterStart) Arrangement.Start else Arrangement.End,
    ) {
        val share = revealedWidth / actions.size
        val ordered = if (alignment == Alignment.CenterEnd) actions.reversed() else actions
        ordered.forEach { action ->
            Column(
                modifier = Modifier
                    .width(share)
                    .fillMaxHeight()
                    .background(action.color)
                    .clickable { onClick(action) },
                horizontalAlignment = Alignment.CenterHorizontally,
                verticalArrangement = Arrangement.Center,
            ) {
                Icon(action.icon, contentDescription = null, tint = Color.White, modifier = Modifier.size(22.dp))
                Text(
                    action.label,
                    color = Color.White,
                    style = MaterialTheme.typography.labelSmall.copy(fontSize = 12.sp),
                    maxLines = 1,
                    overflow = TextOverflow.Clip,
                )
            }
        }
    }
}

/** The destructive swipe a [SwipeToRemove] hands to the [PlayableRow] inside it. */
internal val LocalRowRemoval = compositionLocalOf<SwipeAction?> { null }

/**
 * Swipe the [PlayableRow] inside to take it out of the list it's in, like a queue or a playlist.
 * The row shows the action next to its own queue swipes.
 */
@Composable
fun SwipeToRemove(
    enabled: Boolean = true,
    onRemove: () -> Unit,
    label: String = "Remove",
    icon: ImageVector = Icons.Default.RemoveCircleOutline,
    content: @Composable () -> Unit,
) {
    val removal = if (enabled) SwipeAction.destructive(label, icon, onRemove) else null
    CompositionLocalProvider(LocalRowRemoval provides removal, content = content)
}
