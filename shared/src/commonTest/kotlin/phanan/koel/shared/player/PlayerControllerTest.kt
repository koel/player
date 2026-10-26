package phanan.koel.shared.player

import io.ktor.http.HttpMethod
import kotlinx.coroutines.CompletableDeferred
import kotlinx.coroutines.launch
import kotlinx.coroutines.test.TestScope
import kotlinx.coroutines.test.UnconfinedTestDispatcher
import kotlinx.coroutines.test.advanceTimeBy
import kotlinx.coroutines.test.runTest
import kotlinx.serialization.json.JsonArray
import kotlinx.serialization.json.JsonPrimitive
import kotlinx.serialization.json.buildJsonObject
import kotlinx.serialization.json.int
import kotlinx.serialization.json.jsonArray
import kotlinx.serialization.json.jsonPrimitive
import kotlinx.serialization.json.put
import phanan.koel.shared.json.KoelJson
import phanan.koel.shared.models.Episode
import phanan.koel.shared.models.Playable
import phanan.koel.shared.models.QueueState
import phanan.koel.shared.models.RadioStation
import phanan.koel.shared.session.SemanticVersion
import phanan.koel.shared.session.ServerInfo
import phanan.koel.shared.stores.PlayableStore
import phanan.koel.shared.support.Fixtures
import phanan.koel.shared.support.Harness
import kotlin.random.Random
import kotlin.test.Test
import kotlin.test.assertEquals
import kotlin.test.assertFailsWith
import kotlin.test.assertFalse
import kotlin.test.assertNull
import kotlin.test.assertTrue
import kotlin.time.Duration.Companion.seconds

class PlayerControllerTest {
    private val h = Harness()
    private val store = PlayableStore(h.api)
    private val engine = FakeAudioEngine()
    private val localFiles = mutableMapOf<String, String>()
    private val registeredPlays = mutableListOf<Playable>()
    private var crossfadeSeconds = 0
    private val gains = mutableMapOf<String, Double>()
    private var episodeProgress: suspend (Episode) -> Double = { 0.0 }
    private var isOffline = false

    private fun TestScope.player() = PlayerController(
        api = h.api,
        playables = store,
        session = h.session,
        preferences = h.preferences,
        scope = backgroundScope,
        engine = engine,
        localFileUrl = { localFiles[it.id] },
        onPlayRegistered = { registeredPlays += it },
        crossfadeSeconds = { crossfadeSeconds },
        normalizationGain = { gains[it.id] ?: 0.0 },
        episodeProgress = { episodeProgress(it) },
        isOffline = { isOffline },
        random = Random(42),
    )

    private fun songs(vararg ids: String): List<Playable> = store.sync(JsonArray(ids.map { Fixtures.song(it, length = 100.0) }))

    private fun episode(id: String): Playable = store.sync(JsonArray(listOf(Fixtures.episode(id, length = 1000.0)))).single()

    private fun station(id: String, name: String = "Station $id", url: String = "https://stream.example.com/$id") =
        KoelJson.decodeFromJsonElement(RadioStation.serializer(), Fixtures.radioStation(id, name, url))

    private fun url(playable: Playable) = h.session.sourceUrl(playable)

    private fun supportQueueSync() =
        h.session.update(ServerInfo(SemanticVersion(7, 0, 0), cdnUrl = null, transcoding = false, useLastFm = false, songCount = 0))

    private fun acceptQueueSync() {
        h.on(HttpMethod.Put, "queue/state") { "" }
        h.on(HttpMethod.Put, "queue/playback-status") { "" }
    }

    private fun PlayerController.queueIds() = state.value.queue.map(Playable::id)

    // Loading and failures

    @Test
    fun streamsASongThatHasNotBeenDownloaded() = runTest(UnconfinedTestDispatcher()) {
        val player = player()
        val song = songs("s1").single()

        player.replaceQueue(listOf(song), shuffle = false, autoPlay = true)

        assertEquals(listOf(url(song)), engine.loadedUrls)
        assertEquals(1, engine.playCount)
        assertTrue(player.state.value.isPlaying)
        assertEquals("s1", player.state.value.current?.id)
    }

    @Test
    fun playsADownloadedSongFromItsLocalFile() = runTest(UnconfinedTestDispatcher()) {
        val player = player()
        val song = songs("s1").single()
        localFiles["s1"] = "file:///downloads/s1.mp3"

        player.replaceQueue(listOf(song), shuffle = false, autoPlay = true)

        assertEquals(listOf("file:///downloads/s1.mp3"), engine.loadedUrls)
    }

    @Test
    fun givesUpOnASourceThatNeverBecomesPlayable() = runTest(UnconfinedTestDispatcher()) {
        val player = player()
        val song = songs("s1").single()
        engine.stallingUrls += url(song)

        player.replaceQueue(listOf(song), shuffle = false, autoPlay = true)
        assertTrue(player.state.value.isBuffering)
        advanceTimeBy(30.seconds + 1.seconds)

        assertEquals(1, engine.stopCount)
        assertTrue(player.state.value.hasFailed)
        assertFalse(player.state.value.isBuffering)
    }

    @Test
    fun reportsASourceThatFailsOutright() = runTest(UnconfinedTestDispatcher()) {
        val player = player()
        engine.failEveryLoad = true

        player.replaceQueue(songs("s1"), shuffle = false, autoPlay = true)

        assertEquals(1, engine.stopCount)
        assertTrue(player.state.value.hasFailed)
    }

    @Test
    fun playReloadsAFailedItemThatIsNoLongerQueued() = runTest(UnconfinedTestDispatcher()) {
        val player = player()
        val (song) = songs("s1")
        player.replaceQueue(listOf(song), shuffle = false, autoPlay = true)
        engine.failMidStream()
        player.clearQueue()

        player.play()

        assertEquals(2, engine.loadsOf(url(song)))
        assertTrue(player.state.value.isPlaying)
        assertFalse(player.state.value.hasFailed)
    }

    @Test
    fun skipsPastASongTheServerRefusesToServe() = runTest(UnconfinedTestDispatcher()) {
        val player = player()
        val (broken, next) = songs("s1", "s2")
        engine.failingUrls += url(broken)

        player.replaceQueue(listOf(broken, next), shuffle = false, autoPlay = true)

        assertEquals(1, engine.loadsOf(url(next)))
        assertEquals("s2", player.state.value.current?.id)
        assertFalse(player.state.value.hasFailed)
    }

    @Test
    fun staysPutWhenTheLoadStallsInsteadOfSkipping() = runTest(UnconfinedTestDispatcher()) {
        val player = player()
        val (stalled, next) = songs("s1", "s2")
        engine.stallingUrls += url(stalled)

        player.replaceQueue(listOf(stalled, next), shuffle = false, autoPlay = true)
        advanceTimeBy(31.seconds)

        assertEquals(0, engine.loadsOf(url(next)))
        assertEquals("s1", player.state.value.current?.id)
        assertTrue(player.state.value.hasFailed)
    }

    @Test
    fun givesUpOnceTooManySongsFailInARow() = runTest(UnconfinedTestDispatcher()) {
        val player = player()
        engine.failEveryLoad = true

        player.replaceQueue(songs("s1", "s2", "s3", "s4", "s5", "s6"), shuffle = false, autoPlay = true)

        assertEquals(PlayerController.MAX_ERROR_COUNT, engine.loadedUrls.size)
        assertTrue(player.state.value.hasFailed)
    }

    @Test
    fun stopsSkippingAtTheEndOfTheQueue() = runTest(UnconfinedTestDispatcher()) {
        val player = player()
        engine.failEveryLoad = true

        player.replaceQueue(songs("s1"), shuffle = false, autoPlay = true)

        assertEquals(1, engine.loadedUrls.size)
        assertTrue(player.state.value.hasFailed)
    }

