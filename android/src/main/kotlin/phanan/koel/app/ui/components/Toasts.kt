package phanan.koel.app.ui.components

import androidx.compose.animation.AnimatedVisibility
import androidx.compose.animation.core.tween
import androidx.compose.animation.fadeIn
import androidx.compose.animation.fadeOut
import androidx.compose.animation.scaleIn
import androidx.compose.animation.scaleOut
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.size
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.material3.Icon
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.Surface
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.runtime.LaunchedEffect
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableIntStateOf
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.remember
import androidx.compose.runtime.setValue
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.graphics.compositeOver
import androidx.compose.ui.hapticfeedback.HapticFeedbackType
import androidx.compose.ui.platform.LocalHapticFeedback
import androidx.compose.ui.semantics.LiveRegionMode
import androidx.compose.ui.semantics.liveRegion
import androidx.compose.ui.semantics.semantics
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.unit.dp
import kotlinx.coroutines.delay
import phanan.koel.app.Messages
import phanan.koel.app.ui.theme.KoelColors
import phanan.koel.app.ui.theme.KoelGlass

object ToastSpacing {
    /** Flutter's 80 above the bottom, which keeps clear of Now Playing's queue heading. */
    val bottom = 80.dp

    /** The gap above the tab bar and mini player. */
    val aboveBars = 16.dp
}

private val toastShape = RoundedCornerShape(16.dp)
private const val FADE_MILLIS = 300

/** Shows [messages] one at a time as a glass card near the bottom; [modifier] lifts it clear of whatever sits there. */
@Composable
fun ToastHost(messages: Messages, modifier: Modifier = Modifier) {
    var current by remember { mutableStateOf<Messages.Toast?>(null) }
    var isShown by remember { mutableStateOf(false) }
    var shownCount by remember { mutableIntStateOf(0) }
    val haptics = LocalHapticFeedback.current

    LaunchedEffect(messages) {
        messages.all.collect { toast ->
            current = toast
            isShown = true
            shownCount++
            haptics.performHapticFeedback(HapticFeedbackType.ContextClick)
        }
    }
    LaunchedEffect(shownCount) {
        if (shownCount == 0) return@LaunchedEffect
        delay(Messages.duration)
        isShown = false
    }

    Box(modifier.fillMaxSize().padding(horizontal = 32.dp), contentAlignment = Alignment.BottomCenter) {
        AnimatedVisibility(
            visible = isShown,
            enter = fadeIn(tween(FADE_MILLIS)) + scaleIn(tween(FADE_MILLIS), initialScale = 0.95f),
            exit = fadeOut(tween(FADE_MILLIS)) + scaleOut(tween(FADE_MILLIS), targetScale = 0.95f),
        ) {
            current?.let { toast -> ToastCard(toast, onDismiss = { isShown = false }) }
        }
    }
}

@Composable
private fun ToastCard(toast: Messages.Toast, onDismiss: () -> Unit) {
    Surface(
        onClick = onDismiss,
        shape = toastShape,
        color = KoelGlass.fill.compositeOver(KoelColors.menu),
        contentColor = KoelColors.text,
        border = KoelGlass.border,
        shadowElevation = 8.dp,
        modifier = Modifier.semantics { liveRegion = LiveRegionMode.Polite },
    ) {
        Row(
            modifier = Modifier.padding(horizontal = 16.dp, vertical = 12.dp),
            horizontalArrangement = Arrangement.spacedBy(12.dp),
            verticalAlignment = Alignment.CenterVertically,
        ) {
            Icon(toast.icon, contentDescription = null, tint = KoelColors.faintText, modifier = Modifier.size(24.dp))
            Column {
                Text(toast.caption, style = MaterialTheme.typography.bodyMedium.copy(fontWeight = FontWeight.SemiBold))
                toast.message?.let { message ->
                    Text(message, style = MaterialTheme.typography.bodySmall, color = KoelColors.secondaryText)
                }
            }
        }
    }
}
