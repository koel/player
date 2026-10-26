package phanan.koel.app.ui.library

import androidx.compose.foundation.gestures.awaitEachGesture
import androidx.compose.foundation.gestures.awaitFirstDown
import androidx.compose.foundation.layout.BoxScope
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.size
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.remember
import androidx.compose.runtime.rememberCoroutineScope
import androidx.compose.runtime.rememberUpdatedState
import androidx.compose.runtime.setValue
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.hapticfeedback.HapticFeedbackType
import androidx.compose.ui.input.pointer.pointerInput
import androidx.compose.ui.platform.LocalHapticFeedback
import androidx.compose.ui.semantics.contentDescription
import androidx.compose.ui.semantics.semantics
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.text.style.TextAlign
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import kotlinx.coroutines.launch
import phanan.koel.app.ui.theme.LocalBrandColor

private val LetterHeight = 15.dp

/** How wide the bar is; indexed lists leave this much room at their end so it doesn't cover them. */
val AlphabetIndexBarWidth = 16.dp
private val BarPadding = 4.dp

/** The letter under a finger [offset] pixels down the bar, holding at the ends when it slides past them. */
fun letterIndex(offset: Float, letterHeight: Float, letterCount: Int): Int? {
    if (letterCount <= 0 || letterHeight <= 0f) return null
    return (offset / letterHeight).toInt().coerceIn(0, letterCount - 1)
}

/** A side letter index, as iOS lists have; tapping or sliding over a letter jumps to it. */
@Composable
fun AlphabetIndexBar(letters: List<String>, modifier: Modifier = Modifier, onSelect: (String) -> Unit) {
    val haptics = LocalHapticFeedback.current
    val currentLetters by rememberUpdatedState(letters)
    val currentOnSelect by rememberUpdatedState(onSelect)
    var selected by remember { mutableStateOf<String?>(null) }

    fun select(offset: Float, letterHeight: Float) {
        val index = letterIndex(offset, letterHeight, currentLetters.size) ?: return
        val letter = currentLetters[index]
        if (letter == selected) return
        selected = letter
        haptics.performHapticFeedback(HapticFeedbackType.SegmentTick)
        currentOnSelect(letter)
    }

    Column(
        modifier
            .padding(vertical = BarPadding)
            .semantics { contentDescription = "Section Index" }
            .pointerInput(Unit) {
                val letterHeight = LetterHeight.toPx()
                awaitEachGesture {
                    val down = awaitFirstDown()
                    select(down.position.y, letterHeight)
                    while (true) {
                        val change = awaitPointerEvent().changes.firstOrNull { it.id == down.id } ?: break
                        if (!change.pressed) break
                        change.consume()
                        select(change.position.y, letterHeight)
                    }
                    selected = null
                }
            },
        horizontalAlignment = Alignment.CenterHorizontally,
    ) {
        letters.forEach { letter ->
            Text(
                letter,
                color = LocalBrandColor.current,
                fontSize = 11.sp,
                fontWeight = FontWeight.SemiBold,
                textAlign = TextAlign.Center,
                modifier = Modifier.size(width = AlphabetIndexBarWidth, height = LetterHeight),
            )
        }
    }
}

/** The side letter index over a name-sorted list; [scrollTo] gets the position of the letter's first item in [items]. */
@Composable
fun <T> BoxScope.SideIndex(items: List<T>, name: (T) -> String, scrollTo: suspend (Int) -> Unit) {
    val scope = rememberCoroutineScope()
    val positions = remember(items) { SectionIndex.firstPositions(items, name) }
    AlphabetIndexBar(positions.keys.toList(), Modifier.align(Alignment.CenterEnd)) { letter ->
        positions[letter]?.let { position -> scope.launch { scrollTo(position) } }
    }
}