    @Test
    fun aSongThatPlaysClearsTheRunOfFailures() = runTest(UnconfinedTestDispatcher()) {
        val player = player()
        val all = songs("s1", "s2", "s3", "s4", "s5", "s6")
        engine.failingUrls += all.map(::url) - url(all[1])

        // Fails on the first song, skips onto the second, which plays.
        player.replaceQueue(all, shuffle = false, autoPlay = true)
        assertEquals("s2", player.state.value.current?.id)

        // The three that follow get a full budget of their own.
        player.skipToNext()

        assertEquals(1, engine.loadsOf(url(all[4])))
        assertEquals(0, engine.loadsOf(url(all[5])))
    }

    @Test
    fun canStillSkipToTheNextSongAfterAStalledLoad() = runTest(UnconfinedTestDispatcher()) {
        val player = player()
        val (stalled, next) = songs("s1", "s2")
        engine.stallingUrls += url(stalled)

        player.replaceQueue(listOf(stalled, next), shuffle = false, autoPlay = true)
        advanceTimeBy(31.seconds)
        player.skipToNext()

        assertEquals(1, engine.loadsOf(url(next)))
        assertFalse(player.state.value.hasFailed)
    }

    @Test
    fun playRetriesTheCurrentSongAfterAFailedLoad() = runTest(UnconfinedTestDispatcher()) {
        val player = player()
        val song = songs("s1").single()
        engine.stallingUrls += url(song)

        player.replaceQueue(listOf(song), shuffle = false, autoPlay = true)
        advanceTimeBy(31.seconds)
        engine.stallingUrls.clear()
        player.play()

        assertEquals(2, engine.loadsOf(url(song)))
        assertFalse(player.state.value.hasFailed)
        assertTrue(player.state.value.isPlaying)
    }

    @Test
    fun surfacesAnErrorEmittedByTheEngineItself() = runTest(UnconfinedTestDispatcher()) {
        val player = player()
        player.replaceQueue(songs("s1"), shuffle = false, autoPlay = true)
        assertFalse(player.state.value.hasFailed)

        engine.failMidStream()

        assertTrue(player.state.value.hasFailed)
        assertEquals(1, engine.stopCount)
    }

    @Test
    fun ignoresALoadThatFinishesAfterAnotherItemWasPicked() = runTest(UnconfinedTestDispatcher()) {
        val player = player()
        val (slow, picked) = songs("s1", "s2")
        engine.stallingUrls += url(slow)

        player.replaceQueue(listOf(slow, picked), shuffle = false, autoPlay = true)
        val staleReady = engine.stalledLoad!!
        player.play(picked)
        staleReady()
        advanceTimeBy(31.seconds)

        assertEquals("s2", player.state.value.current?.id)
        assertFalse(player.state.value.hasFailed)
        assertEquals(1, engine.playCount)
    }

    @Test
    fun pausingWhileTheItemLoadsKeepsItFromPlaying() = runTest(UnconfinedTestDispatcher()) {
        val player = player()
        val song = songs("s1").single()
        engine.stallingUrls += url(song)

        player.replaceQueue(listOf(song), shuffle = false, autoPlay = true)
        player.pause()
        engine.stalledLoad!!()

        assertEquals(0, engine.playCount)
        assertFalse(player.state.value.isPlaying)

        player.play()
        assertEquals(1, engine.playCount)
        assertTrue(player.state.value.isPlaying)
    }

    @Test
    fun pausingWhileTheItemLoadsHoldsAcrossSkippingPastAFailure() = runTest(UnconfinedTestDispatcher()) {
        val player = player()
        val (broken, next) = songs("s1", "s2")
        engine.stallingUrls += url(broken)

        player.replaceQueue(listOf(broken, next), shuffle = false, autoPlay = true)
        player.pause()
        engine.stalledLoadFailure!!("500")

        assertEquals("s2", player.state.value.current?.id)
        assertEquals(0, engine.playCount)
        assertFalse(player.state.value.isPlaying)
    }

    @Test
    fun theEngineStoppingWhileTheItemLoadsKeepsItFromPlaying() = runTest(UnconfinedTestDispatcher()) {
        val player = player()
        val (playing, picked) = songs("s1", "s2")
        player.replaceQueue(listOf(playing, picked), shuffle = false, autoPlay = true)
        engine.reportPlaying(true)
        engine.stallingUrls += url(picked)

        player.play(picked)
        engine.reportPlaying(false)
        engine.stalledLoad!!()

        assertEquals(1, engine.playCount)
        assertFalse(player.state.value.isPlaying)
    }

    @Test
    fun theLastSongPausingAsItEndsDoesNotStopTheNextOne() = runTest(UnconfinedTestDispatcher()) {
        val player = player()
        val (first, second) = songs("s1", "s2")
        player.replaceQueue(listOf(first, second), shuffle = false, autoPlay = true)
        engine.reportPlaying(true)
        engine.stallingUrls += url(second)

        engine.finish()
        engine.reportPlaying(false)
        engine.stalledLoad!!()

        assertEquals("s2", player.state.value.current?.id)
        assertEquals(2, engine.playCount)
    }

    @Test
    fun playAfterAMidStreamFailureResumesWhereItFailed() = runTest(UnconfinedTestDispatcher()) {
        val player = player()
        val song = songs("s1").single()
        player.replaceQueue(listOf(song), shuffle = false, autoPlay = true)
        engine.reachPosition(40.0)

        engine.failMidStream()
        player.play()

        assertEquals(2, engine.loadsOf(url(song)))
        assertEquals(40.0, engine.seeks.last())
        assertTrue(player.state.value.isPlaying)
    }

    @Test
    fun seekingAfterAMidStreamFailureResumesFromTheSeekPosition() = runTest(UnconfinedTestDispatcher()) {
        val player = player()
        val song = songs("s1").single()
        player.replaceQueue(listOf(song), shuffle = false, autoPlay = true)
        engine.reachPosition(40.0)
        engine.failMidStream()

        player.seek(70.0)
        player.play()

        assertEquals(70.0, engine.seeks.last())
        assertEquals(70.0, player.position.value)
    }

    @Test
    fun seekingAfterStoppingResumesFromTheSeekPosition() = runTest(UnconfinedTestDispatcher()) {
        val player = player()
        val song = songs("s1").single()
        player.replaceQueue(listOf(song), shuffle = false, autoPlay = true)
        engine.reachPosition(40.0)
        player.stop()

        player.seek(10.0)
        player.play()

        assertEquals(2, engine.loadsOf(url(song)))
        assertEquals(10.0, engine.seeks.last())
    }

    @Test
    fun stoppingWhileTheItemLoadsCallsOffTheLoad() = runTest(UnconfinedTestDispatcher()) {
        val player = player()
        val song = songs("s1").single()
        engine.stallingUrls += url(song)
        player.replaceQueue(listOf(song), shuffle = false, autoPlay = true)

        player.stop()
        advanceTimeBy(31.seconds)

        assertFalse(player.state.value.hasFailed)
        assertFalse(player.state.value.isBuffering)
        assertEquals(1, engine.stopCount)
    }

    // Queue

    @Test
    fun replacingTheQueueWithoutAutoPlayLoadsNothing() = runTest(UnconfinedTestDispatcher()) {
        val player = player()

        player.replaceQueue(songs("s1", "s2"), shuffle = false, autoPlay = false)

        assertEquals(listOf("s1", "s2"), player.queueIds())
        assertTrue(engine.loadedUrls.isEmpty())
        assertEquals(-1, player.state.value.currentIndex)
    }

    @Test
    fun shufflePlayShufflesTheQueueAndPlaysItsFirstItem() = runTest(UnconfinedTestDispatcher()) {
        val player = player()
        val all = songs("s1", "s2", "s3", "s4", "s5", "s6", "s7", "s8")

        player.replaceQueue(all, shuffle = true, autoPlay = true)

        val queued = player.queueIds()
        assertEquals(all.map(Playable::id).toSet(), queued.toSet())
        assertTrue(queued != all.map(Playable::id))
        assertEquals(queued.first(), player.state.value.current?.id)
    }

    @Test
    fun playingAQueuedItemJumpsToIt() = runTest(UnconfinedTestDispatcher()) {
        val player = player()
        val all = songs("s1", "s2", "s3")
        player.replaceQueue(all, shuffle = false, autoPlay = true)

        player.play(all[2])

        assertEquals(listOf("s1", "s2", "s3"), player.queueIds())
        assertEquals(2, player.state.value.currentIndex)
    }

