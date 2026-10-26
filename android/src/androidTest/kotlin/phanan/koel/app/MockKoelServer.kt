package phanan.koel.app

import mockwebserver3.Dispatcher
import mockwebserver3.MockResponse
import mockwebserver3.MockWebServer
import mockwebserver3.RecordedRequest
import okio.Buffer
import org.json.JSONArray
import org.json.JSONObject
import java.util.concurrent.ConcurrentHashMap
import java.util.concurrent.TimeUnit

/** A stand-in Koel server, so UI tests run without a real one. Streams a short tone for every song. */
class MockKoelServer(private val audio: ByteArray) {
    private val server = MockWebServer()

    val host: String get() = server.url("/").toString().trimEnd('/')

    fun start() {
        server.dispatcher = object : Dispatcher() {
            override fun dispatch(request: RecordedRequest): MockResponse = respond(request)
        }
        server.start()
    }

    fun stop() = server.close()

    /** Newer Koel servers list saved equalizer presets with the user's preferences; older ones leave them out. */
    @Volatile
    var keepsEqualizerPresets = false

    @Volatile
    var streamsAudio = true

    @Volatile
    var requiresTwoFactor = false

    @Volatile
    var canManageRadioStations = true

    @Volatile
    var checksLoginSlowly = false

    @Volatile
    var logsInSlowly = false

    @Volatile
    var rejectsToken = false

    @Volatile
    var logsOutSlowly = false

    @Volatile
    var verifiesTwoFactorSlowly = false

    /** Answers every API request with a server error, as a server that is up but broken does. */
    @Volatile
    var failsRequests = false

    @Volatile
    var hasPlaylistFolders = false

    /** Title-sorted genre pages arrive late, so a sort change can overtake them. */
    @Volatile
    var slowsTitleSortedGenrePages = false

    @Volatile
    var failsLaterGenrePages = false

    var twoFactorCode: String? = null

    private val requestCounts = ConcurrentHashMap<String, Int>()
    private val lastQueries = ConcurrentHashMap<String, String>()

    /** How many times [path] was requested, e.g. "/api/songs/favorite". */
    fun requestCount(path: String): Int = requestCounts[path] ?: 0

    fun lastQuery(path: String): String? = lastQueries[path]

