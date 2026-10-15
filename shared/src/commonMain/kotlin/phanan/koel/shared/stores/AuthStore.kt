package phanan.koel.shared.stores

import kotlinx.coroutines.flow.MutableStateFlow
import kotlinx.coroutines.flow.StateFlow
import kotlinx.coroutines.flow.asStateFlow
import kotlinx.serialization.json.JsonElement
import kotlinx.serialization.json.JsonPrimitive
import kotlinx.serialization.json.booleanOrNull
import kotlinx.serialization.json.buildJsonObject
import kotlinx.serialization.json.jsonObject
import kotlinx.serialization.json.jsonPrimitive
import kotlinx.serialization.json.put
import phanan.koel.shared.api.ApiClient
import phanan.koel.shared.models.User
import phanan.koel.shared.storage.Preferences

data class TwoFactorChallenge(val loginToken: String)

class AuthStore internal constructor(
    private val api: ApiClient,
    private val preferences: Preferences,
) {
    private val userState = MutableStateFlow<User?>(null)
    val currentUser: StateFlow<User?> = userState.asStateFlow()

    val hasToken: Boolean get() = preferences.apiToken != null

    val host: String? get() = preferences.host

    val lastEmail: String? get() = preferences.userEmail

    /** Returns a challenge when the server wants a second factor, or null when logged in. */
    @Throws(Exception::class)
    suspend fun login(host: String, email: String, password: String): TwoFactorChallenge? {
        preferences.host = host
        preferences.userEmail = email

        val response = api.post("me", buildJsonObject {
            put("email", email)
            put("password", password)
        }).jsonObject

        if (response["two_factor"]?.jsonPrimitive?.booleanOrNull == true) {
            return TwoFactorChallenge(response.getValue("login_token").jsonPrimitive.content)
        }

        storeTokens(response)
        return null
    }

    @Throws(Exception::class)
    suspend fun completeTwoFactorChallenge(challenge: TwoFactorChallenge, code: String) {
        storeTokens(api.post("me/two-factor-challenge", buildJsonObject {
            put("login_token", challenge.loginToken)
            put("code", code)
        }))
    }

    /** Logs in with the one-time token from the QR code shown in Koel's web UI. */
    @Throws(Exception::class)
    suspend fun loginWithOneTimeToken(host: String, token: String) {
        preferences.host = host
        storeTokens(api.post("me/otp", buildJsonObject { put("token", token) }))
    }

    /** Null when there is no stored token; throws when the server rejects it or is unreachable. */
    @Throws(Exception::class)
    suspend fun fetchCurrentUser(): User? {
        if (preferences.apiToken == null) return null

        val user = api.get("me", User.serializer())
        preferences.userEmail = user.email
        userState.value = user
        return user
    }

    internal suspend fun logout() {
        runCatching { api.delete("me") }
        preferences.apiToken = null
        preferences.audioToken = null
        userState.value = null
    }

    private fun storeTokens(response: JsonElement) {
        val json = response.jsonObject
        preferences.apiToken = (json["token"] as? JsonPrimitive)?.content
        preferences.audioToken = (json["audio-token"] as? JsonPrimitive)?.content
    }
}