    @Test
    fun playingAnUnqueuedItemInsertsItAfterTheCurrentOne() = runTest(UnconfinedTestDispatcher()) {
        val player = player()
        val (first, second, outsider) = songs("s1", "s2", "s9")
        player.replaceQueue(listOf(first, second), shuffle = false, autoPlay = true)

        player.play(outsider)

        assertEquals(listOf("s1", "s9", "s2"), player.queueIds())
        assertEquals("s9", player.state.value.current?.id)
        assertEquals(1, player.state.value.currentIndex)
    }

    @Test
    fun playNextMovesAnItemRightAfterTheCurrentOne() = runTest(UnconfinedTestDispatcher()) {
        val player = player()
        val all = songs("s1", "s2", "s3", "s4")
        player.replaceQueue(all, shuffle = false, autoPlay = false)
        player.play(all[1])

        player.playNext(all[3])

        assertEquals(listOf("s1", "s2", "s4", "s3"), player.queueIds())
    }

    @Test
    fun playNextLeavesTheCurrentItemWhereItIs() = runTest(UnconfinedTestDispatcher()) {
        val player = player()
        val all = songs("s1", "s2", "s3")
        player.replaceQueue(all, shuffle = false, autoPlay = false)
        player.play(all[1])

        player.playNext(all[1])

        assertEquals(listOf("s1", "s2", "s3"), player.queueIds())
    }

    @Test
    fun playNextOnSeveralItemsKeepsTheirOrderAndPutsTheQueueOnce() = runTest(UnconfinedTestDispatcher()) {
        supportQueueSync()
        acceptQueueSync()
        val player = player()
        val all = songs("s1", "s2", "s3", "s4", "s5")
        player.replaceQueue(all.take(3), shuffle = false, autoPlay = false)
        player.play(all[0])
        val putsBefore = h.requestsTo(HttpMethod.Put, "queue/state").size

        player.playNext(listOf(all[3], all[0], all[4]))

        assertEquals(listOf("s1", "s4", "s5", "s2", "s3"), player.queueIds())
        assertEquals(putsBefore + 1, h.requestsTo(HttpMethod.Put, "queue/state").size)
    }

    @Test
    fun playNextOnAnEmptyQueueOnlyQueues() = runTest(UnconfinedTestDispatcher()) {
        val player = player()

        player.playNext(songs("s1").single())

        assertEquals(listOf("s1"), player.queueIds())
        assertTrue(engine.loadedUrls.isEmpty())
    }

    @Test
    fun queueToBottomMovesOrAppendsAnItemToTheEnd() = runTest(UnconfinedTestDispatcher()) {
        val player = player()
        val all = songs("s1", "s2", "s3", "s9")
        player.replaceQueue(all.take(3), shuffle = false, autoPlay = false)

        player.queueToBottom(all[0])
        player.queueToBottom(all[3])

        assertEquals(listOf("s2", "s3", "s1", "s9"), player.queueIds())
    }

    @Test
    fun queueToBottomLeavesTheCurrentItemWhereItIs() = runTest(UnconfinedTestDispatcher()) {
        val player = player()
        val all = songs("s1", "s2", "s3")
        player.replaceQueue(all, shuffle = false, autoPlay = true)

        player.queueToBottom(all[0])
        assertEquals(listOf("s1", "s2", "s3"), player.queueIds())

        player.queueToBottom(listOf(all[0], all[1]))
        assertEquals(listOf("s1", "s3", "s2"), player.queueIds())
    }

    @Test
    fun queueToBottomOnSeveralItemsKeepsTheirOrderAndPutsTheQueueOnce() = runTest(UnconfinedTestDispatcher()) {
        supportQueueSync()
        acceptQueueSync()
        val player = player()
        val all = songs("s1", "s2", "s3", "s9")
        player.replaceQueue(all.take(3), shuffle = false, autoPlay = false)
        val putsBefore = h.requestsTo(HttpMethod.Put, "queue/state").size

        player.queueToBottom(listOf(all[0], all[3]))

        assertEquals(listOf("s2", "s3", "s1", "s9"), player.queueIds())
        assertEquals(putsBefore + 1, h.requestsTo(HttpMethod.Put, "queue/state").size)
    }

    @Test
    fun removingAnotherItemFromTheQueueLeavesPlaybackAlone() = runTest(UnconfinedTestDispatcher()) {
        val player = player()
        val all = songs("s1", "s2")
        player.replaceQueue(all, shuffle = false, autoPlay = true)

        player.removeFromQueue(all[1])

        assertEquals(listOf("s1"), player.queueIds())
        assertEquals("s1", player.state.value.current?.id)
        assertEquals(1, engine.loadedUrls.size)
    }

    @Test
    fun removingTheCurrentItemFromTheQueueMovesOnToTheNext() = runTest(UnconfinedTestDispatcher()) {
        val player = player()
        val all = songs("s1", "s2", "s3")
        player.replaceQueue(all, shuffle = false, autoPlay = true)

        player.removeFromQueue(all[0])
        player.skipToNext()

        assertEquals(listOf("s2", "s3"), player.queueIds())
        assertEquals("s3", player.state.value.current?.id)
        assertEquals(1, player.state.value.currentIndex)
    }

    @Test
    fun removingTheCurrentItemByIndexMovesOnToTheNext() = runTest(UnconfinedTestDispatcher()) {
        val player = player()
        player.replaceQueue(songs("s1", "s2", "s3"), shuffle = false, autoPlay = true)

        player.removeAt(0)

        assertEquals(listOf("s2", "s3"), player.queueIds())
        assertEquals("s2", player.state.value.current?.id)
        assertEquals(0, player.state.value.currentIndex)
    }

    @Test
    fun removingAnotherItemByIndexKeepsTheCurrentOne() = runTest(UnconfinedTestDispatcher()) {
        val player = player()
        player.replaceQueue(songs("s1", "s2", "s3"), shuffle = false, autoPlay = true)

        player.removeAt(2)
        player.removeAt(5)

        assertEquals(listOf("s1", "s2"), player.queueIds())
        assertEquals(1, engine.loadedUrls.size)
    }

    @Test
    fun movingUsesTheDropPositionOfAReorderableList() = runTest(UnconfinedTestDispatcher()) {
        val player = player()
        player.replaceQueue(songs("s1", "s2", "s3", "s4"), shuffle = false, autoPlay = true)

        player.move(0, 3)
        assertEquals(listOf("s2", "s3", "s1", "s4"), player.queueIds())
        assertEquals(2, player.state.value.currentIndex)

        player.move(3, 0)
        assertEquals(listOf("s4", "s2", "s3", "s1"), player.queueIds())
        assertEquals(3, player.state.value.currentIndex)
    }

    @Test
    fun clearingTheQueueEmptiesIt() = runTest(UnconfinedTestDispatcher()) {
        val player = player()
        val all = songs("s1", "s2")
        player.replaceQueue(all, shuffle = false, autoPlay = false)

        player.clearQueue()

        assertTrue(player.state.value.queue.isEmpty())
        assertFalse(player.isQueued(all[0]))
    }

    @Test
    fun theQueueFollowsChangesMadeInTheVault() = runTest(UnconfinedTestDispatcher()) {
        val player = player()
        player.replaceQueue(songs("s1", "s2"), shuffle = false, autoPlay = true)

        store.update("s1") { it.withFavorite(true) }

        assertTrue(player.state.value.queue.first().favorite)
        assertTrue(player.state.value.current!!.favorite)
    }

    // Navigation

    @Test
    fun skipToNextStopsAtTheEndUnlessRepeatingAll() = runTest(UnconfinedTestDispatcher()) {
        val player = player()
        player.replaceQueue(songs("s1", "s2"), shuffle = false, autoPlay = true)

        player.skipToNext()
        player.skipToNext()
        assertEquals("s2", player.state.value.current?.id)

        player.rotateRepeatMode()
        player.skipToNext()
        assertEquals("s1", player.state.value.current?.id)
    }

