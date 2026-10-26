package phanan.koel.shared.api

import io.ktor.client.engine.okhttp.OkHttp
import kotlinx.coroutines.runBlocking
import kotlinx.serialization.json.jsonPrimitive
import phanan.koel.shared.storage.InMemoryKeyValueStore
import phanan.koel.shared.storage.Preferences
import java.net.ServerSocket
import java.net.Socket
import kotlin.concurrent.thread
import kotlin.test.AfterTest
import kotlin.test.Test
import kotlin.test.assertEquals
import kotlin.test.assertFails
import kotlin.test.assertTrue
import kotlin.time.Duration.Companion.milliseconds
import kotlin.time.TimeSource

class ApiClientTimeoutTest {
    private val server = ServerSocket(0)
    private val preferences = Preferences(InMemoryKeyValueStore()).apply { host = "http://127.0.0.1:${server.localPort}" }
    private val api = ApiClient(OkHttp.create(), preferences, stallTimeout = STALL_TIMEOUT)

    @AfterTest
    fun closeServer() = server.close()

    private fun serve(respond: (Socket) -> Unit) {
        thread(isDaemon = true) {
            runCatching { server.accept().use { socket -> socket.getInputStream().read(ByteArray(8192)); respond(socket) } }
        }
    }

    @Test
    fun givesUpOnAServerThatStopsAnswering() = runBlocking {
        serve { Thread.sleep(10 * STALL_TIMEOUT.inWholeMilliseconds) }
        val start = TimeSource.Monotonic.markNow()

        val error = assertFails { api.get("data") }

        assertTrue(error.isServerFailure)
        assertTrue(start.elapsedNow() < STALL_TIMEOUT * 5)
    }

    @Test
    fun waitsForASlowResponseThatKeepsComing() = runBlocking {
        val body = "\"" + "x".repeat(10) + "\""
        serve { socket ->
            val output = socket.getOutputStream()
            output.write("HTTP/1.1 200 OK\r\nContent-Type: application/json\r\nContent-Length: ${body.length}\r\n\r\n".toByteArray())
            output.flush()
            body.forEach { character ->
                Thread.sleep(STALL_TIMEOUT.inWholeMilliseconds / 2)
                output.write(character.code)
                output.flush()
            }
        }

        assertEquals("x".repeat(10), api.get("data").jsonPrimitive.content)
    }

    private companion object {
        val STALL_TIMEOUT = 200.milliseconds
    }
}
