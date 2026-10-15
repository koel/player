package phanan.koel.shared.support

import io.ktor.client.engine.mock.MockEngine
import io.ktor.client.engine.mock.respond
import io.ktor.client.request.HttpRequestData
import io.ktor.http.HttpHeaders
import io.ktor.http.HttpMethod
import io.ktor.http.HttpStatusCode
import io.ktor.http.content.TextContent
import io.ktor.http.headersOf
import kotlinx.serialization.json.JsonElement
import kotlinx.serialization.json.JsonNull
import kotlinx.serialization.json.JsonObject
import kotlinx.serialization.json.jsonObject
import phanan.koel.shared.api.ApiClient
import phanan.koel.shared.json.KoelJson
import phanan.koel.shared.session.Session
import phanan.koel.shared.storage.InMemoryKeyValueStore
import phanan.koel.shared.storage.Preferences

data class RecordedRequest(
    val method: HttpMethod,
    val path: String,
    val body: JsonElement,
    val headers: Map<String, String>,
) {
    val json: JsonObject get() = body.jsonObject
}

/**
 * A fake Koel server. Routes match on method plus the path after `/api/`, query string
 * included; a route registered without a query string also matches any query.
 */
class Harness {
    val keyValueStore = InMemoryKeyValueStore()

    val preferences = Preferences(keyValueStore).apply {
        host = HOST
        apiToken = "api-token"
        audioToken = "audio-token"
        userEmail = "me@koel.test"
    }

    val session = Session(preferences)

    val requests = mutableListOf<RecordedRequest>()

    private val routes = mutableMapOf<Pair<HttpMethod, String>, (RecordedRequest) -> Reply>()

    val engine = MockEngine { request ->
        val recorded = record(request)
        val route = routes[request.method to recorded.path]
            ?: routes[request.method to recorded.path.substringBefore('?')]
            ?: error("No fake route for ${request.method.value} ${recorded.path}")
        val reply = route(recorded)
        respond(
            content = reply.body,
            status = HttpStatusCode.fromValue(reply.status),
            headers = headersOf(HttpHeaders.ContentType, "application/json"),
        )
    }

    val api = ApiClient(engine, preferences)

    fun on(method: HttpMethod, path: String, status: Int = 200, body: () -> String) {
        routes[method to path] = { Reply(status, body()) }
    }

    fun onRequest(method: HttpMethod, path: String, reply: (RecordedRequest) -> Reply) {
        routes[method to path] = reply
    }

    fun requestsTo(method: HttpMethod, path: String): List<RecordedRequest> =
        requests.filter { it.method == method && (it.path == path || it.path.substringBefore('?') == path) }

    private fun record(request: HttpRequestData): RecordedRequest {
        val path = request.url.encodedPathAndQuery.removePrefix("/api/")
        val text = (request.body as? TextContent)?.text
        val body = text?.let { KoelJson.parseToJsonElement(it) } ?: JsonNull
        val headers = request.headers.entries().associate { (name, values) -> name to values.joinToString(",") }
        return RecordedRequest(request.method, path, body, headers).also(requests::add)
    }

    data class Reply(val status: Int, val body: String)

    companion object {
        const val HOST = "https://koel.test"
    }
}