    @Test
    fun skipToPreviousRestartsAnItemPastItsFirstFiveSeconds() = runTest(UnconfinedTestDispatcher()) {
        val player = player()
        player.replaceQueue(songs("s1", "s2"), shuffle = false, autoPlay = true)
        player.skipToNext()

        engine.reachPosition(6.0)
        player.skipToPrevious()
        assertEquals("s2", player.state.value.current?.id)
        assertEquals(0.0, engine.seeks.last())

        engine.reachPosition(3.0)
        player.skipToPrevious()
        assertEquals("s1", player.state.value.current?.id)
    }

    @Test
    fun skipToPreviousWrapsOnlyWhenRepeatingAll() = runTest(UnconfinedTestDispatcher()) {
        val player = player()
        player.replaceQueue(songs("s1", "s2"), shuffle = false, autoPlay = true)

        player.skipToPrevious()
        assertEquals("s1", player.state.value.current?.id)

        player.rotateRepeatMode()
        player.skipToPrevious()
        assertEquals("s2", player.state.value.current?.id)
    }

    @Test
    fun finishingAnItemPlaysTheNextOne() = runTest(UnconfinedTestDispatcher()) {
        val player = player()
        player.replaceQueue(songs("s1", "s2"), shuffle = false, autoPlay = true)

        engine.finish()
        assertEquals("s2", player.state.value.current?.id)

        engine.finish()
        assertEquals("s2", player.state.value.current?.id)
        assertFalse(player.state.value.isPlaying)
    }

    @Test
    fun playAfterTheQueueFinishedStartsTheLastItemOver() = runTest(UnconfinedTestDispatcher()) {
        val player = player()
        player.replaceQueue(songs("s1"), shuffle = false, autoPlay = true)
        engine.reachPosition(100.0)
        engine.finish()

        player.play()

        assertEquals(0.0, engine.seeks.last())
        assertTrue(player.state.value.isPlaying)
    }

    @Test
    fun playAfterSeekingAFinishedQueueContinuesFromTheSeekedSpot() = runTest(UnconfinedTestDispatcher()) {
        val player = player()
        player.replaceQueue(songs("s1"), shuffle = false, autoPlay = true)
        engine.reachPosition(100.0)
        engine.finish()

        player.seek(30.0)
        player.play()

        assertEquals(30.0, engine.seeks.last())
        assertEquals(30.0, engine.position)
        assertTrue(player.state.value.isPlaying)
    }

    @Test
    fun repeatOneRestartsTheItemWhenItFinishes() = runTest(UnconfinedTestDispatcher()) {
        val player = player()
        player.replaceQueue(songs("s1", "s2"), shuffle = false, autoPlay = true)
        player.rotateRepeatMode()
        player.rotateRepeatMode()

        engine.reachPosition(99.0)
        engine.finish()

        assertEquals("s1", player.state.value.current?.id)
        assertEquals(0.0, engine.seeks.last())
        assertEquals(2, engine.playCount)
    }

    @Test
    fun rotatingTheRepeatModePersistsIt() = runTest(UnconfinedTestDispatcher()) {
        val player = player()

        assertEquals(RepeatMode.ALL, player.rotateRepeatMode())
        assertEquals(RepeatMode.ALL, h.preferences.repeatMode)
        assertEquals(RepeatMode.ALL, player.state.value.repeatMode)
        assertEquals(RepeatMode.ONE, player.rotateRepeatMode())
        assertEquals(RepeatMode.NONE, player.rotateRepeatMode())
    }

    @Test
    fun startsWithTheSavedRepeatModeAndVolume() = runTest(UnconfinedTestDispatcher()) {
        h.preferences.repeatMode = RepeatMode.ONE
        h.preferences.volume = 0.4

        val player = player()

        assertEquals(RepeatMode.ONE, player.state.value.repeatMode)
        assertEquals(0.4, engine.volume)
    }

    @Test
    fun settingTheVolumeAppliesAndPersistsIt() = runTest(UnconfinedTestDispatcher()) {
        val player = player()

        player.setVolume(0.25)

        assertEquals(0.25, engine.volume)
        assertEquals(0.25, h.preferences.volume)
        assertEquals(0.25, player.state.value.volume)
    }

    // Transport

    @Test
    fun pauseAndToggleDriveTheEngine() = runTest(UnconfinedTestDispatcher()) {
        val player = player()
        player.replaceQueue(songs("s1"), shuffle = false, autoPlay = true)

        player.togglePlayPause()
        assertFalse(player.state.value.isPlaying)
        assertEquals(1, engine.pauseCount)

        player.togglePlayPause()
        assertTrue(player.state.value.isPlaying)
        assertEquals(2, engine.playCount)
    }

    @Test
    fun seekingMovesThePlayhead() = runTest(UnconfinedTestDispatcher()) {
        val player = player()
        player.replaceQueue(songs("s1"), shuffle = false, autoPlay = true)

        player.seek(42.0)

        assertEquals(42.0, engine.seeks.last())
        assertEquals(42.0, player.position.value)
    }

    @Test
    fun playAfterStopReloadsTheItemWhereItStopped() = runTest(UnconfinedTestDispatcher()) {
        val player = player()
        val song = songs("s1").single()
        player.replaceQueue(listOf(song), shuffle = false, autoPlay = true)
        engine.reachPosition(12.0)

        player.stop()
        assertFalse(player.state.value.isPlaying)
        player.play()

        assertEquals(2, engine.loadsOf(url(song)))
        assertEquals(12.0, engine.seeks.last())
        assertTrue(player.state.value.isPlaying)
    }

    @Test
    fun cleaningUpUponLogoutStopsAndForgetsEverything() = runTest(UnconfinedTestDispatcher()) {
        val player = player()
        player.replaceQueue(songs("s1"), shuffle = false, autoPlay = true)

        player.cleanUpUponLogout()

        assertEquals(1, engine.stopCount)
        assertEquals(PlaybackState(volume = h.preferences.volume), player.state.value)
    }

    @Test
    fun aQueueRestoredAfterLogoutResumesWhereItWasSaved() = runTest(UnconfinedTestDispatcher()) {
        supportQueueSync()
        acceptQueueSync()
        val player = player()
        val (finished, saved) = songs("s1", "s2")
        player.replaceQueue(listOf(finished), shuffle = false, autoPlay = true)
        engine.reachPosition(100.0)
        engine.finish()

        player.cleanUpUponLogout()
        player.restore(QueueState(listOf(saved), saved, 42.0))
        player.play()

        assertEquals(1, engine.loadsOf(url(saved)))
        assertEquals(42.0, engine.seeks.last())
    }

    @Test
    fun aSongFadingAtLogoutFadesAgainAfterwards() = runTest(UnconfinedTestDispatcher()) {
        crossfadeSeconds = 5
        val player = player()
        val queue = songs("s1", "s2")
        engine.stallingUrls += url(queue[1])
        player.replaceQueue(queue, shuffle = false, autoPlay = true)
        engine.reachPosition(95.0)

        player.cleanUpUponLogout()
        engine.stallingUrls.clear()
        player.replaceQueue(queue, shuffle = false, autoPlay = true)
        engine.reachPosition(95.0)

        assertEquals(2, engine.crossfades.size)
        assertEquals("s2", player.state.value.current?.id)
    }

    @Test
    fun cleaningUpUponLogoutLeavesTheServerQueueAlone() = runTest(UnconfinedTestDispatcher()) {
        supportQueueSync()
        acceptQueueSync()
        val player = player()
        player.replaceQueue(songs("s1"), shuffle = false, autoPlay = true)
        val putsBefore = h.requestsTo(HttpMethod.Put, "queue/state").size

        player.cleanUpUponLogout()

        assertEquals(putsBefore, h.requestsTo(HttpMethod.Put, "queue/state").size)
    }

    // Episodes

