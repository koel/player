package phanan.koel.shared

import io.ktor.http.HttpMethod
import kotlinx.coroutines.CompletableDeferred
import kotlinx.coroutines.joinAll
import kotlinx.coroutines.launch
import kotlinx.coroutines.test.TestScope
import kotlinx.coroutines.test.UnconfinedTestDispatcher
import kotlinx.coroutines.test.runTest
import kotlinx.io.files.Path
import kotlinx.serialization.json.JsonArray
import kotlinx.serialization.json.JsonObject
import kotlinx.serialization.json.JsonPrimitive
import kotlinx.serialization.json.buildJsonObject
import kotlinx.serialization.json.put
import kotlinx.serialization.json.putJsonObject
import phanan.koel.shared.json.KoelJson
import phanan.koel.shared.models.Playable
import phanan.koel.shared.player.FakeAudioEngine
import phanan.koel.shared.session.Feature
import phanan.koel.shared.storage.InMemoryKeyValueStore
import phanan.koel.shared.support.Fixtures
import phanan.koel.shared.support.Harness
import phanan.koel.shared.support.RecordedRequest
import phanan.koel.shared.support.exists
import phanan.koel.shared.support.temporaryDirectory
import phanan.koel.shared.support.writeText
import kotlin.test.Test
import kotlin.test.assertEquals
import kotlin.test.assertFalse
import kotlin.test.assertNotNull
import kotlin.test.assertNull
import kotlin.test.assertTrue

class KoelCoreTest {
    private val h = Harness()

    private fun TestScope.core() =
        KoelCore(h.keyValueStore, temporaryDirectory().toString(), FakeAudioEngine(), h.engine, backgroundScope)

    private fun dataResponse(version: String = "v8.1.0") = buildJsonObject {
        put("current_version", version)
        put("cdn_url", "https://cdn.koel.test/")
        put("transcoding", true)
        put("use_last_fm", true)
        put("song_count", 42)
        put("playlists", JsonArray(listOf(Fixtures.playlist("p1"), Fixtures.playlist("p2", isSmart = true))))
        put("playlist_folders", JsonArray(listOf(Fixtures.folder("f1"))))
        putJsonObject("queue_state") {
            put("songs", JsonArray(listOf(Fixtures.song("s1"), Fixtures.song("s2"))))
            put("current_song", Fixtures.song("s2"))
            put("playback_position", 12)
        }
    }.toString()

    @Test
    fun theEqualizerReachesTheEngineAndFollowsTheServer() = runTest(UnconfinedTestDispatcher()) {
        val engine = FakeAudioEngine()
        h.on(HttpMethod.Get, "me") {
            """{"id":"u1","name":"Me","email":"me@koel.test","preferences":{"equalizer":{"preamp":-5,"gains":[4,0,0,0,0,0,0,0,0,0]}}}"""
        }
        val core = KoelCore(h.keyValueStore, temporaryDirectory().toString(), engine, h.engine, backgroundScope)
        assertEquals(0.0, engine.equalizer?.preamp)

        core.auth.fetchCurrentUser()

        assertEquals(-5.0, engine.equalizer?.preamp)
        assertEquals(4.0, engine.equalizer?.gains?.first())
    }

    @Test
    fun loggingOutGoesBackToAFlatEqualizerWithoutCrossfade() = runTest(UnconfinedTestDispatcher()) {
        val engine = FakeAudioEngine()
        h.on(HttpMethod.Patch, "me/preferences") { "" }
        h.on(HttpMethod.Delete, "me", status = 404) { "{}" }
        val core = KoelCore(h.keyValueStore, temporaryDirectory().toString(), engine, h.engine, backgroundScope)
        core.playbackSettings.setEqualizer(phanan.koel.shared.models.Equalizer.builtInPresets.last())
        core.playbackSettings.setCrossfadeDuration(5)

        core.logout()

        assertTrue(core.playbackSettings.equalizer.value.isFlat)
        assertEquals(0, core.playbackSettings.crossfadeDuration.value)
        assertTrue(engine.equalizer!!.isFlat)
    }

    @Test
    fun koelPlusServersEvenOutLoudnessUnlessTurnedOff() = runTest(UnconfinedTestDispatcher()) {
        val loudSong = JsonObject(Fixtures.song("s1") + mapOf("loudness" to JsonPrimitive(-8.0), "true_peak" to JsonPrimitive(0.0)))
        h.on(HttpMethod.Get, "data") {
            buildJsonObject {
                put("current_version", "v9.0.0")
                put("playlists", JsonArray(emptyList()))
                putJsonObject("koel_plus") { put("active", true) }
                putJsonObject("queue_state") {
                    put("songs", JsonArray(listOf(loudSong)))
                    put("current_song", loudSong)
                    put("playback_position", 0)
                }
            }.toString()
        }
        h.on(HttpMethod.Put, "queue/state") { "" }
        h.on(HttpMethod.Patch, "me/preferences") { "" }
        val engine = FakeAudioEngine()
        val core = KoelCore(h.keyValueStore, temporaryDirectory().toString(), engine, h.engine, backgroundScope)

        core.loadData()
        assertEquals(-6.0, engine.normalizationGain)

        core.playbackSettings.setNormalizeVolume(false)
        assertEquals(0.0, engine.normalizationGain)
    }

