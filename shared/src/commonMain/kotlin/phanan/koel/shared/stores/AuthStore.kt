package phanan.koel.shared.stores

import phanan.koel.shared.onMain
import kotlinx.coroutines.CoroutineScope
import kotlinx.coroutines.flow.MutableStateFlow
import kotlinx.coroutines.flow.StateFlow
import kotlinx.coroutines.flow.asStateFlow
import kotlinx.coroutines.launch
import kotlinx.serialization.json.JsonElement
import kotlinx.serialization.json.JsonPrimitive
import kotlinx.serialization.json.booleanOrNull
import kotlinx.serialization.json.buildJsonObject
import kotlinx.serialization.json.jsonObject
import kotlinx.serialization.json.jsonPrimitive
import kotlinx.serialization.json.put
import phanan.koel.shared.api.ApiClient
import phanan.koel.shared.api.HttpResponseException
import phanan.koel.shared.models.User
import phanan.koel.shared.storage.Preferences

data class TwoFactorChallenge(val loginToken: String)

class AuthStore internal constructor(
    private val api: ApiClient,
    private val preferences: Preferences,
    private val scope: CoroutineScope,
    private val onSessionRejected: () -> Unit = {},
    private val onUserConfirmed: () -> Unit = {},
) {
    private val userState = MutableStateFlow<User?>(null)
    val currentUser: StateFlow<User?> = userState.asStateFlow()

    val hasToken: Boolean get() = preferences.apiToken != null

    val host: String? get() = preferences.host

    val lastEmail: String? get() = preferences.userEmail

    /** Returns a challenge when the server wants a second factor, or null when logged in. */
    @Throws(Exception::class)
    suspend fun login(host: String, email: String, password: String): TwoFactorChallenge? = onMain {
        preferences.host = host
        preferences.userEmail = email

        val response = api.post("me", buildJsonObject {
            put("email", email)
            put("password", password)
        }).jsonObject

        if (response["two_factor"]?.jsonPrimitive?.booleanOrNull == true) {
            return@onMain TwoFactorChallenge(response.getValue("login_token").jsonPrimitive.content)
        }

        storeTokens(response)
        null
    }

    @Throws(Exception::class)
    suspend fun completeTwoFactorChallenge(challenge: TwoFactorChallenge, code: String): Unit = onMain {
        storeTokens(api.post("me/two-factor-challenge", buildJsonObject {
            put("login_token", challenge.loginToken)
            put("code", code)
        }))
    }

    /** Starts a session with tokens the server issued earlier, as UI tests do against their mock server. */
    fun startSession(host: String, apiToken: String, audioToken: String) {
        preferences.host = host
        preferences.apiToken = apiToken
        preferences.audioToken = audioToken
    }

    /** Logs in with the one-time token from the QR code shown in Koel's web UI. */
    @Throws(Exception::class)
    suspend fun loginWithOneTimeToken(host: String, token: String): Unit = onMain {
        preferences.host = host
        storeTokens(api.post("me/otp", buildJsonObject { put("token", token) }))
    }

    /**
     * Null when there is no stored token or host, or the server rejects the token (and the user is then logged out
     * locally); throws when the server can't be reached. A token can outlive its host, as the iOS Keychain outlives
     * the app.
     */
    @Throws(Exception::class)
    suspend fun fetchCurrentUser(): User? = onMain {
        if (preferences.apiToken == null) return@onMain null
        if (preferences.host == null) {
            forgetSession()
            return@onMain null
        }

        val user = try {
            api.get("me", User.serializer())
        } catch (error: HttpResponseException) {
            if (error.statusCode != UNAUTHORIZED) throw error
            forgetSession()
            onSessionRejected()
            return@onMain null
        }
        preferences.userEmail = user.email
        userState.value = user
        onUserConfirmed()
        user
    }

    /** Tells the server to drop the token without waiting on it, so an unreachable server can't hold up logging out. */
    internal fun logout() {
        val apiToken = preferences.apiToken
        scope.launch { runCatching { api.delete("me", apiToken) } }
        forgetSession()
    }

    private fun forgetSession() {
        preferences.apiToken = null
        preferences.audioToken = null
        userState.value = null
    }

    private fun storeTokens(response: JsonElement) {
        val json = response.jsonObject
        preferences.apiToken = (json["token"] as? JsonPrimitive)?.content
        preferences.audioToken = (json["audio-token"] as? JsonPrimitive)?.content
    }

    private companion object {
        const val UNAUTHORIZED = 401
    }
}