    @Test
    fun anEpisodeResumesWhereItWasLeftOff() = runTest(UnconfinedTestDispatcher()) {
        val player = player()
        val podcastEpisode = episode("e1")
        player.rememberPosition("e1", 300.0)

        player.play(podcastEpisode)

        assertEquals(300.0, engine.seeks.last())
        assertEquals(300.0, player.position.value)
    }

    @Test
    fun anEpisodeFirstLooksUpWhereItWasLeftOff() = runTest(UnconfinedTestDispatcher()) {
        episodeProgress = { 300.0 }
        val player = player()

        player.play(episode("e1"))

        assertEquals("e1", player.state.value.current?.id)
        assertEquals(300.0, engine.seeks.last())
    }

    @Test
    fun aSongPickedWhileAnEpisodeLooksUpItsPositionKeepsPlaying() = runTest(UnconfinedTestDispatcher()) {
        val lookup = CompletableDeferred<Double>()
        episodeProgress = { lookup.await() }
        val player = player()
        val podcastEpisode = episode("e1")
        val (song) = songs("s1")

        player.play(podcastEpisode)
        player.play(song)
        lookup.complete(300.0)

        assertEquals("s1", player.state.value.current?.id)
        assertEquals(listOf(url(song)), engine.loadedUrls)
    }

    @Test
    fun anEpisodeLeftOffAtItsEndStartsOver() = runTest(UnconfinedTestDispatcher()) {
        episodeProgress = { 999.5 }
        val player = player()

        player.play(episode("e1"))

        assertEquals(0.0, engine.seeks.last())
    }

    @Test
    fun anEpisodeLeftOffAtItsLastProgressReportStartsOver() = runTest(UnconfinedTestDispatcher()) {
        episodeProgress = { 995.0 }
        val player = player()

        player.play(episode("e1"))

        assertEquals(0.0, engine.seeks.last())
    }

    @Test
    fun offlineAnEpisodePlaysWithoutLookingUpWhereItWasLeftOff() = runTest(UnconfinedTestDispatcher()) {
        episodeProgress = { CompletableDeferred<Double>().await() }
        isOffline = true
        val player = player()

        player.play(episode("e1"))

        assertEquals("e1", player.state.value.current?.id)
        assertEquals(1, engine.playCount)
    }

    @Test
    fun playWhileAnEpisodeLooksUpItsPositionWaitsForTheEpisode() = runTest(UnconfinedTestDispatcher()) {
        val lookup = CompletableDeferred<Double>()
        episodeProgress = { lookup.await() }
        val player = player()
        val podcastEpisode = episode("e1")
        player.replaceQueue(songs("s1"), shuffle = false, autoPlay = true)
        player.pause()

        player.play(podcastEpisode)
        player.play()
        assertEquals(1, engine.playCount)

        lookup.complete(300.0)
        assertEquals("e1", player.state.value.current?.id)
        assertEquals(2, engine.playCount)
    }

    @Test
    fun pausingWhileAnEpisodeLooksUpItsPositionCallsOffPlayingIt() = runTest(UnconfinedTestDispatcher()) {
        val lookup = CompletableDeferred<Double>()
        episodeProgress = { lookup.await() }
        val player = player()

        player.play(episode("e1"))
        player.pause()
        lookup.complete(300.0)

        assertTrue(engine.loadedUrls.isEmpty())
        assertEquals(0, engine.playCount)
        assertNull(player.state.value.current)
    }

    @Test
    fun replacingTheQueueWhileAnEpisodeLooksUpItsPositionLetsPlayResume() = runTest(UnconfinedTestDispatcher()) {
        val lookup = CompletableDeferred<Double>()
        episodeProgress = { lookup.await() }
        val player = player()

        player.play(episode("e1"))
        player.replaceQueue(songs("s1"), shuffle = false, autoPlay = true)
        engine.reportPlaying(true)
        engine.reportPlaying(false)
        player.play()
        lookup.complete(300.0)

        assertEquals(2, engine.playCount)
        assertEquals("s1", player.state.value.current?.id)
    }

    @Test
    fun skippingWhileAnEpisodeLooksUpItsPositionLetsPlayResume() = runTest(UnconfinedTestDispatcher()) {
        val lookup = CompletableDeferred<Double>()
        episodeProgress = { lookup.await() }
        val player = player()
        player.replaceQueue(songs("s1", "s2"), shuffle = false, autoPlay = true)

        player.play(episode("e1"))
        player.skipToNext()
        engine.reportPlaying(true)
        engine.reportPlaying(false)
        player.play()
        lookup.complete(300.0)

        assertEquals(3, engine.playCount)
        assertEquals("s2", player.state.value.current?.id)
    }

    @Test
    fun replayingAnEpisodeThatPlayedToItsEndStartsItOver() = runTest(UnconfinedTestDispatcher()) {
        episodeProgress = { 995.0 }
        val player = player()
        val podcastEpisode = episode("e1")
        player.play(podcastEpisode)
        engine.reachPosition(995.0)
        engine.reachPosition(999.5)
        engine.finish()

        player.play(podcastEpisode)

        assertEquals(0.0, engine.seeks.last())
    }

    @Test
    fun remembersAnEpisodesPositionWhilePlaying() = runTest(UnconfinedTestDispatcher()) {
        val player = player()
        val (song) = songs("s1")
        player.replaceQueue(listOf(episode("e1"), song), shuffle = false, autoPlay = true)

        engine.reachPosition(10.4)
        engine.reachPosition(12.0)
        assertEquals(10.0, player.rememberedPosition("e1"))

        player.skipToNext()
        engine.reachPosition(10.0)
        assertNull(player.rememberedPosition("s1"))

        engine.reachPosition(1.0)
        player.skipToPrevious()
        assertEquals(10.0, engine.seeks.last())
    }

    // Play counts

    @Test
    fun registersAPlayOncePastAQuarterWithoutTouchingFavorite() = runTest(UnconfinedTestDispatcher()) {
        val player = player()
        val song = store.sync(JsonArray(listOf(Fixtures.song("s1", length = 100.0, favorite = true, playCount = 3)))).single()
        h.on(HttpMethod.Post, "interaction/play") {
            buildJsonObject {
                put("type", "interactions")
                put("id", 1)
                put("song_id", "s1")
                put("play_count", 17)
            }.toString()
        }
        player.replaceQueue(listOf(song), shuffle = false, autoPlay = true)

        engine.reachPosition(25.0)
        assertTrue(h.requestsTo(HttpMethod.Post, "interaction/play").isEmpty())

        engine.reachPosition(30.0)
        engine.reachPosition(31.0)

        assertEquals("s1", h.requestsTo(HttpMethod.Post, "interaction/play").single().json["song"]?.jsonPrimitive?.content)
        assertEquals(listOf("s1"), registeredPlays.map(Playable::id))
        assertEquals(17, store.byId("s1")!!.playCount)
        assertTrue(store.byId("s1")!!.favorite)
    }

    @Test
    fun aReplayCountsAgainOnceTheItemFinished() = runTest(UnconfinedTestDispatcher()) {
        val player = player()
        h.on(HttpMethod.Post, "interaction/play") { """{"song_id":"s1","play_count":1}""" }
        player.replaceQueue(songs("s1"), shuffle = false, autoPlay = true)
        player.rotateRepeatMode()
        player.rotateRepeatMode()

        engine.reachPosition(50.0)
        engine.finish()
        engine.reachPosition(50.0)

        assertEquals(2, h.requestsTo(HttpMethod.Post, "interaction/play").size)
    }

    @Test
    fun aSkippedSongCountsAgainWhenPlayedAgain() = runTest(UnconfinedTestDispatcher()) {
        val player = player()
        h.on(HttpMethod.Post, "interaction/play") { """{"song_id":"s1","play_count":1}""" }
        player.replaceQueue(songs("s1", "s2"), shuffle = false, autoPlay = true)

        engine.reachPosition(50.0)
        player.skipToNext()
        player.skipToPrevious()
        engine.reachPosition(50.0)

        assertEquals(2, h.requestsTo(HttpMethod.Post, "interaction/play").size)
    }

