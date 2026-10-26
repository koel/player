package phanan.koel.shared.api

import io.ktor.client.network.sockets.SocketTimeoutException
import io.ktor.http.HttpMethod
import kotlinx.coroutines.awaitCancellation
import kotlinx.coroutines.test.runTest
import phanan.koel.shared.support.Harness
import kotlin.test.Test
import kotlin.test.assertFails
import kotlin.test.assertFailsWith
import kotlin.test.assertFalse
import kotlin.test.assertTrue
import kotlin.time.Duration.Companion.milliseconds

class ApiClientTest {
    private val h = Harness()

    @Test
    fun givesUpOnAServerThatDoesNotAnswer() = runTest {
        h.onRequest(HttpMethod.Get, "data") { awaitCancellation() }
        val api = ApiClient(h.engine, h.preferences, stallTimeout = 100.milliseconds)

        assertFailsWith<SocketTimeoutException> { api.get("data") }
    }

    @Test
    fun tellsAServerFailureFromAnUnreachableServer() = runTest {
        h.on(HttpMethod.Get, "data", status = 503) { "" }
        h.onRequest(HttpMethod.Get, "overview") { awaitCancellation() }
        h.onRequest(HttpMethod.Get, "me") { throw IllegalStateException("Unable to resolve host") }
        val api = ApiClient(h.engine, h.preferences, stallTimeout = 100.milliseconds)

        assertTrue(assertFails { api.get("data") }.isServerFailure)
        assertTrue(assertFails { api.get("overview") }.isServerFailure)
        assertFalse(assertFails { api.get("me") }.isServerFailure)
    }
}
