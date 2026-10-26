package phanan.koel.app.ui.auth

import androidx.compose.foundation.background
import androidx.compose.foundation.border
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.size
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.foundation.text.BasicTextField
import androidx.compose.foundation.text.KeyboardOptions
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.remember
import androidx.compose.runtime.setValue
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.alpha
import androidx.compose.ui.focus.onFocusChanged
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.graphics.SolidColor
import androidx.compose.ui.semantics.contentDescription
import androidx.compose.ui.semantics.semantics
import androidx.compose.ui.text.TextStyle
import androidx.compose.ui.text.font.FontFamily
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.text.input.ImeAction
import androidx.compose.ui.text.input.KeyboardType
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import phanan.koel.app.ui.theme.KoelColors

private val boxShape = RoundedCornerShape(8.dp)
private val boxFill = Color.White.copy(alpha = 0.1f)
private val boxBorder = Color.White.copy(alpha = 0.24f)
private val digitStyle = TextStyle(color = Color.White, fontSize = 20.sp, fontFamily = FontFamily.Monospace, fontWeight = FontWeight.SemiBold)

/**
 * Flutter's segmented code input: one box per digit, filled from a single field so pasting a code
 * fills every box at once.
 */
@Composable
fun OneTimeCodeInput(code: String, onChange: (String) -> Unit, modifier: Modifier = Modifier) {
    var isFocused by remember { mutableStateOf(false) }

    BasicTextField(
        value = code,
        onValueChange = { onChange(AuthenticatorCode.sanitized(it)) },
        singleLine = true,
        keyboardOptions = KeyboardOptions(keyboardType = KeyboardType.NumberPassword, imeAction = ImeAction.Done),
        cursorBrush = SolidColor(Color.Transparent),
        modifier = modifier
            .onFocusChanged { isFocused = it.isFocused }
            .semantics { contentDescription = "Authentication code" },
        decorationBox = { innerTextField ->
            Box {
                Box(Modifier.alpha(0f)) { innerTextField() }
                Row(horizontalArrangement = Arrangement.spacedBy(8.dp, Alignment.CenterHorizontally), modifier = Modifier.fillMaxWidth()) {
                    repeat(AuthenticatorCode.LENGTH) { index ->
                        val isCurrent = isFocused && index == minOf(code.length, AuthenticatorCode.LENGTH - 1)
                        Box(
                            contentAlignment = Alignment.Center,
                            modifier = Modifier
                                .size(width = 44.dp, height = 54.dp)
                                .background(boxFill, boxShape)
                                .border(if (isCurrent) 2.dp else 1.dp, if (isCurrent) KoelColors.highlight else boxBorder, boxShape),
                        ) {
                            Text(code.getOrNull(index)?.toString().orEmpty(), style = digitStyle)
                        }
                    }
                }
            }
        },
    )
}