    @Test
    fun ignoresPositionsWhileTheRadioPlays() = runTest(UnconfinedTestDispatcher()) {
        val player = player()
        h.on(HttpMethod.Get, "radio/stations/r1/now-playing") { """{"stream_title":null}""" }
        player.replaceQueue(songs("s1"), shuffle = false, autoPlay = true)
        player.playRadio(station("r1"))

        engine.reachPosition(90.0)

        assertTrue(registeredPlays.isEmpty())
        assertEquals(0.0, player.position.value)
    }

    // Queue state sync

    @Test
    fun doesNotSyncWithServersThatDoNotSupportIt() = runTest(UnconfinedTestDispatcher()) {
        val player = player()

        player.replaceQueue(songs("s1"), shuffle = false, autoPlay = true)
        engine.reachPosition(5.0)
        player.restore(QueueState(songs("s2"), null, 0.0))

        assertTrue(h.requests.isEmpty())
        assertEquals(listOf("s1"), player.queueIds())
    }

    @Test
    fun putsTheQueueWheneverItChanges() = runTest(UnconfinedTestDispatcher()) {
        supportQueueSync()
        acceptQueueSync()
        val player = player()
        val all = songs("s1", "s2", "s3")

        player.replaceQueue(all, shuffle = false, autoPlay = true)
        player.move(2, 0)
        player.clearQueue()

        val bodies = h.requestsTo(HttpMethod.Put, "queue/state").map { it.json }
        assertEquals(3, bodies.size)
        assertEquals(listOf("s3", "s1", "s2"), bodies[1]["songs"]!!.jsonArray.map { it.jsonPrimitive.content })
        assertEquals("s1", bodies[1]["song"]!!.jsonPrimitive.content)
        assertEquals(JsonArray(emptyList()), bodies[2]["songs"])
        assertEquals("", bodies[2]["song"]!!.jsonPrimitive.content)
    }

    @Test
    fun putsThePlaybackStatusWhenAnItemStartsAndEveryFiveSeconds() = runTest(UnconfinedTestDispatcher()) {
        supportQueueSync()
        acceptQueueSync()
        val player = player()
        player.replaceQueue(songs("s1"), shuffle = false, autoPlay = true)

        listOf(0.2, 1.0, 4.9, 5.0, 5.3, 7.0, 10.1).forEach(engine::reachPosition)

        val statuses = h.requestsTo(HttpMethod.Put, "queue/playback-status").map { it.json }
        assertEquals(listOf(0, 5, 10), statuses.map { it["position"]!!.jsonPrimitive.int })
        assertTrue(statuses.all { it["song"]!!.jsonPrimitive.content == "s1" })
    }

    @Test
    fun restoresTheSavedQueueWithoutPlaying() = runTest(UnconfinedTestDispatcher()) {
        supportQueueSync()
        acceptQueueSync()
        val player = player()
        val (first, second) = songs("s1", "s2")

        player.restore(QueueState(listOf(first, second), second, 42.0))

        assertEquals(listOf("s1", "s2"), player.queueIds())
        assertEquals("s2", player.state.value.current?.id)
        assertEquals(listOf(url(second)), engine.loadedUrls)
        assertEquals(42.0, engine.seeks.last())
        assertEquals(0, engine.playCount)
        assertFalse(player.state.value.isPlaying)
        assertEquals("s2", h.requestsTo(HttpMethod.Put, "queue/state").single().json["song"]!!.jsonPrimitive.content)

        player.play()
        assertEquals(1, engine.playCount)
    }

    @Test
    fun theQueueStateIsPutOneAtATimeWithTheLatestLast() = runTest(UnconfinedTestDispatcher()) {
        supportQueueSync()
        val firstPutAnswered = CompletableDeferred<Unit>()
        h.onRequest(HttpMethod.Put, "queue/state") {
            firstPutAnswered.await()
            Harness.Reply(200, "")
        }
        val player = player()
        val all = songs("s1", "s2", "s3")

        player.replaceQueue(all, shuffle = false, autoPlay = false)
        player.move(2, 0)
        player.move(2, 0)
        assertEquals(1, h.requestsTo(HttpMethod.Put, "queue/state").size)
        firstPutAnswered.complete(Unit)

        val sent = h.requestsTo(HttpMethod.Put, "queue/state").map { put -> put.json["songs"]!!.jsonArray.map { it.jsonPrimitive.content } }
        assertEquals(listOf(listOf("s1", "s2", "s3"), listOf("s2", "s3", "s1")), sent)
    }

    @Test
    fun aQueueStateWaitingToBePutAtLogoutIsNeverSent() = runTest(UnconfinedTestDispatcher()) {
        supportQueueSync()
        val firstPutAnswered = CompletableDeferred<Unit>()
        h.onRequest(HttpMethod.Put, "queue/state") {
            firstPutAnswered.await()
            Harness.Reply(200, "")
        }
        val player = player()
        player.replaceQueue(songs("s1", "s2"), shuffle = false, autoPlay = false)
        player.move(1, 0)

        player.cleanUpUponLogout()
        firstPutAnswered.complete(Unit)

        assertEquals(1, h.requestsTo(HttpMethod.Put, "queue/state").size)
    }

    @Test
    fun restoringLeavesWhatIsAlreadyPlayingAlone() = runTest(UnconfinedTestDispatcher()) {
        supportQueueSync()
        acceptQueueSync()
        val player = player()
        val (playing, saved) = songs("s1", "s2")
        player.replaceQueue(listOf(playing), shuffle = false, autoPlay = true)

        player.restore(QueueState(listOf(saved), saved, 42.0))

        assertEquals(listOf("s1"), player.queueIds())
        assertEquals("s1", player.state.value.current?.id)
        assertEquals(listOf(url(playing)), engine.loadedUrls)
    }

    @Test
    fun aRestoredSongSavedAtItsEndStartsOver() = runTest(UnconfinedTestDispatcher()) {
        supportQueueSync()
        acceptQueueSync()
        val player = player()
        val song = songs("s1").single()

        player.restore(QueueState(listOf(song), song, 100.2))

        assertEquals(0.0, engine.seeks.last())
    }

    @Test
    fun playAfterTheQueueRanOutStartsTheLastSongOver() = runTest(UnconfinedTestDispatcher()) {
        val player = player()
        val song = songs("s1").single()
        player.replaceQueue(listOf(song), shuffle = false, autoPlay = true)
        engine.reachPosition(100.0)
        engine.finish()
        assertFalse(player.state.value.isPlaying)

        player.play()

        assertEquals(0.0, engine.seeks.last())
        assertTrue(player.state.value.isPlaying)
        assertEquals(2, engine.playCount)
    }

    @Test
    fun abandonsARestoredItemThatFailsToLoad() = runTest(UnconfinedTestDispatcher()) {
        supportQueueSync()
        acceptQueueSync()
        val player = player()
        val song = songs("s1").single()
        engine.failEveryLoad = true

        player.restore(QueueState(listOf(song), song, 42.0))

        assertTrue(player.state.value.hasFailed)
        assertEquals(1, engine.stopCount)
        assertEquals(1, engine.loadedUrls.size)
    }

    @Test
    fun playAfterARestoredItemFailedToLoadStartsWhereItWasSaved() = runTest(UnconfinedTestDispatcher()) {
        supportQueueSync()
        acceptQueueSync()
        val player = player()
        val song = songs("s1").single()
        engine.failEveryLoad = true
        player.restore(QueueState(listOf(song), song, 42.0))

        engine.failEveryLoad = false
        player.play()

        assertEquals(42.0, engine.seeks.last())
        assertTrue(player.state.value.isPlaying)
    }

    @Test
    fun parsesTheQueueStateIntoTheVault() {
        val json = buildJsonObject {
            put("songs", JsonArray(listOf(Fixtures.song("s1"), Fixtures.song("s2"))))
            put("current_song", Fixtures.song("s2"))
            put("playback_position", 42)
        }

        val queueState = QueueState.parse(json, store)

        assertEquals(listOf("s1", "s2"), queueState.playables.map(Playable::id))
        assertEquals("s2", queueState.currentPlayable?.id)
        assertEquals(42.0, queueState.playbackPosition)
        assertEquals("s1", store.byId("s1")?.id)
    }

