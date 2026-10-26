package phanan.koel.app.ui.auth

import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.setValue
import androidx.lifecycle.ViewModel
import androidx.lifecycle.viewModelScope
import kotlinx.coroutines.flow.filter
import kotlinx.coroutines.launch
import phanan.koel.app.AppModel
import phanan.koel.shared.stores.TwoFactorChallenge

/** Holds the login form and its request, so turning the phone neither clears them nor cancels the login. */
class LoginViewModel(private val app: AppModel) : ViewModel() {
    var host by mutableStateOf(app.core.auth.host.orEmpty())
    var email by mutableStateOf(app.core.auth.lastEmail.orEmpty())
    var password by mutableStateOf("")
    var errorMessage by mutableStateOf<String?>(null)
    var challenge by mutableStateOf<TwoFactorChallenge?>(null)
    var twoFactorCode by mutableStateOf("")
    var isLoggingIn by mutableStateOf(false)
        private set

    init {
        viewModelScope.launch {
            app.phase.filter { it != AppModel.Phase.Login }.collect {
                password = ""
                challenge = null
            }
        }
    }

    fun logIn() {
        if (isLoggingIn) return
        isLoggingIn = true
        viewModelScope.launch {
            try {
                val pending = app.core.auth.login(host.normalizedHost, email.trim(), password)
                if (pending != null) {
                    twoFactorCode = ""
                    challenge = pending
                } else {
                    finishLogin()
                }
            } catch (error: Exception) {
                errorMessage = authErrorMessage(error, "Invalid email or password.", "There was a problem logging in. Please try again.")
            } finally {
                isLoggingIn = false
            }
        }
    }

    fun logIn(payload: LoginQrPayload) {
        if (isLoggingIn) return
        isLoggingIn = true
        viewModelScope.launch {
            try {
                app.core.auth.loginWithOneTimeToken(payload.host.normalizedHost, payload.token)
                finishLogin()
            } catch (error: Exception) {
                errorMessage = authErrorMessage(error, "Invalid login token.", "There was a problem logging in. Please try again.")
            } finally {
                isLoggingIn = false
            }
        }
    }

    fun verifyTwoFactorCode() {
        val pending = challenge ?: return
        if (twoFactorCode.isBlank() || isLoggingIn) return
        isLoggingIn = true
        viewModelScope.launch {
            try {
                app.core.auth.completeTwoFactorChallenge(pending, twoFactorCode.trim())
                finishLogin()
            } catch (error: Exception) {
                twoFactorCode = ""
                errorMessage = authErrorMessage(error, "Invalid authentication code.", "There was a problem verifying the code. Please try again.")
            } finally {
                isLoggingIn = false
            }
        }
    }

    private suspend fun finishLogin() {
        app.core.auth.fetchCurrentUser()
        app.didLogIn()
    }
}
