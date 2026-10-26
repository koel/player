package phanan.koel.app.ui.components

import androidx.compose.foundation.background
import androidx.compose.foundation.clickable
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.navigationBarsPadding
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.size
import androidx.compose.foundation.rememberScrollState
import androidx.compose.foundation.shape.CircleShape
import androidx.compose.foundation.verticalScroll
import androidx.compose.material3.ExperimentalMaterial3Api
import androidx.compose.material3.HorizontalDivider
import androidx.compose.material3.Icon
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.ModalBottomSheet
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.alpha
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.text.style.TextAlign
import androidx.compose.ui.text.style.TextOverflow
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import phanan.koel.app.ui.theme.KoelColors

/**
 * A long-press menu: the compact preview card, then [accessory] if any, then the actions, grouped
 * into sections. Picking an action closes the sheet first, unless the action opens a follow-up.
 */
@OptIn(ExperimentalMaterial3Api::class)
@Composable
fun ActionsSheet(
    onDismiss: () -> Unit,
    actions: List<MenuAction>,
    accessory: @Composable () -> Unit = {},
    preview: @Composable () -> Unit,
) {
    ModalBottomSheet(onDismissRequest = onDismiss, containerColor = KoelColors.menu) {
        Column(Modifier.verticalScroll(rememberScrollState()).navigationBarsPadding().padding(bottom = 8.dp)) {
            preview()
            accessory()
            actions.forEachIndexed { index, action ->
                if (index == 0 || action.startsSection) HorizontalDivider(Modifier.padding(vertical = 4.dp), color = KoelColors.hairline)
                SheetAction(
                    MenuAction(action.label, action.icon, action.isDestructive, action.isEnabled, action.startsSection) {
                        if (!action.opensFollowUp) onDismiss()
                        action.onClick()
                    },
                )
            }
        }
    }
}

/** A row in an action sheet; red when destructive, dimmed when unavailable. */
@Composable
fun SheetAction(action: MenuAction) {
    val color = if (action.isDestructive) KoelColors.destructiveSwipe else KoelColors.text
    Row(
        Modifier
            .fillMaxWidth()
            .clickable(enabled = action.isEnabled, onClick = action.onClick)
            .alpha(if (action.isEnabled) 1f else 0.38f)
            .padding(horizontal = 20.dp, vertical = 14.dp),
        horizontalArrangement = Arrangement.spacedBy(16.dp),
        verticalAlignment = Alignment.CenterVertically,
    ) {
        action.icon?.let { Icon(it, contentDescription = null, tint = color, modifier = Modifier.size(22.dp)) }
        Text(action.label, color = color, style = MaterialTheme.typography.bodyLarge)
    }
}

/** The centered, one-line title on top of a sheet. */
@Composable
fun SheetTitle(text: String, modifier: Modifier = Modifier) {
    Text(
        text,
        style = MaterialTheme.typography.titleMedium.copy(fontSize = 17.sp, fontWeight = FontWeight.SemiBold),
        textAlign = TextAlign.Center,
        maxLines = 1,
        overflow = TextOverflow.Ellipsis,
        modifier = modifier.fillMaxWidth(),
    )
}

/** The grabber on top of sheets that draw their own instead of Material's. */
@Composable
fun SheetDragHandle(modifier: Modifier = Modifier) {
    Box(modifier.size(width = 36.dp, height = 5.dp).background(KoelColors.secondaryText, CircleShape))
}
