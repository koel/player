package phanan.koel.app.ui.auth

import androidx.compose.animation.AnimatedContent
import androidx.compose.animation.AnimatedContentTransitionScope
import androidx.compose.animation.ContentTransform
import androidx.compose.animation.slideInHorizontally
import androidx.compose.animation.slideOutHorizontally
import androidx.compose.animation.togetherWith
import androidx.compose.foundation.Image
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.imePadding
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.size
import androidx.compose.foundation.layout.widthIn
import androidx.compose.foundation.rememberScrollState
import androidx.compose.foundation.text.KeyboardActions
import androidx.compose.foundation.text.KeyboardOptions
import androidx.compose.foundation.verticalScroll
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.filled.QrCodeScanner
import androidx.compose.material.icons.filled.Visibility
import androidx.compose.material.icons.filled.VisibilityOff
import androidx.compose.material3.Icon
import androidx.compose.material3.IconButton
import androidx.compose.material3.Text
import androidx.compose.material3.TextField
import androidx.compose.runtime.Composable
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.remember
import androidx.compose.runtime.rememberCoroutineScope
import androidx.compose.runtime.saveable.rememberSaveable
import androidx.compose.runtime.setValue
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.focus.FocusRequester
import androidx.compose.ui.focus.focusRequester
import androidx.compose.ui.platform.LocalContext
import androidx.compose.ui.res.painterResource
import androidx.compose.ui.semantics.contentDescription
import androidx.compose.ui.semantics.semantics
import androidx.compose.ui.semantics.text
import androidx.compose.ui.text.AnnotatedString
import androidx.compose.ui.text.input.ImeAction
import androidx.compose.ui.text.input.KeyboardType
import androidx.compose.ui.text.input.PasswordVisualTransformation
import androidx.compose.ui.text.input.VisualTransformation
import androidx.compose.ui.unit.dp
import androidx.lifecycle.viewmodel.compose.viewModel
import kotlinx.coroutines.launch
import phanan.koel.app.R
import phanan.koel.app.ui.LocalAppModel
import phanan.koel.app.ui.components.BrandMeshBackground
import phanan.koel.app.ui.components.GlassCircle
import phanan.koel.app.ui.theme.KoelColors
import phanan.koel.shared.stores.TwoFactorChallenge

