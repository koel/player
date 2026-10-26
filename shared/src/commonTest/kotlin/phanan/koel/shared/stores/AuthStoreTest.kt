package phanan.koel.shared.stores

import io.ktor.http.HttpMethod
import kotlinx.coroutines.CoroutineScope
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.awaitCancellation
import kotlinx.coroutines.test.runTest
import kotlinx.serialization.json.jsonPrimitive
import phanan.koel.shared.api.HttpResponseException
import phanan.koel.shared.support.Fixtures
import phanan.koel.shared.support.Harness
import kotlin.test.Test
import kotlin.test.assertEquals
import kotlin.test.assertFailsWith
import kotlin.test.assertNull

class AuthStoreTest {
    private val h = Harness()
    private val auth = AuthStore(h.api, h.preferences, CoroutineScope(Dispatchers.Unconfined))

    @Test
    fun storesBothTokensAfterAPlainLogin() = runTest {
        h.preferences.apiToken = null
        h.on(HttpMethod.Post, "me") { """{"token":"new-api","audio-token":"new-audio"}""" }

        val challenge = auth.login("https://other.test/", "a@b.c", "secret")

        assertNull(challenge)
        assertEquals("https://other.test", h.preferences.host)
        assertEquals("new-api", h.preferences.apiToken)
        assertEquals("new-audio", h.preferences.audioToken)
        assertEquals("secret", h.requestsTo(HttpMethod.Post, "me").single().json["password"]?.jsonPrimitive?.content)
    }

    @Test
    fun returnsAChallengeWhenTheServerWantsASecondFactor() = runTest {
        h.preferences.apiToken = null
        h.on(HttpMethod.Post, "me") { """{"two_factor":true,"login_token":"lt-1"}""" }
        h.on(HttpMethod.Post, "me/two-factor-challenge") { """{"token":"api-2fa","audio-token":"audio-2fa"}""" }

        val challenge = auth.login(Harness.HOST, "a@b.c", "secret")!!
        assertNull(h.preferences.apiToken)

        auth.completeTwoFactorChallenge(challenge, "123456")

        val sent = h.requestsTo(HttpMethod.Post, "me/two-factor-challenge").single().json
        assertEquals("lt-1", sent["login_token"]?.jsonPrimitive?.content)
        assertEquals("123456", sent["code"]?.jsonPrimitive?.content)
        assertEquals("api-2fa", h.preferences.apiToken)
    }

    @Test
    fun logsInWithAOneTimeToken() = runTest {
        h.on(HttpMethod.Post, "me/otp") { """{"token":"otp-api","audio-token":"otp-audio"}""" }

        auth.loginWithOneTimeToken(Harness.HOST, "one-time")

        assertEquals("one-time", h.requestsTo(HttpMethod.Post, "me/otp").single().json["token"]?.jsonPrimitive?.content)
        assertEquals("otp-api", h.preferences.apiToken)
    }

    @Test
    fun aStartedSessionFetchesTheUserWithItsToken() = runTest {
        h.preferences.apiToken = null
        h.on(HttpMethod.Get, "me") { Fixtures.user(email = "mock@koel.test").toString() }

        auth.startSession("https://mock.test", "mock-api", "mock-audio")

        assertEquals("https://mock.test", h.preferences.host)
        assertEquals("mock-audio", h.preferences.audioToken)
        assertEquals("mock-api", h.preferences.apiToken)
        assertEquals("mock@koel.test", auth.fetchCurrentUser()?.email)
        assertEquals("Bearer mock-api", h.requestsTo(HttpMethod.Get, "me").single().headers["Authorization"])
    }

    @Test
    fun surfacesRejectedCredentials() = runTest {
        h.on(HttpMethod.Post, "me", status = 401) { """{"message":"Unauthenticated."}""" }

        val error = assertFailsWith<HttpResponseException> { auth.login(Harness.HOST, "a@b.c", "wrong") }

        assertEquals(401, error.statusCode)
    }

    @Test
    fun fetchesTheCurrentUserOnlyWithAToken() = runTest {
        h.on(HttpMethod.Get, "me") { Fixtures.user(email = "fresh@koel.test").toString() }

        assertEquals("fresh@koel.test", auth.fetchCurrentUser()?.email)
        assertEquals("fresh@koel.test", h.preferences.userEmail)

        h.preferences.apiToken = null
        assertNull(auth.fetchCurrentUser())
    }

    @Test
    fun aRejectedTokenMeansLoggedOut() = runTest {
        h.on(HttpMethod.Get, "me", status = 401) { """{"message":"Unauthenticated."}""" }

        assertNull(auth.fetchCurrentUser())
        assertNull(h.preferences.apiToken)
        assertNull(h.preferences.audioToken)
    }

    @Test
    fun aTokenWithoutAHostMeansLoggedOut() = runTest {
        h.preferences.host = null

        assertNull(auth.fetchCurrentUser())
        assertNull(h.preferences.apiToken)
        assertNull(h.preferences.audioToken)
        assertEquals(emptyList(), h.requests)
    }

    @Test
    fun anUnreachableServerIsAnErrorNotALogout() = runTest {
        h.onRequest(HttpMethod.Get, "me") { throw IllegalStateException("Unable to resolve host") }

        assertFailsWith<IllegalStateException> { auth.fetchCurrentUser() }
        assertEquals("api-token", h.preferences.apiToken)
    }

    @Test
    fun logoutDoesNotWaitForTheServer() = runTest {
        h.onRequest(HttpMethod.Delete, "me") { awaitCancellation() }

        auth.logout()

        assertNull(h.preferences.apiToken)
        assertEquals("Bearer api-token", h.requestsTo(HttpMethod.Delete, "me").single().headers["Authorization"])
    }

    @Test
    fun logoutClearsTokensEvenWhenTheServerFails() = runTest {
        h.on(HttpMethod.Delete, "me", status = 500) { "" }

        auth.logout()

        assertNull(h.preferences.apiToken)
        assertNull(h.preferences.audioToken)
        assertNull(auth.currentUser.value)
    }

    @Test
    fun sendsTheApiVersionAndBearerToken() = runTest {
        h.on(HttpMethod.Get, "me") { Fixtures.user().toString() }

        auth.fetchCurrentUser()

        val headers = h.requestsTo(HttpMethod.Get, "me").single().headers
        assertEquals("Bearer api-token", headers["Authorization"])
        assertEquals("v6", headers["X-Api-Version"])
    }
}
