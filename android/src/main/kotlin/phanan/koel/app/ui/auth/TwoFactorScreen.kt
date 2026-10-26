package phanan.koel.app.ui.auth

import androidx.activity.compose.BackHandler
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.imePadding
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.systemBarsPadding
import androidx.compose.foundation.layout.widthIn
import androidx.compose.foundation.rememberScrollState
import androidx.compose.foundation.text.KeyboardActions
import androidx.compose.foundation.text.KeyboardOptions
import androidx.compose.foundation.verticalScroll
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.Text
import androidx.compose.material3.TextButton
import androidx.compose.material3.TextField
import androidx.compose.runtime.Composable
import androidx.compose.runtime.LaunchedEffect
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.remember
import androidx.compose.runtime.saveable.rememberSaveable
import androidx.compose.runtime.setValue
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.focus.FocusRequester
import androidx.compose.ui.focus.focusRequester
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.text.font.FontFamily
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.text.input.ImeAction
import androidx.compose.ui.text.input.KeyboardCapitalization
import androidx.compose.ui.text.style.TextAlign
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import phanan.koel.app.ui.components.BrandMeshBackground
import phanan.koel.app.ui.theme.KoelColors

/** The authenticator code, or a recovery code, after a password login. */
@Composable
fun TwoFactorScreen(login: LoginViewModel, onCancel: () -> Unit) {
    var usesRecoveryCode by rememberSaveable { mutableStateOf(false) }
    val code = login.twoFactorCode
    val isVerifying = login.isLoggingIn
    val focusRequester = remember { FocusRequester() }

    BackHandler(enabled = !isVerifying, onBack = onCancel)
    LaunchedEffect(usesRecoveryCode) { focusRequester.requestFocus() }

    Box(Modifier.fillMaxSize()) {
        BrandMeshBackground()
        Column(
            modifier = Modifier
                .fillMaxSize()
                .systemBarsPadding()
                .verticalScroll(rememberScrollState())
                .imePadding()
                .padding(horizontal = 24.dp, vertical = 24.dp),
            verticalArrangement = Arrangement.Center,
            horizontalAlignment = Alignment.CenterHorizontally,
        ) {
            Column(
                modifier = Modifier.widthIn(max = 480.dp).fillMaxWidth(),
                verticalArrangement = Arrangement.spacedBy(16.dp),
                horizontalAlignment = Alignment.CenterHorizontally,
            ) {
                Text(
                    "Two-Factor Authentication",
                    style = MaterialTheme.typography.headlineSmall.copy(fontWeight = FontWeight.Bold),
                    textAlign = TextAlign.Center,
                )
                Text(
                    if (usesRecoveryCode) "Enter one of your recovery codes." else "Enter the code from your authenticator app.",
                    color = KoelColors.secondaryText,
                    textAlign = TextAlign.Center,
                )
                if (usesRecoveryCode) {
                    GlassField {
                        TextField(
                            value = code,
                            onValueChange = { login.twoFactorCode = it.uppercase() },
                            placeholder = { Text("Recovery code", textAlign = TextAlign.Center, modifier = Modifier.fillMaxWidth()) },
                            singleLine = true,
                            textStyle = MaterialTheme.typography.bodyLarge.copy(fontFamily = FontFamily.Monospace, letterSpacing = 2.sp, textAlign = TextAlign.Center),
                            keyboardOptions = KeyboardOptions(capitalization = KeyboardCapitalization.Characters, autoCorrectEnabled = false, imeAction = ImeAction.Go),
                            keyboardActions = KeyboardActions(onGo = { login.verifyTwoFactorCode() }),
                            colors = cardFieldColors(),
                            modifier = Modifier.fillMaxWidth().padding(horizontal = 4.dp).focusRequester(focusRequester),
                        )
                    }
                } else {
                    OneTimeCodeInput(
                        code = code,
                        onChange = { input ->
                            login.twoFactorCode = input
                            if (AuthenticatorCode.isComplete(input)) login.verifyTwoFactorCode()
                        },
                        modifier = Modifier.focusRequester(focusRequester),
                    )
                }
                ProminentButton("Verify", onClick = login::verifyTwoFactorCode, enabled = !isVerifying, isBusy = isVerifying, modifier = Modifier.fillMaxWidth())
                FooterButton(if (usesRecoveryCode) "Use authenticator code instead" else "Use a recovery code", enabled = !isVerifying) {
                    usesRecoveryCode = !usesRecoveryCode
                    login.twoFactorCode = ""
                }
                FooterButton("Back to login", enabled = !isVerifying, onClick = onCancel)
            }
        }
    }
}

@Composable
private fun FooterButton(label: String, enabled: Boolean, onClick: () -> Unit) {
    TextButton(onClick = onClick, enabled = enabled, modifier = Modifier.fillMaxWidth()) {
        Text(label, color = Color.White, textAlign = TextAlign.Center)
    }
}

object AuthenticatorCode {
    const val LENGTH = 6

    /** Keeps only digits, up to the code's length. */
    fun sanitized(input: String): String = input.filter(Char::isDigit).take(LENGTH)

    fun isComplete(code: String): Boolean = code.length == LENGTH
}
