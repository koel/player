package phanan.koel.shared

import io.ktor.client.engine.HttpClientEngine
import kotlinx.coroutines.CoroutineScope
import kotlinx.coroutines.MainScope
import kotlinx.serialization.json.JsonObject
import kotlinx.serialization.json.booleanOrNull
import kotlinx.serialization.json.jsonObject
import kotlinx.serialization.json.jsonPrimitive
import phanan.koel.shared.api.ApiClient
import phanan.koel.shared.json.decodeList
import phanan.koel.shared.json.int
import phanan.koel.shared.json.string
import phanan.koel.shared.models.Playlist
import phanan.koel.shared.models.PlaylistFolder
import phanan.koel.shared.player.AudioEngine
import phanan.koel.shared.player.PlayerController
import phanan.koel.shared.player.QueueState
import phanan.koel.shared.session.Feature
import phanan.koel.shared.session.SemanticVersion
import phanan.koel.shared.session.ServerInfo
import phanan.koel.shared.session.Session
import phanan.koel.shared.storage.FlutterDataMigration
import phanan.koel.shared.storage.KeyValueStore
import phanan.koel.shared.storage.Preferences
import phanan.koel.shared.stores.AlbumStore
import phanan.koel.shared.stores.ArtistStore
import phanan.koel.shared.stores.AuthStore
import phanan.koel.shared.stores.DownloadStore
import phanan.koel.shared.stores.DownloadSyncStore
import phanan.koel.shared.stores.FavoriteStore
import phanan.koel.shared.stores.GenreStore
import phanan.koel.shared.stores.MediaInfoStore
import phanan.koel.shared.stores.OverviewStore
import phanan.koel.shared.stores.PlayableStore
import phanan.koel.shared.stores.PlaylistFolderStore
import phanan.koel.shared.stores.PlaylistStore
import phanan.koel.shared.stores.PodcastStore
import phanan.koel.shared.stores.RadioStationStore
import phanan.koel.shared.stores.RecentlyPlayedStore
import phanan.koel.shared.stores.SearchStore

/** Everything the native app talks to, wired together once per launch. */
class KoelCore internal constructor(
    keyValueStore: KeyValueStore,
    private val documentsPath: String,
    audioEngine: AudioEngine,
    httpEngine: HttpClientEngine,
    scope: CoroutineScope = MainScope(),
) {
    val preferences = Preferences(keyValueStore)
    val session = Session(preferences)
    private val api = ApiClient(httpEngine, preferences)

    val auth = AuthStore(api, preferences)
    val playables = PlayableStore(api)
    val albums = AlbumStore(api, playables)
    val artists = ArtistStore(api, playables, albums)
    val genres = GenreStore(api)
    val recentlyPlayed = RecentlyPlayedStore(api, playables)
    val overview = OverviewStore(api, playables, albums, artists, recentlyPlayed)
    val search = SearchStore(api, playables, albums, artists)
    val mediaInfo = MediaInfoStore(api)
    val favorites = FavoriteStore(api, playables)
    val playlists = PlaylistStore(api, playables)
    val playlistFolders = PlaylistFolderStore(api)
    val podcasts = PodcastStore(api)
    val radioStations = RadioStationStore(api)
    val downloads = DownloadStore(api, playables, session, preferences, documentsPath, scope)
    val downloadSync = DownloadSyncStore(api, downloads, playables, scope)

    val player = PlayerController(
        api = api,
        playables = playables,
        session = session,
        preferences = preferences,
        scope = scope,
        engine = audioEngine,
        localFileUrl = downloads::localFileUrl,
        onPlayRegistered = recentlyPlayed::add,
    )

    /** Keeps users who update from the Flutter app logged in, with their downloads. */
    fun migrateFlutterData() {
        FlutterDataMigration(preferences, documentsPath).run()
        downloads.load()
    }

    /** `GET /data`: server facts, playlists, folders and the saved queue. */
    @Throws(Exception::class)
    suspend fun loadData() {
        val data = api.get("data").jsonObject

        session.update(serverInfo(data))
        playlists.seed(data.decodeList("playlists", Playlist.serializer()))
        playlistFolders.seed(data.decodeList("playlist_folders", PlaylistFolder.serializer()))
        downloads.load()

        if (session.supports(Feature.QUEUE_STATE_SYNC)) {
            data["queue_state"]?.let { player.restore(QueueState.parse(it, playables)) }
        }

        downloadSync.syncAfterDelay()
    }

    @Throws(Exception::class)
    suspend fun logout() {
        player.cleanUpUponLogout()
        auth.logout()
        session.update(null)

        playables.reset()
        albums.reset()
        artists.reset()
        genres.reset()
        recentlyPlayed.reset()
        overview.reset()
        search.reset()
        mediaInfo.reset()
        favorites.reset()
        playlists.reset()
        playlistFolders.reset()
        podcasts.reset()
        radioStations.reset()
        downloads.reset()
    }

    private fun serverInfo(data: JsonObject) = ServerInfo(
        version = SemanticVersion.parse(data.string("current_version").orEmpty()),
        cdnUrl = data.string("cdn_url"),
        transcoding = data["transcoding"]?.jsonPrimitive?.booleanOrNull ?: false,
        useLastFm = data["use_last_fm"]?.jsonPrimitive?.booleanOrNull ?: false,
        songCount = data.int("song_count") ?: 0,
    )
}