    private fun respond(request: RecordedRequest): MockResponse {
        val path = request.url.encodedPath
        requestCounts.merge(path, 1, Int::plus)
        request.url.encodedQuery?.let { lastQueries[path] = it }
        if (path.startsWith("/play/") || path.startsWith("/radio/stream/")) {
            return if (streamsAudio) audioResponse(request.headers["Range"]) else MockResponse.Builder().code(404).body("{}").build()
        }

        if (failsRequests && path.startsWith("/api/")) return MockResponse.Builder().code(500).body("{}").build()

        return when (request.method to path) {
            "POST" to "/api/me" -> json(
                if (requiresTwoFactor) JSONObject().put("two_factor", true).put("login_token", "login-token") else tokens(),
                delaySeconds = if (logsInSlowly) SLOW_LOGIN_SECONDS else 0,
            )
            "POST" to "/api/me/two-factor-challenge" -> {
                twoFactorCode = JSONObject(request.body?.utf8() ?: "{}").optString("code")
                json(tokens(), delaySeconds = if (verifiesTwoFactorSlowly) SLOW_LOGIN_SECONDS else 0)
            }
            "GET" to "/api/me" -> if (rejectsToken) {
                MockResponse.Builder().code(401).body("{}").build()
            } else {
                json(user(), delaySeconds = if (checksLoginSlowly) SLOW_LOGIN_CHECK_SECONDS else 0)
            }
            "DELETE" to "/api/me" -> json(JSONObject(), delaySeconds = if (logsOutSlowly) SLOW_LOGOUT_SECONDS else 0)
            "PATCH" to "/api/me/preferences" -> json(JSONObject())
            "POST" to "/api/me/equalizer-presets" -> json(JSONObject(request.body?.utf8() ?: "{}").put("id", "saved-preset-2"))
            "DELETE" to "/api/me/equalizer-presets/$SAVED_PRESET_ID" -> json(JSONObject())
            "GET" to "/api/data" -> json(
                JSONObject()
                    .put("current_version", "v8.0.0")
                    .put("cdn_url", host)
                    .put("song_count", SONG_TITLES.size)
                    .put("playlists", JSONArray().put(playlist))
                    .put("playlist_folders", JSONArray()),
            )
            "GET" to "/api/overview" -> json(
                JSONObject()
                    .put("recently_played_songs", songs(4))
                    .put("most_played_songs", songs(3))
                    .put("recently_added_songs", songs(6))
                    .put("recently_added_albums", JSONArray().put(album))
                    .put("recently_added_episodes", JSONArray().put(episodes.getJSONObject(2))),
            )
            "GET" to "/api/artists/artist-1" -> json(JSONObject().put("type", "artists").put("id", "artist-1").put("name", "Test Artist").put("image", ""))
            "GET" to "/api/artists/artist-1/songs" -> json(songs())
            "GET" to "/api/albums" -> json(JSONObject().put("data", JSONArray().put(album)).put("links", JSONObject().put("next", JSONObject.NULL)).put("meta", JSONObject().put("current_page", 1)))
            "GET" to "/api/albums/album-1" -> json(album)
            "GET" to "/api/albums/album-1/songs" -> json(songs())
            "GET" to "/api/songs" -> json(JSONObject().put("data", songs()).put("links", JSONObject().put("next", JSONObject.NULL)).put("meta", JSONObject().put("current_page", 1)))
            "GET" to "/api/playlists" -> json(JSONArray().put(playlist))
            "GET" to "/api/playlists/playlist-1/songs" -> json(songs(PLAYLIST_SONG_COUNT))
            "POST" to "/api/playlists/playlist-1/songs" -> json(JSONObject())
            "POST" to "/api/playlists" -> json(
                JSONObject(playlist.toString()).put("id", "playlist-2").put("name", JSONObject(request.body?.utf8() ?: "{}").optString("name")),
            )
            "GET" to "/api/playlist-folders" -> json(if (hasPlaylistFolders) JSONArray().put(playlistFolder) else JSONArray())
            "GET" to "/api/podcasts" -> json(JSONArray().put(podcast))
            "GET" to "/api/podcasts/podcast-1" -> json(podcast)
            "GET" to "/api/podcasts/podcast-1/episodes" -> json(episodes)
            "GET" to "/api/queue/fetch" -> json(songs())
            "GET" to "/api/radio/stations" -> json(JSONArray())
            "GET" to "/api/genres" -> json(JSONArray().put(genre))
            "GET" to "/api/genres/genre-1/songs" -> genreSongs(request)
            "GET" to "/api/songs/recently-played" -> json(songs(4))
            "GET" to "/api/songs/favorite" -> json(songs(FAVORITE_COUNT))
            "GET" to "/api/search" -> json(JSONObject().put("songs", songs(SEARCH_RESULT_COUNT)), delaySeconds = SEARCH_DELAY_SECONDS)
            "PUT" to "/api/queue/state", "PUT" to "/api/queue/playback-status", "POST" to "/api/interaction/play" -> json(JSONObject())
            else -> MockResponse.Builder().code(404).body("{}").build()
        }
    }

    private fun user(): JSONObject {
        val preferences = JSONObject()
        if (keepsEqualizerPresets) {
            val savedPreset = JSONObject()
                .put("id", SAVED_PRESET_ID)
                .put("name", SAVED_PRESET_NAME)
                .put("preamp", 0)
                .put("gains", JSONArray(List(10) { 3 }))
            preferences.put("equalizer_presets", JSONArray().put(savedPreset))
        }
        val abilities = if (canManageRadioStations) JSONArray().put("manage radio stations") else JSONArray()
        return JSONObject().put("type", "users").put("id", "user-1").put("name", "Tester").put("email", EMAIL).put("avatar", "")
            .put("preferences", preferences).put("abilities", abilities)
    }

    private val album = JSONObject()
        .put("type", "albums")
        .put("id", "album-1")
        .put("name", ALBUM_NAME)
        .put("artist_id", "artist-1")
        .put("artist_name", "Test Artist")
        .put("permissions", JSONObject().put("edit", true))

    private val genre = JSONObject().put("type", "genres").put("id", "genre-1").put("name", GENRE_NAME).put("song_count", GENRE_FIRST_PAGE_SIZE + 1)

    private fun genreSongs(request: RecordedRequest): MockResponse {
        val page = request.url.queryParameter("page")?.toIntOrNull() ?: 1
        val isSortedByTitle = request.url.queryParameter("sort") == "title"
        return when {
            failsLaterGenrePages && page > 1 -> MockResponse.Builder().code(500).body("{}").build()
            !isSortedByTitle -> json(
                JSONObject()
                    .put("data", JSONArray().put(song("genre-other-sort", GENRE_OTHER_SORT_SONG, 1)))
                    .put("links", JSONObject().put("next", JSONObject.NULL))
                    .put("meta", JSONObject().put("current_page", 1)),
            )
            else -> json(genreSongsPage(page), delaySeconds = if (slowsTitleSortedGenrePages) SLOW_GENRE_PAGE_SECONDS else 0)
        }
    }

