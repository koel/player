package phanan.koel.app.ui.components

import androidx.compose.foundation.background
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.Spacer
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.height
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.size
import androidx.compose.foundation.shape.CircleShape
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.foundation.lazy.LazyListScope
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.filled.MusicNote
import androidx.compose.material.icons.filled.Search
import androidx.compose.material.icons.filled.SignalWifiStatusbarConnectedNoInternet4
import androidx.compose.material3.Button
import androidx.compose.material3.CircularProgressIndicator
import androidx.compose.material3.Icon
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.runtime.LaunchedEffect
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableIntStateOf
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.remember
import androidx.compose.runtime.setValue
import kotlinx.coroutines.CancellationException
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.graphics.vector.ImageVector
import androidx.compose.ui.semantics.clearAndSetSemantics
import androidx.compose.foundation.text.InlineTextContent
import androidx.compose.foundation.text.appendInlineContent
import androidx.compose.ui.text.Placeholder
import androidx.compose.ui.text.PlaceholderVerticalAlign
import androidx.compose.ui.text.buildAnnotatedString
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.text.style.TextAlign
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.em
import androidx.compose.ui.unit.sp
import phanan.koel.app.ui.theme.KoelColors
import phanan.koel.app.ui.theme.KoelInputs

class PlaceholderAction(val label: String, val onClick: () -> Unit)

/** "Tap the [icon] icon …": an explanation that points at an icon on screen. */
class IconHint(val icon: ImageVector, val textAfterIcon: String)

object LoadFailure {
    const val TITLE = "Oops!"
    const val MESSAGE = "The request cannot be completed. Please double-check if you are connected to the internet."
    const val RETRY = "Retry"
}

private const val HINT_ICON_ID = "hint-icon"

/** A big symbol, a title, a line of explanation and maybe a button, like iOS's ContentUnavailableView. */
@Composable
fun ContentUnavailable(
    title: String,
    icon: ImageVector,
    modifier: Modifier = Modifier,
    description: String? = null,
    hint: IconHint? = null,
    action: PlaceholderAction? = null,
) {
    val descriptionStyle = MaterialTheme.typography.bodyMedium.copy(fontSize = 15.sp)
    Column(
        modifier = modifier.fillMaxWidth().padding(horizontal = 32.dp, vertical = 48.dp),
        horizontalAlignment = Alignment.CenterHorizontally,
    ) {
        Icon(icon, contentDescription = null, tint = KoelColors.secondaryText, modifier = Modifier.size(48.dp))
        Spacer(Modifier.height(16.dp))
        Text(title, style = MaterialTheme.typography.titleLarge.copy(fontWeight = FontWeight.Bold), textAlign = TextAlign.Center)
        description?.let {
            Spacer(Modifier.height(6.dp))
            Text(it, style = descriptionStyle, color = KoelColors.secondaryText, textAlign = TextAlign.Center)
        }
        hint?.let {
            Spacer(Modifier.height(6.dp))
            Text(
                buildAnnotatedString {
                    append("Tap the ")
                    appendInlineContent(HINT_ICON_ID)
                    append(" ${it.textAfterIcon}")
                },
                style = descriptionStyle,
                color = KoelColors.secondaryText,
                textAlign = TextAlign.Center,
                inlineContent = mapOf(
                    HINT_ICON_ID to InlineTextContent(Placeholder(1.em, 1.em, PlaceholderVerticalAlign.TextCenter)) { _ ->
                        Icon(it.icon, contentDescription = null, tint = KoelColors.secondaryText)
                    },
                ),
            )
        }
        action?.let {
            Spacer(Modifier.height(20.dp))
            Button(onClick = it.onClick, shape = KoelInputs.shape) { Text(it.label, fontWeight = FontWeight.SemiBold) }
        }
    }
}

/**
 * Loading, failure and empty states for a list with nothing to show yet, centered in the screen.
 * The empty state can carry its own symbol, explanation and button, such as "Create Playlist".
 */