    @Test
    fun loadingDataSeedsServerInfoLibraryAndQueue() = runTest(UnconfinedTestDispatcher()) {
        h.on(HttpMethod.Get, "data") { dataResponse() }
        h.on(HttpMethod.Put, "queue/state") { "" }
        h.on(HttpMethod.Put, "queue/playback-status") { "" }
        val core = core()

        core.loadData()

        val info = core.session.serverInfo.value!!
        assertEquals(42, info.songCount)
        assertTrue(info.transcoding)
        assertTrue(core.session.supports(Feature.RADIO_STATIONS))
        assertFalse(core.session.supports(Feature.CUSTOM_FAVORITES_ORDER))
        assertEquals(listOf("p1", "p2"), core.playlists.playlists.value.map { it.id })
        assertEquals(listOf("f1"), core.playlistFolders.folders.value.map { it.id })
        assertEquals(listOf("s1", "s2"), core.player.state.value.queue.map { it.id })
        assertEquals("s2", core.player.state.value.current?.id)
        assertTrue(core.session.sourceUrl(core.playables.byId("s1")!!).startsWith("https://cdn.koel.test/play/s1/1/128"))
    }

    @Test
    fun oldServersStillLoadWithoutFoldersOrQueueSync() = runTest(UnconfinedTestDispatcher()) {
        h.on(HttpMethod.Get, "data") {
            buildJsonObject {
                put("current_version", "v5.1.0")
                put("playlists", JsonArray(emptyList()))
            }.toString()
        }
        val core = core()

        core.loadData()

        assertFalse(core.session.supports(Feature.QUEUE_STATE_SYNC))
        assertTrue(core.playlistFolders.folders.value.isEmpty())
        assertTrue(core.player.state.value.queue.isEmpty())
    }

    @Test
    fun loggingOutForgetsTheUserAndTheirLibrary() = runTest(UnconfinedTestDispatcher()) {
        h.on(HttpMethod.Get, "data") { dataResponse() }
        h.on(HttpMethod.Put, "queue/state") { "" }
        h.on(HttpMethod.Put, "queue/playback-status") { "" }
        h.on(HttpMethod.Delete, "me") { "" }
        val core = core()
        core.loadData()

        core.logout()

        assertNull(h.preferences.apiToken)
        assertNull(core.session.serverInfo.value)
        assertTrue(core.playlists.playlists.value.isEmpty())
        assertTrue(core.player.state.value.queue.isEmpty())
        assertNull(core.playables.byId("s1"))
    }

    @Test
    fun requestsInFlightWhileLoggingOutLeaveNoDataBehind() = runTest(UnconfinedTestDispatcher()) {
        val serverAnswers = CompletableDeferred<Unit>()
        fun answerAfterLogout(body: String): suspend (RecordedRequest) -> Harness.Reply = {
            serverAnswers.await()
            Harness.Reply(200, body)
        }
        h.onRequest(HttpMethod.Get, "songs/favorite", answerAfterLogout(Fixtures.list(Fixtures.song("s1", favorite = true))))
        h.onRequest(HttpMethod.Get, "songs/recently-played", answerAfterLogout(Fixtures.list(Fixtures.song("s2"))))
        h.onRequest(HttpMethod.Get, "albums", answerAfterLogout(Fixtures.page(listOf(Fixtures.album("a1")), currentPage = 1).toString()))
        h.on(HttpMethod.Delete, "me") { "" }
        val core = core()
        val requests = listOf(
            launch { runCatching { core.favorites.fetch() } },
            launch { runCatching { core.recentlyPlayed.fetch() } },
            launch { runCatching { core.albums.loadMore() } },
        )

        core.logout()
        serverAnswers.complete(Unit)
        requests.joinAll()

        assertTrue(core.favorites.items.value.isEmpty())
        assertTrue(core.recentlyPlayed.items.value.isEmpty())
        assertFalse(core.recentlyPlayed.loaded.value)
        assertTrue(core.albums.items.value.isEmpty())
        assertTrue(core.albums.hasMore.value)
        assertNull(core.playables.byId("s1"))
    }

    @Test
    fun aTokenRejectedAtLaunchLogsOutLocallyWithoutCallingTheServer() = runTest(UnconfinedTestDispatcher()) {
        val engine = FakeAudioEngine()
        h.on(HttpMethod.Get, "data") { dataResponse() }
        h.on(HttpMethod.Put, "queue/state") { "" }
        h.on(HttpMethod.Put, "queue/playback-status") { "" }
        h.on(HttpMethod.Patch, "me/preferences", status = 500) { "" }
        h.on(HttpMethod.Get, "me", status = 401) { """{"message":"Unauthenticated."}""" }
        val core = KoelCore(h.keyValueStore, temporaryDirectory().toString(), engine, h.engine, backgroundScope)
        core.loadData()
        core.playbackSettings.setCrossfadeDuration(5)

        assertNull(core.auth.fetchCurrentUser())

        assertNull(h.preferences.apiToken)
        assertNull(core.session.serverInfo.value)
        assertTrue(core.playlists.playlists.value.isEmpty())
        assertTrue(core.player.state.value.queue.isEmpty())
        assertTrue(engine.stopCount > 0)
        assertEquals(0, core.playbackSettings.crossfadeDuration.value)
        assertTrue(h.preferences.unsyncedPlaybackSettings.isEmpty())
        assertTrue(h.requestsTo(HttpMethod.Delete, "me").isEmpty())
    }