    /** A first page long enough for the side index, then a last page with [GENRE_LAST_PAGE_SONG]. */
    private fun genreSongsPage(page: Int): JSONObject {
        val titles = if (page == 1) List(GENRE_FIRST_PAGE_SIZE) { "Genre Song %03d".format(it + 1) } else listOf(GENRE_LAST_PAGE_SONG)
        val songs = JSONArray(titles.mapIndexed { index, title -> song("genre-$page-${index + 1}", title, index + 1) })
        val next = if (page == 1) "$host/api/genres/genre-1/songs?page=2" else JSONObject.NULL
        return JSONObject().put("data", songs).put("links", JSONObject().put("next", next)).put("meta", JSONObject().put("current_page", page))
    }

    private val playlist = JSONObject()
        .put("type", "playlists")
        .put("id", "playlist-1")
        .put("name", PLAYLIST_NAME)
        .put("permissions", JSONObject().put("edit", true).put("delete", true))

    private val playlistFolder = JSONObject().put("type", "playlist-folders").put("id", "folder-1").put("name", PLAYLIST_FOLDER_NAME)

    private val podcast = JSONObject().put("type", "podcasts").put("id", "podcast-1").put("title", PODCAST_TITLE).put("author", "Test Host")


    private val episodes = JSONArray(
        (1..3).map { number ->
            JSONObject()
                .put("type", "episodes")
                .put("id", "episode-$number")
                .put("title", "Episode $number")
                .put("podcast_id", "podcast-1")
                .put("podcast_title", PODCAST_TITLE)
                .put("length", 30.0)
                .put("created_at", "2024-01-0${number}T00:00:00Z")
        },
    )

    private fun songs(limit: Int = SONG_TITLES.size) = JSONArray(
        SONG_TITLES.take(limit).mapIndexed { index, title -> song("song-${index + 1}", title, index + 1) },
    )

    private fun song(id: String, title: String, track: Int) = JSONObject()
        .put("type", "songs")
        .put("id", id)
        .put("title", title)
        .put("album_id", "album-1")
        .put("album_name", ALBUM_NAME)
        .put("artist_id", "artist-1")
        .put("artist_name", "Test Artist")
        .put("length", 30.0)
        .put("track", track)
        .put("created_at", "2024-01-01T00:00:00Z")

    private fun tokens() = JSONObject().put("token", TOKEN).put("audio-token", TOKEN)

    private fun json(body: Any, delaySeconds: Long = 0) = MockResponse.Builder()
        .headersDelay(delaySeconds, TimeUnit.SECONDS)
        .addHeader("Content-Type", "application/json")
        .body(body.toString())
        .build()

    /** ExoPlayer asks for byte ranges. */
    private fun audioResponse(range: String?): MockResponse {
        val bounds = range?.removePrefix("bytes=")?.split("-")?.takeIf { range.startsWith("bytes=") }
        val start = bounds?.getOrNull(0)?.toIntOrNull()
        if (start == null || start >= audio.size) {
            return MockResponse.Builder().addHeader("Content-Type", "audio/mpeg").addHeader("Accept-Ranges", "bytes").body(Buffer().write(audio)).build()
        }
        val end = (bounds.getOrNull(1)?.toIntOrNull() ?: (audio.size - 1)).coerceAtMost(audio.size - 1)
        return MockResponse.Builder()
            .code(206)
            .addHeader("Content-Type", "audio/mpeg")
            .addHeader("Accept-Ranges", "bytes")
            .addHeader("Content-Range", "bytes $start-$end/${audio.size}")
            .body(Buffer().write(audio, start, end - start + 1))
            .build()
    }

    companion object {
        val SONG_TITLES = (1..40).map { "Song %02d".format(it) }
        const val FAVORITE_COUNT = 3
        const val ALBUM_NAME = "Test Album"
        const val PLAYLIST_NAME = "Test Playlist"
        const val PLAYLIST_SONG_COUNT = 5
        const val PODCAST_TITLE = "Test Podcast"
        const val GENRE_NAME = "Test Genre"
        const val GENRE_FIRST_PAGE_SIZE = 120
        const val GENRE_LAST_PAGE_SONG = "Later Song"
        const val GENRE_OTHER_SORT_SONG = "Sorted Otherwise"
        const val SLOW_GENRE_PAGE_SECONDS = 3L
        const val PLAYLIST_FOLDER_NAME = "Test Folder"
        const val SEARCH_RESULT_COUNT = 2
        const val SEARCH_DELAY_SECONDS = 2L
        const val SLOW_LOGIN_CHECK_SECONDS = 3L
        const val SLOW_LOGIN_SECONDS = 3L
        const val SLOW_LOGOUT_SECONDS = 2L
        const val TOKEN = "api-token"
        const val EMAIL = "tester@koel.test"
        const val SAVED_PRESET_ID = "saved-preset-1"
        const val SAVED_PRESET_NAME = "My Preset"
        const val PASSWORD = "secret"
    }
}