@Composable
fun LoginScreen() {
    val app = LocalAppModel.current
    val login = viewModel { LoginViewModel(app) }
    val scope = rememberCoroutineScope()
    val context = LocalContext.current

    var isPasswordShown by rememberSaveable { mutableStateOf(false) }
    val focusRequesters = remember { LoginField.entries.associateWith { FocusRequester() } }

    fun logIn() {
        LoginField.firstMissing(login.host, login.email, login.password)?.let { missing ->
            focusRequesters.getValue(missing).requestFocus()
            return
        }
        login.logIn()
    }

    fun logInWithQrCode() {
        scope.launch { scanLoginQrCode(context)?.let(login::logIn) }
    }

    login.errorMessage?.let { ErrorAlert(it) { login.errorMessage = null } }

    AnimatedContent(login.challenge, transitionSpec = { pageSlide() }, contentKey = { it != null }, label = "Two-Factor") { pending ->
        if (pending != null) {
            TwoFactorScreen(login, onCancel = { login.challenge = null })
            return@AnimatedContent
        }

        Box(Modifier.fillMaxSize()) {
            BrandMeshBackground()
            Column(
                modifier = Modifier
                    .fillMaxSize()
                    .verticalScroll(rememberScrollState())
                    .imePadding()
                    .padding(horizontal = 24.dp, vertical = 48.dp),
                verticalArrangement = Arrangement.Center,
                horizontalAlignment = Alignment.CenterHorizontally,
            ) {
                Column(
                    modifier = Modifier.widthIn(max = 480.dp).fillMaxWidth(),
                    verticalArrangement = Arrangement.spacedBy(32.dp),
                    horizontalAlignment = Alignment.CenterHorizontally,
                ) {
                    Image(
                        painter = painterResource(R.drawable.logo),
                        contentDescription = "Koel",
                        modifier = Modifier.size(120.dp),
                    )

                    Column(verticalArrangement = Arrangement.spacedBy(12.dp)) {
                        GlassField {
                            CardField(
                                value = login.host,
                                onValueChange = { login.host = it },
                                label = "Host",
                                hint = "https://www.koel.music",
                                keyboardOptions = KeyboardOptions(keyboardType = KeyboardType.Uri, imeAction = ImeAction.Next, autoCorrectEnabled = false),
                                modifier = Modifier
                                    .focusRequester(focusRequesters.getValue(LoginField.Host))
                                    .semantics { contentDescription = "Host" },
                            )
                        }
                        GlassField {
                            CardField(
                                value = login.email,
                                onValueChange = { login.email = it },
                                label = "Email",
                                hint = "you@koel.music",
                                keyboardOptions = KeyboardOptions(keyboardType = KeyboardType.Email, imeAction = ImeAction.Next, autoCorrectEnabled = false),
                                modifier = Modifier.focusRequester(focusRequesters.getValue(LoginField.Email)),
                            )
                        }
                        GlassField {
                            CardField(
                                value = login.password,
                                onValueChange = { login.password = it },
                                label = "Password",
                                visualTransformation = if (isPasswordShown) VisualTransformation.None else PasswordVisualTransformation(),
                                keyboardOptions = KeyboardOptions(keyboardType = KeyboardType.Password, imeAction = ImeAction.Go),
                                keyboardActions = KeyboardActions(onGo = { logIn() }),
                                trailingIcon = {
                                    IconButton(onClick = { isPasswordShown = !isPasswordShown }) {
                                        Icon(
                                            if (isPasswordShown) Icons.Default.VisibilityOff else Icons.Default.Visibility,
                                            contentDescription = if (isPasswordShown) "Hide Password" else "Show Password",
                                            tint = KoelColors.secondaryText,
                                        )
                                    }
                                },
                                modifier = Modifier.focusRequester(focusRequesters.getValue(LoginField.Password)),
                            )
                        }
                    }

                    Row(horizontalArrangement = Arrangement.spacedBy(12.dp), verticalAlignment = Alignment.CenterVertically) {
                        ProminentButton("Log In", onClick = ::logIn, enabled = !login.isLoggingIn, isBusy = login.isLoggingIn, modifier = Modifier.weight(1f))
                        GlassCircle(56.dp, onClick = ::logInWithQrCode, enabled = !login.isLoggingIn) {
                            Icon(Icons.Default.QrCodeScanner, contentDescription = "Log In with QR Code")
                        }
                    }
                }
            }
        }
    }
}

/** The two-factor page slides in over the login form like a pushed page, and back out when cancelled. */
private fun AnimatedContentTransitionScope<TwoFactorChallenge?>.pageSlide(): ContentTransform =
    if (targetState != null) {
        slideInHorizontally { width -> width } togetherWith slideOutHorizontally { width -> -width / 3 }
    } else {
        slideInHorizontally { width -> -width / 3 } togetherWith slideOutHorizontally { width -> width }
    }

/** A login field with a floating label, and an example under it once the label has moved up. */
@Composable
private fun CardField(
    value: String,
    onValueChange: (String) -> Unit,
    label: String,
    keyboardOptions: KeyboardOptions,
    modifier: Modifier = Modifier,
    keyboardActions: KeyboardActions = KeyboardActions.Default,
    visualTransformation: VisualTransformation = VisualTransformation.None,
    hint: String? = null,
    trailingIcon: (@Composable () -> Unit)? = null,
) {
    TextField(
        value = value,
        onValueChange = onValueChange,
        label = { Text(label) },
        placeholder = hint?.let { { Text(it) } },
        singleLine = true,
        visualTransformation = visualTransformation,
        keyboardOptions = keyboardOptions,
        keyboardActions = keyboardActions,
        trailingIcon = trailingIcon,
        colors = cardFieldColors(),
        modifier = modifier
            .fillMaxWidth()
            .padding(horizontal = 4.dp)
            .semantics { text = AnnotatedString(label) },
    )
}

enum class LoginField {
    Host,
    Email,
    Password,
    ;

    companion object {
        /** The first field still empty, which Log In focuses instead of sending the form. */
        fun firstMissing(host: String, email: String, password: String): LoginField? = when {
            host.isBlank() -> Host
            email.isBlank() -> Email
            password.isEmpty() -> Password
            else -> null
        }
    }
}

/** Adds https:// when no scheme is given and drops a trailing slash. */
val String.normalizedHost: String
    get() {
        val trimmed = trim().trimEnd('/')
        return if (trimmed.startsWith("http://") || trimmed.startsWith("https://")) trimmed else "https://$trimmed"
    }