    @Test
    fun parsesAnEmptyQueueState() {
        val json = buildJsonObject {
            put("songs", JsonArray(emptyList()))
            put("current_song", JsonPrimitive(null as String?))
            put("playback_position", 0)
        }

        assertEquals(QueueState.EMPTY, QueueState.parse(json, store))
    }

    // Crossfade

    private fun FakeAudioEngine.playThrough(vararg positions: Double) = positions.forEach(::reachPosition)

    @Test
    fun aSongFadesIntoTheNextAsItNearsItsEnd() = runTest(UnconfinedTestDispatcher()) {
        crossfadeSeconds = 5
        val player = player()
        val queue = songs("s1", "s2")
        player.replaceQueue(queue, shuffle = false, autoPlay = true)

        engine.playThrough(94.5, 95.0)

        assertEquals(listOf(url(queue[1]) to 5.0), engine.crossfades)
        assertEquals("s2", player.state.value.current?.id)
        assertEquals(0.0, player.position.value)
    }

    @Test
    fun seekingIntoTheFadeFadesOverWhatIsLeft() = runTest(UnconfinedTestDispatcher()) {
        crossfadeSeconds = 5
        val player = player()
        val queue = songs("s1", "s2")
        player.replaceQueue(queue, shuffle = false, autoPlay = true)

        engine.reachPosition(50.0)
        player.seek(97.0)
        engine.reachPosition(97.0)

        assertEquals(listOf(url(queue[1]) to 3.0), engine.crossfades)
        assertEquals("s2", player.state.value.current?.id)
    }

    @Test
    fun seekingRightToTheEndLetsTheSongEndAsUsual() = runTest(UnconfinedTestDispatcher()) {
        crossfadeSeconds = 5
        val player = player()
        player.replaceQueue(songs("s1", "s2"), shuffle = false, autoPlay = true)

        player.seek(99.5)
        engine.reachPosition(99.5)

        assertTrue(engine.crossfades.isEmpty())
        assertEquals("s1", player.state.value.current?.id)
    }

    @Test
    fun aSongStartsFadingOnlyOnce() = runTest(UnconfinedTestDispatcher()) {
        crossfadeSeconds = 5
        val player = player()
        val queue = songs("s1", "s2")
        engine.stallingUrls += url(queue[1])
        player.replaceQueue(queue, shuffle = false, autoPlay = true)

        engine.playThrough(95.0, 95.5, 96.0)

        assertEquals(1, engine.crossfades.size)
    }

    @Test
    fun onlySongsFadeIntoSongs() = runTest(UnconfinedTestDispatcher()) {
        crossfadeSeconds = 5
        val player = player()
        player.replaceQueue(songs("s1") + episode("e1"), shuffle = false, autoPlay = true)

        engine.playThrough(94.5, 95.0)

        assertTrue(engine.crossfades.isEmpty())
    }

    @Test
    fun repeatOneLoopsWithoutAFade() = runTest(UnconfinedTestDispatcher()) {
        crossfadeSeconds = 5
        val player = player()
        player.replaceQueue(songs("s1", "s2"), shuffle = false, autoPlay = true)
        player.rotateRepeatMode()
        player.rotateRepeatMode()

        engine.playThrough(94.5, 95.0)

        assertTrue(engine.crossfades.isEmpty())
    }

    @Test
    fun noFadeWhenCrossfadeIsOff() = runTest(UnconfinedTestDispatcher()) {
        val player = player()
        player.replaceQueue(songs("s1", "s2"), shuffle = false, autoPlay = true)

        engine.playThrough(94.5, 95.0)

        assertTrue(engine.crossfades.isEmpty())
    }

    @Test
    fun aNextSongThatFailsToLoadLetsTheCurrentOnePlayOut() = runTest(UnconfinedTestDispatcher()) {
        crossfadeSeconds = 5
        val player = player()
        val queue = songs("s1", "s2")
        engine.failingUrls += url(queue[1])
        player.replaceQueue(queue, shuffle = false, autoPlay = true)

        engine.playThrough(94.5, 95.0)

        assertEquals("s1", player.state.value.current?.id)
        assertFalse(player.state.value.hasFailed)
    }

    @Test
    fun seekingWhileTheNextSongLoadsCallsOffTheFade() = runTest(UnconfinedTestDispatcher()) {
        crossfadeSeconds = 5
        val player = player()
        val queue = songs("s1", "s2")
        engine.stallingUrls += url(queue[1])
        player.replaceQueue(queue, shuffle = false, autoPlay = true)
        engine.playThrough(94.5, 95.0)
        val lateReady = engine.stalledLoad

        player.seek(50.0)
        lateReady?.invoke()

        assertEquals("s1", player.state.value.current?.id)
        assertEquals(1, engine.crossfadeCancelCount)
    }

    @Test
    fun pausingWhileTheNextSongLoadsCallsOffTheFade() = runTest(UnconfinedTestDispatcher()) {
        crossfadeSeconds = 5
        val player = player()
        val queue = songs("s1", "s2")
        engine.stallingUrls += url(queue[1])
        player.replaceQueue(queue, shuffle = false, autoPlay = true)
        engine.playThrough(94.5, 95.0)
        val lateReady = engine.stalledLoad

        player.pause()
        lateReady?.invoke()

        assertEquals("s1", player.state.value.current?.id)
        assertEquals(1, engine.crossfadeCancelCount)
    }

    @Test
    fun theEnginePausingWhileTheNextSongLoadsCallsOffTheFade() = runTest(UnconfinedTestDispatcher()) {
        crossfadeSeconds = 5
        val player = player()
        val queue = songs("s1", "s2")
        engine.stallingUrls += url(queue[1])
        player.replaceQueue(queue, shuffle = false, autoPlay = true)
        engine.reportPlaying(true)
        engine.playThrough(94.5, 95.0)
        val lateReady = engine.stalledLoad

        engine.reportPlaying(false)
        lateReady?.invoke()

        assertEquals("s1", player.state.value.current?.id)
        assertEquals(1, engine.crossfadeCancelCount)
    }

    @Test
    fun pickingAnotherSongWhileTheNextOneLoadsCallsOffTheFade() = runTest(UnconfinedTestDispatcher()) {
        crossfadeSeconds = 5
        val player = player()
        val queue = songs("s1", "s2", "s3")
        engine.stallingUrls += url(queue[1])
        player.replaceQueue(queue, shuffle = false, autoPlay = true)
        engine.playThrough(94.5, 95.0)
        val lateReady = engine.stalledLoad

        player.play(queue[2])
        lateReady?.invoke()

        assertEquals("s3", player.state.value.current?.id)
    }

    // Loudness

    @Test
    fun eachSongPlaysWithItsOwnLoudnessGain() = runTest(UnconfinedTestDispatcher()) {
        crossfadeSeconds = 5
        gains["s1"] = -4.0
        gains["s2"] = 3.0
        val player = player()
        player.replaceQueue(songs("s1", "s2"), shuffle = false, autoPlay = true)
        assertEquals(-4.0, engine.normalizationGain)

        engine.playThrough(94.5, 95.0)

        assertEquals(listOf(3.0), engine.crossfadeGains)
    }

    @Test
    fun aChangedLoudnessSettingAppliesToWhatIsPlaying() = runTest(UnconfinedTestDispatcher()) {
        val player = player()
        player.replaceQueue(songs("s1"), shuffle = false, autoPlay = true)

        gains["s1"] = -2.0
        player.refreshNormalization()

        assertEquals(-2.0, engine.normalizationGain)
    }

    @Test
    fun radioPlaysWithoutALoudnessGain() = runTest(UnconfinedTestDispatcher()) {
        gains["s1"] = -4.0
        val player = player()
        player.replaceQueue(songs("s1"), shuffle = false, autoPlay = true)

        player.playRadio(station("r1"))

        assertEquals(0.0, engine.normalizationGain)
    }

    // Radio

