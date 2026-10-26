package phanan.koel.shared.api

import io.ktor.client.HttpClient
import io.ktor.client.engine.HttpClientEngine
import io.ktor.client.network.sockets.SocketTimeoutException
import io.ktor.client.plugins.HttpRequestTimeoutException
import io.ktor.client.plugins.HttpTimeout
import io.ktor.client.plugins.timeout
import io.ktor.client.request.bearerAuth
import io.ktor.client.request.header
import io.ktor.client.request.request
import io.ktor.client.request.setBody
import io.ktor.client.statement.bodyAsText
import io.ktor.http.ContentType
import io.ktor.http.HttpHeaders
import io.ktor.http.HttpMethod
import io.ktor.http.contentType
import io.ktor.http.isSuccess
import kotlinx.serialization.DeserializationStrategy
import kotlinx.serialization.KSerializer
import kotlinx.serialization.builtins.ListSerializer
import kotlinx.serialization.json.JsonElement
import kotlinx.serialization.json.JsonNull
import kotlinx.serialization.json.JsonObject
import kotlinx.serialization.json.int
import kotlinx.serialization.json.jsonArray
import kotlinx.serialization.json.jsonObject
import kotlinx.serialization.json.jsonPrimitive
import phanan.koel.shared.json.KoelJson
import phanan.koel.shared.storage.Preferences
import kotlin.time.Duration
import kotlin.time.Duration.Companion.seconds

class HttpResponseException(val statusCode: Int, val body: String) :
    Exception("Request failed with status code $statusCode.")

class NoHostException : Exception("No Koel server is configured.")

/** The user logged out or in while the request was in flight, so its response belongs to a session that is gone. */
class SessionChangedException : Exception("The session changed while the request was in flight.")

/** The server was reached but answered with an error or stopped answering, rather than not being reachable at all. */
val Throwable.isServerFailure: Boolean
    get() = this is HttpResponseException || this is HttpRequestTimeoutException || this is SocketTimeoutException

/**
 * Requests fail once the server stops sending for [stallTimeout], not after a fixed total, so a large response on a
 * slow network can take as long as it needs while a dead server still fails quickly. The connect timeout covers
 * OkHttp; Darwin ignores it, but counts waiting for the connection toward the socket (idle) timeout.
 */
class ApiClient(
    engine: HttpClientEngine,
    private val preferences: Preferences,
    stallTimeout: Duration = 15.seconds,
) {
    internal val http = HttpClient(engine) {
        expectSuccess = false
        install(HttpTimeout) {
            connectTimeoutMillis = stallTimeout.inWholeMilliseconds
            socketTimeoutMillis = stallTimeout.inWholeMilliseconds
        }
    }

    suspend fun get(path: String): JsonElement = request(HttpMethod.Get, path, null)

    /** For the few calls the server takes minutes to answer, which [timeout] then allows for. */
    internal suspend fun get(path: String, timeout: Duration?): JsonElement =
        request(HttpMethod.Get, path, null, timeoutOverride = timeout)

    suspend fun post(path: String, body: JsonElement = EMPTY_BODY): JsonElement = request(HttpMethod.Post, path, body)

    /** For the few calls the server takes minutes to answer, which [timeout] then allows for. */
    internal suspend fun post(path: String, body: JsonElement, timeout: Duration): JsonElement =
        request(HttpMethod.Post, path, body, timeoutOverride = timeout)

    suspend fun put(path: String, body: JsonElement = EMPTY_BODY): JsonElement = request(HttpMethod.Put, path, body)

    suspend fun patch(path: String, body: JsonElement = EMPTY_BODY): JsonElement = request(HttpMethod.Patch, path, body)

    suspend fun delete(path: String, body: JsonElement = EMPTY_BODY): JsonElement = request(HttpMethod.Delete, path, body)

    internal suspend fun delete(path: String, apiToken: String?): JsonElement = request(HttpMethod.Delete, path, EMPTY_BODY, apiToken)

    internal suspend fun <T> get(path: String, deserializer: DeserializationStrategy<T>): T =
        KoelJson.decodeFromJsonElement(deserializer, get(path))

    internal suspend fun <T> getList(path: String, serializer: KSerializer<T>): List<T> =
        get(path, ListSerializer(serializer))

    internal suspend fun <T> getPage(path: String, deserializer: DeserializationStrategy<T>): Page<T> =
        Page.parse(get(path), deserializer)

    private suspend fun request(
        method: HttpMethod,
        path: String,
        body: JsonElement?,
        apiToken: String? = preferences.apiToken,
        timeoutOverride: Duration? = null,
    ): JsonElement {
        val baseUrl = preferences.apiBaseUrl ?: throw NoHostException()

        val response = http.request("$baseUrl/$path") {
            this.method = method
            timeoutOverride?.let { duration ->
                timeout {
                    requestTimeoutMillis = duration.inWholeMilliseconds
                    socketTimeoutMillis = duration.inWholeMilliseconds
                }
            }
            header(HttpHeaders.Accept, ContentType.Application.Json.toString())
            header("X-Api-Version", API_VERSION)
            apiToken?.let { bearerAuth(it) }

            if (body != null) {
                contentType(ContentType.Application.Json)
                setBody(body.toString())
            }
        }

        val text = response.bodyAsText()
        if (preferences.apiToken != apiToken) throw SessionChangedException()
        if (!response.status.isSuccess()) throw HttpResponseException(response.status.value, text)

        return runCatching { KoelJson.parseToJsonElement(text) }.getOrDefault(JsonNull)
    }

    companion object {
        const val API_VERSION = "v6"
        private val EMPTY_BODY = JsonObject(emptyMap())
    }
}

data class Page<T>(val items: List<T>, val nextPage: Int?) {
    companion object {
        internal fun <T> parse(json: JsonElement, deserializer: DeserializationStrategy<T>): Page<T> {
            val root = json.jsonObject
            val items = root.getValue("data").jsonArray.map { KoelJson.decodeFromJsonElement(deserializer, it) }
            val hasNext = root["links"]?.jsonObject?.get("next").let { it != null && it !is JsonNull }
            val currentPage = root["meta"]?.jsonObject?.get("current_page")?.jsonPrimitive?.int ?: 1
            return Page(items, if (hasNext) currentPage + 1 else null)
        }
    }
}