    @Test
    fun downloadsFromAFlutterQrLoginStayListedOnceTheServerConfirmsTheEmail() = runTest(UnconfinedTestDispatcher()) {
        val documents = flutterDocuments(email = null)
        Path(documents, "75b71484992804d510c5975c1ab2ee61cd7bc6d2b8c17fcbb577fe3e72aea66b/CACHE_s1.mp3").writeText("one")
        val core = KoelCore(InMemoryKeyValueStore(), documents.toString(), FakeAudioEngine(), h.engine, backgroundScope)

        core.migrateFlutterData()
        assertEquals(listOf("s1"), core.downloads.playables.value.map { it.id })

        core.auth.fetchCurrentUser()
        core.downloads.load()

        assertEquals(listOf("s1"), core.downloads.playables.value.map { it.id })
        assertTrue(Path(documents, "$CONFIRMED_USER_DIRECTORY/CACHE_s1.mp3").exists())
    }

    @Test
    fun flutterQrLoginDownloadsSurviveTheMigratedTokenBeingRejected() = runTest(UnconfinedTestDispatcher()) {
        val documents = flutterDocuments(email = null)
        Path(documents, "75b71484992804d510c5975c1ab2ee61cd7bc6d2b8c17fcbb577fe3e72aea66b/CACHE_s1.mp3").writeText("one")
        val core = KoelCore(InMemoryKeyValueStore(), documents.toString(), FakeAudioEngine(), h.engine, backgroundScope)
        core.migrateFlutterData()
        h.on(HttpMethod.Get, "me", status = 401) { """{"message":"Unauthenticated."}""" }
        assertNull(core.auth.fetchCurrentUser())

        h.on(HttpMethod.Post, "me/otp") { """{"token":"new-api","audio-token":"new-audio"}""" }
        h.on(HttpMethod.Get, "me") { Fixtures.user(email = "me@koel.test").toString() }
        core.auth.loginWithOneTimeToken("https://koel.test", "otp")
        core.auth.fetchCurrentUser()
        core.downloads.load()

        assertEquals(listOf("s1"), core.downloads.playables.value.map { it.id })
        assertTrue(Path(documents, "$CONFIRMED_USER_DIRECTORY/CACHE_s1.mp3").exists())
    }

    @Test
    fun downloadsFiledUnderADifferentlyCasedFlutterEmailStayListed() = runTest(UnconfinedTestDispatcher()) {
        val documents = flutterDocuments(email = "Me@Koel.test")
        Path(documents, "$CONFIRMED_USER_DIRECTORY/CACHE_s1.mp3").writeText("one")
        val core = KoelCore(InMemoryKeyValueStore(), documents.toString(), FakeAudioEngine(), h.engine, backgroundScope)

        core.migrateFlutterData()
        core.auth.fetchCurrentUser()
        core.downloads.load()

        assertEquals(listOf("s1"), core.downloads.playables.value.map { it.id })
    }

    @Test
    fun loggingOutForgetsTheLastDownloadSync() = runTest(UnconfinedTestDispatcher()) {
        h.on(HttpMethod.Get, "/play/s1") { "audio" }
        h.on(HttpMethod.Post, "songs/by-ids", status = 500) { "{}" }
        h.on(HttpMethod.Delete, "me") { "" }
        val core = core()
        core.downloads.download(KoelJson.decodeFromJsonElement(Playable.serializer(), Fixtures.song("s1")))
        core.downloadSync.sync()
        assertNotNull(core.downloadSync.lastSyncResult.value)

        core.logout()

        assertNull(core.downloadSync.lastSyncResult.value)
    }

    /** Flutter's preferences and download list, with the email it had stored (none after a QR login). */
    private fun flutterDocuments(email: String?): Path {
        val documents = temporaryDirectory()
        val emailField = email?.let { ""","email":"$it"""" }.orEmpty()
        Path(documents, "Preferences.gs").writeText("""{"hostUrl":"https://koel.test","apiToken":"api"$emailField}""")
        Path(documents, "Downloads.gs").writeText("""{"https://koel.test.$email.songs":[${Fixtures.song("s1")}]}""")
        h.on(HttpMethod.Get, "me") { Fixtures.user(email = "me@koel.test").toString() }
        return documents
    }

    private companion object {
        /** sha256("https://koel.test" + "me@koel.test"), as the Flutter app named the folder. */
        const val CONFIRMED_USER_DIRECTORY = "3c45a7678675b4b10b0c258aa8d0adb2799d721e0b2df2ceeffea9d802b8ce7b"
    }
}
