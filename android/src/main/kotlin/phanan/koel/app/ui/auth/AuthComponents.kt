package phanan.koel.app.ui.auth

import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.height
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.size
import androidx.compose.foundation.shape.CircleShape
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.material3.AlertDialog
import androidx.compose.material3.CircularProgressIndicator
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.Surface
import androidx.compose.material3.Text
import androidx.compose.material3.TextButton
import androidx.compose.material3.TextFieldDefaults
import androidx.compose.runtime.Composable
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.unit.dp
import phanan.koel.app.ui.theme.KoelColors
import phanan.koel.app.ui.theme.KoelGlass
import phanan.koel.shared.api.HttpResponseException

/** A field in its own frosted, rounded box. */
@Composable
fun GlassField(content: @Composable () -> Unit) {
    Surface(
        shape = RoundedCornerShape(16.dp),
        color = KoelGlass.fill,
        border = KoelGlass.border,
        modifier = Modifier.fillMaxWidth(),
        content = content,
    )
}

/** A text field without a fill or underline, for use inside a [GlassField]. */
@Composable
fun cardFieldColors() = TextFieldDefaults.colors(
    focusedContainerColor = Color.Transparent,
    unfocusedContainerColor = Color.Transparent,
    disabledContainerColor = Color.Transparent,
    focusedIndicatorColor = Color.Transparent,
    unfocusedIndicatorColor = Color.Transparent,
    disabledIndicatorColor = Color.Transparent,
    focusedPlaceholderColor = KoelColors.faintText,
    unfocusedPlaceholderColor = KoelColors.faintText,
    focusedLabelColor = KoelColors.secondaryText,
    unfocusedLabelColor = KoelColors.faintText,
    cursorColor = KoelColors.highlight,
)

/** A large, fully rounded frosted button with semibold text, or a spinner while [isBusy]. */
@Composable
fun GlassButton(label: String, onClick: () -> Unit, modifier: Modifier = Modifier, enabled: Boolean = true, isBusy: Boolean = false) {
    Surface(
        onClick = onClick,
        enabled = enabled,
        shape = CircleShape,
        color = KoelGlass.fill,
        contentColor = Color.White,
        border = KoelGlass.border,
        modifier = modifier.height(56.dp),
    ) {
        ButtonContent(label, isBusy)
    }
}

/** The tinted, prominent version of [GlassButton], for a screen's main action. */
@Composable
fun ProminentButton(label: String, onClick: () -> Unit, modifier: Modifier = Modifier, enabled: Boolean = true, isBusy: Boolean = false) {
    Surface(
        onClick = onClick,
        enabled = enabled,
        shape = CircleShape,
        color = if (enabled) KoelColors.highlight else KoelColors.highlight.copy(alpha = 0.4f),
        contentColor = Color.White,
        modifier = modifier.height(56.dp),
    ) {
        ButtonContent(label, isBusy)
    }
}

@Composable
private fun ButtonContent(label: String, isBusy: Boolean) {
    Box(contentAlignment = Alignment.Center, modifier = Modifier.padding(horizontal = 24.dp)) {
        if (isBusy) {
            CircularProgressIndicator(color = Color.White, strokeWidth = 2.dp, modifier = Modifier.size(22.dp))
        } else {
            Text(label, style = MaterialTheme.typography.titleMedium.copy(fontWeight = FontWeight.SemiBold))
        }
    }
}

/** The iOS-style "Error" alert. */
@Composable
fun ErrorAlert(message: String, onDismiss: () -> Unit) {
    AlertDialog(
        onDismissRequest = onDismiss,
        title = { Text("Error") },
        text = { Text(message) },
        confirmButton = { TextButton(onClick = onDismiss) { Text("OK") } },
    )
}

/** What to tell the user when a login request fails; a 401 means the credentials were wrong. */
fun authErrorMessage(error: Throwable, whenUnauthorized: String, otherwise: String): String =
    if ((error as? HttpResponseException)?.statusCode == 401) whenUnauthorized else otherwise