    @Test
    fun playingARadioStationTakesOverTheEngine() = runTest(UnconfinedTestDispatcher()) {
        val player = player()
        val radio = station("r1")
        h.on(HttpMethod.Get, "radio/stations/r1/now-playing") { """{"stream_title":null}""" }
        player.replaceQueue(songs("s1"), shuffle = false, autoPlay = true)

        player.playRadio(radio)

        assertEquals(h.session.radioStreamUrl(radio), engine.loadedUrls.last())
        assertEquals(radio, player.state.value.radioStation)
        assertTrue(player.state.value.isRadioMode)
        assertTrue(player.state.value.isPlaying)
    }

    @Test
    fun pollsTheStreamTitleWhileTheStationIsOn() = runTest(UnconfinedTestDispatcher()) {
        val player = player()
        var title = "First Song"
        h.on(HttpMethod.Get, "radio/stations/r1/now-playing") { """{"stream_title":"$title"}""" }

        player.playRadio(station("r1"))
        advanceTimeBy(1.9.seconds)
        assertTrue(h.requests.isEmpty())

        advanceTimeBy(0.2.seconds)
        assertEquals("First Song", player.state.value.radioStreamTitle)

        title = "Second Song"
        advanceTimeBy(15.seconds)
        assertEquals("Second Song", player.state.value.radioStreamTitle)
        assertEquals(2, h.requestsTo(HttpMethod.Get, "radio/stations/r1/now-playing").size)

        player.stopRadio()
        advanceTimeBy(60.seconds)
        assertEquals(2, h.requests.size)
        assertFalse(player.state.value.isRadioMode)
        assertNull(player.state.value.radioStreamTitle)
    }

    @Test
    fun switchingStationsPollsOnlyTheNewOne() = runTest(UnconfinedTestDispatcher()) {
        val player = player()
        h.on(HttpMethod.Get, "radio/stations/r1/now-playing") { """{"stream_title":"One"}""" }
        h.on(HttpMethod.Get, "radio/stations/r2/now-playing") { """{"stream_title":"Two"}""" }

        player.playRadio(station("r1"))
        advanceTimeBy(1.seconds)
        player.playRadio(station("r2"))
        advanceTimeBy(20.seconds)

        assertTrue(h.requestsTo(HttpMethod.Get, "radio/stations/r1/now-playing").isEmpty())
        assertEquals("Two", player.state.value.radioStreamTitle)
    }

    @Test
    fun transportControlsActOnTheRadioInRadioMode() = runTest(UnconfinedTestDispatcher()) {
        val player = player()
        h.on(HttpMethod.Get, "radio/stations/r1/now-playing") { """{"stream_title":null}""" }
        player.replaceQueue(songs("s1"), shuffle = false, autoPlay = true)
        player.playRadio(station("r1"))
        val loads = engine.loadedUrls.size

        player.togglePlayPause()
        assertFalse(player.state.value.isPlaying)
        player.play()

        assertTrue(player.state.value.isPlaying)
        assertTrue(player.state.value.isRadioMode)
        assertEquals(loads, engine.loadedUrls.size)

        player.stop()
        assertFalse(player.state.value.isRadioMode)
    }

    @Test
    fun skippingDoesNothingInRadioMode() = runTest(UnconfinedTestDispatcher()) {
        val player = player()
        h.on(HttpMethod.Get, "radio/stations/r1/now-playing") { """{"stream_title":null}""" }
        player.replaceQueue(songs("s1", "s2"), shuffle = false, autoPlay = true)
        player.playRadio(station("r1"))
        val loads = engine.loadedUrls.size
        val seeks = engine.seeks.size
        engine.reachPosition(30.0)

        player.skipToNext()
        player.skipToPrevious()

        assertTrue(player.state.value.isRadioMode)
        assertEquals(loads, engine.loadedUrls.size)
        assertEquals(seeks, engine.seeks.size)
    }

    @Test
    fun restoringLeavesThePlayingRadioAlone() = runTest(UnconfinedTestDispatcher()) {
        supportQueueSync()
        acceptQueueSync()
        val player = player()
        h.on(HttpMethod.Get, "radio/stations/r1/now-playing") { """{"stream_title":null}""" }
        val saved = songs("s1").single()
        player.playRadio(station("r1"))

        player.restore(QueueState(listOf(saved), saved, 42.0))

        assertTrue(player.state.value.isRadioMode)
        assertEquals(0, engine.loadsOf(url(saved)))
    }

    @Test
    fun startingQueuePlaybackLeavesRadioMode() = runTest(UnconfinedTestDispatcher()) {
        val player = player()
        h.on(HttpMethod.Get, "radio/stations/r1/now-playing") { """{"stream_title":null}""" }
        val song = songs("s1").single()
        player.playRadio(station("r1"))

        player.play(song)
        advanceTimeBy(60.seconds)

        assertFalse(player.state.value.isRadioMode)
        assertEquals("s1", player.state.value.current?.id)
        assertTrue(h.requests.isEmpty())
    }

    @Test
    fun resumingTheQueueAfterTheRadioReloadsWhereItLeftOff() = runTest(UnconfinedTestDispatcher()) {
        val player = player()
        h.on(HttpMethod.Get, "radio/stations/r1/now-playing") { """{"stream_title":null}""" }
        val song = songs("s1").single()
        player.replaceQueue(listOf(song), shuffle = false, autoPlay = true)
        engine.reachPosition(20.0)

        player.playRadio(station("r1"))
        player.stopRadio()
        player.play()

        assertEquals(2, engine.loadsOf(url(song)))
        assertEquals(20.0, engine.seeks.last())
        assertTrue(player.state.value.isPlaying)
    }

    @Test
    fun aStationThatFailsToLoadThrowsAndLeavesRadioMode() = runTest(UnconfinedTestDispatcher()) {
        val player = player()
        engine.failEveryLoad = true

        assertFailsWith<SourceLoadException> { player.playRadio(station("r1")) }

        assertFalse(player.state.value.isRadioMode)
        assertFalse(player.state.value.isBuffering)
    }

    @Test
    fun pausingWhileTheStationConnectsKeepsItFromPlaying() = runTest(UnconfinedTestDispatcher()) {
        val player = player()
        h.on(HttpMethod.Get, "radio/stations/r1/now-playing") { """{"stream_title":null}""" }
        val radio = station("r1")
        engine.stallingUrls += h.session.radioStreamUrl(radio)

        launch { player.playRadio(radio) }
        player.pause()
        engine.stalledLoad!!()

        assertEquals(0, engine.playCount)
        assertFalse(player.state.value.isPlaying)
        assertTrue(player.state.value.isRadioMode)

        player.play()
        assertEquals(1, engine.playCount)
        assertEquals(1, engine.loadedUrls.size)
    }

    @Test
    fun theCallerGoingAwayWhileTheStationConnectsStillTunesIn() = runTest(UnconfinedTestDispatcher()) {
        val player = player()
        h.on(HttpMethod.Get, "radio/stations/r1/now-playing") { """{"stream_title":null}""" }
        val radio = station("r1")
        engine.stallingUrls += h.session.radioStreamUrl(radio)

        launch { player.playRadio(radio) }.cancel()
        engine.stalledLoad!!()

        assertFalse(player.state.value.isBuffering)
        assertTrue(player.state.value.isPlaying)
        assertEquals(radio, player.state.value.radioStation)
    }

    @Test
    fun refreshingTheStationAppliesARenameAndRestartsOnANewUrl() = runTest(UnconfinedTestDispatcher()) {
        val player = player()
        h.on(HttpMethod.Get, "radio/stations/r1/now-playing") { """{"stream_title":null}""" }
        player.playRadio(station("r1"))

        player.refreshRadioStation(station("r1", name = "Renamed"))
        assertEquals("Renamed", player.state.value.radioStation?.name)
        assertEquals(1, engine.loadedUrls.size)

        player.refreshRadioStation(station("r1", url = "https://elsewhere.example.com"))
        assertEquals(2, engine.loadedUrls.size)

        player.refreshRadioStation(station("r2", name = "Not playing"))
        assertEquals("r1", player.state.value.radioStation?.id)
    }
}