@Composable
fun ListPlaceholder(
    loading: Loading,
    emptyTitle: String,
    emptyIcon: ImageVector = Icons.Default.MusicNote,
    emptyDescription: String? = null,
    emptyHint: IconHint? = null,
    emptyAction: PlaceholderAction? = null,
) {
    Box(Modifier.fillMaxSize(), contentAlignment = Alignment.Center) {
        when {
            loading.isBusy -> LoadingSpinner()
            loading.hasFailed -> FailedState(loading::retry)
            else -> ContentUnavailable(emptyTitle, emptyIcon, description = emptyDescription, hint = emptyHint, action = emptyAction)
        }
    }
}

/** What shows when something couldn't load, with Retry. */
@Composable
fun FailedState(onRetry: () -> Unit, modifier: Modifier = Modifier) {
    ContentUnavailable(
        LoadFailure.TITLE,
        Icons.Default.SignalWifiStatusbarConnectedNoInternet4,
        modifier = modifier,
        description = LoadFailure.MESSAGE,
        action = PlaceholderAction(LoadFailure.RETRY, onRetry),
    )
}

@Composable
fun LoadingSpinner(modifier: Modifier = Modifier) {
    Box(modifier, contentAlignment = Alignment.Center) {
        CircularProgressIndicator(color = KoelColors.secondaryText)
    }
}

/**
 * What a list of songs shows instead of its rows, in this order: placeholder rows while it loads,
 * a failure with Retry, the empty state when there is an [emptyTitle], and "No Results" when
 * the [filter] matches nothing.
 */
fun LazyListScope.playableListStates(
    isEmpty: Boolean,
    loading: Loading,
    emptyTitle: String?,
    emptyIcon: ImageVector = Icons.Default.MusicNote,
    filter: String,
    hasNoResults: Boolean,
) {
    when {
        isEmpty && loading.isBusy -> item(key = "loading") { LoadingRows() }
        isEmpty && loading.hasFailed -> item(key = "failed") { FailedState(loading::retry) }
        isEmpty && emptyTitle != null -> item(key = "empty") { ContentUnavailable(emptyTitle, emptyIcon) }
        hasNoResults && filter.isNotBlank() -> item(key = "no-results") { NoResults(filter) }
    }
}

/** What a filter or search shows when nothing matches. */
@Composable
fun NoResults(keywords: String, modifier: Modifier = Modifier) {
    ContentUnavailable(
        "No Results for “${keywords.trim()}”",
        Icons.Default.Search,
        modifier = modifier,
        description = "Check the spelling or try a new search.",
    )
}

/** Placeholder song rows while a list loads, like the iOS app's. */
@Composable
fun LoadingRows(count: Int = 8) {
    Column(Modifier.clearAndSetSemantics {}) {
        repeat(count) {
            Row(
                Modifier.fillMaxWidth().padding(horizontal = 16.dp, vertical = 8.dp),
                horizontalArrangement = Arrangement.spacedBy(12.dp),
                verticalAlignment = Alignment.CenterVertically,
            ) {
                Box(Modifier.size(44.dp).background(KoelColors.placeholder, RoundedCornerShape(6.dp)))
                Column(Modifier.weight(1f), verticalArrangement = Arrangement.spacedBy(8.dp)) {
                    Box(Modifier.fillMaxWidth().height(14.dp).background(KoelColors.placeholder, CircleShape))
                    Box(Modifier.fillMaxWidth().padding(end = 96.dp).height(11.dp).background(KoelColors.placeholder, CircleShape))
                }
            }
        }
    }
}

/** The last row of a paged list: loads the next page when it scrolls into view, with Retry when that fails. */
@Composable
fun LoadMore(loadedCount: Int, load: suspend () -> Unit) {
    var attempts by remember(loadedCount) { mutableIntStateOf(0) }
    var hasFailed by remember(loadedCount) { mutableStateOf(false) }
    LaunchedEffect(loadedCount, attempts) {
        hasFailed = false
        try {
            load()
        } catch (cancellation: CancellationException) {
            throw cancellation
        } catch (error: Exception) {
            hasFailed = true
        }
    }
    if (hasFailed) {
        FailedState(onRetry = { attempts++ })
        return
    }
    Box(Modifier.fillMaxWidth().padding(16.dp), contentAlignment = Alignment.Center) {
        CircularProgressIndicator(modifier = Modifier.size(24.dp), strokeWidth = 2.dp, color = KoelColors.secondaryText)
    }
}
