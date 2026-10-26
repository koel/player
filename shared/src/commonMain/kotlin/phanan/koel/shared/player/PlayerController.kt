package phanan.koel.shared.player

import phanan.koel.shared.onMain
import kotlinx.coroutines.CoroutineScope
import kotlinx.coroutines.Job
import kotlinx.coroutines.channels.Channel
import kotlinx.coroutines.delay
import kotlinx.coroutines.flow.MutableStateFlow
import kotlinx.coroutines.flow.StateFlow
import kotlinx.coroutines.flow.asStateFlow
import kotlinx.coroutines.launch
import kotlinx.coroutines.suspendCancellableCoroutine
import kotlinx.coroutines.withTimeoutOrNull
import kotlinx.serialization.json.JsonElement
import kotlinx.serialization.json.JsonObject
import kotlinx.serialization.json.JsonPrimitive
import kotlinx.serialization.json.buildJsonObject
import kotlinx.serialization.json.contentOrNull
import kotlinx.serialization.json.intOrNull
import kotlinx.serialization.json.jsonObject
import kotlinx.serialization.json.jsonPrimitive
import kotlinx.serialization.json.put
import kotlinx.serialization.json.putJsonArray
import phanan.koel.shared.api.ApiClient
import phanan.koel.shared.models.Episode
import phanan.koel.shared.models.Playable
import phanan.koel.shared.models.QueueState
import phanan.koel.shared.models.RadioStation
import phanan.koel.shared.models.Song
import phanan.koel.shared.session.Feature
import phanan.koel.shared.session.Session
import phanan.koel.shared.storage.Preferences
import phanan.koel.shared.stores.PlayableStore
import kotlin.coroutines.resume
import kotlin.random.Random
import kotlin.time.Duration
import kotlin.time.Duration.Companion.seconds

class SourceLoadException(message: String) : Exception(message)

/** The queue, the radio, and everything that goes on while they play, over a single [AudioEngine]. */
class PlayerController internal constructor(
    private val api: ApiClient,
    private val playables: PlayableStore,
    private val session: Session,
    private val preferences: Preferences,
    private val scope: CoroutineScope,
    private val engine: AudioEngine,
    private val localFileUrl: (Playable) -> String?,
    private val onPlayRegistered: (Playable) -> Unit,
    /** How many seconds a song fades into the next when it ends on its own; 0 plays them back to back. */
    private val crossfadeSeconds: () -> Int = { 0 },
    /** How many dB to turn a playable up or down so everything plays at about the same loudness. */
    private val normalizationGain: (Playable) -> Double = { 0.0 },
    private val episodeProgress: suspend (Episode) -> Double = { 0.0 },
    private val isOffline: () -> Boolean = { false },
    /**
     * How long a source is given to become playable before we give up on it. Without this, a
     * stalled connection leaves the player loading forever: the platform player never times out
     * on its own.
     */
    private val sourceLoadTimeout: Duration = 30.seconds,
    private val random: Random = Random.Default,
) {
    private val stateFlow = MutableStateFlow(PlaybackState())
    val state: StateFlow<PlaybackState> = stateFlow.asStateFlow()

    private val positionFlow = MutableStateFlow(0.0)
    val position: StateFlow<Double> = positionFlow.asStateFlow()

    private var queueIds: List<String> = emptyList()
    private var currentId: String? = null
    private var isPlaying = false
    private var isBuffering = false
    private var hasFailed = false
    private var repeatMode = preferences.repeatMode
    private var volume = preferences.volume
    private var radioStation: RadioStation? = null
    private var radioStreamTitle: String? = null

    private var errorCount = 0
    private var loadGeneration = 0
    private var crossfadingFromId: String? = null
    private var pendingCrossfadeGeneration: Int? = null

    /** Set once the engine no longer holds the current item's source (stopped, or replaced by radio). */
    private var detachedAt: Double? = null
    private var hasFinishedQueue = false
    private var playsWhenLoaded = true
    private var engineIsPlaying = false
    private var episodeLookup: Job? = null

    private var nowPlayingJob: Job? = null
    private var lastReportedSecond = -1
    private val registeredPlays = mutableSetOf<String>()
    private val rememberedPositions = mutableMapOf<String, Double>()
    private val queueStateUpdates = Channel<JsonObject>(Channel.CONFLATED)

    private val currentIndex: Int get() = currentId?.let(queueIds::indexOf) ?: -1
    private val isRadioMode: Boolean get() = radioStation != null
    private val isLookingUpEpisode: Boolean get() = episodeLookup?.isActive == true

    init {
        engine.listener = EngineListener()
        engine.setVolume(volume)
        publish()
        scope.launch { playables.vault.entities.collect { publish() } }
        scope.launch {
            for (body in queueStateUpdates) runCatching { api.put("queue/state", body) }
        }
    }

    fun replaceQueue(playables: List<Playable>, shuffle: Boolean, autoPlay: Boolean) {
        callOffEpisodeLookup()
        ensureInVault(playables)
        val ids = playables.map(Playable::id).distinct()
        setQueue(if (shuffle) ids.shuffled(random) else ids)

        if (autoPlay) scope.launch { playAt(0) }
    }

    /**
     * Jumps to [playable] if it's queued, otherwise queues it after the current item first. An episode first looks
     * up where it was left off, possibly on another device, unless offline; picking, skipping, pausing or stopping
     * meanwhile wins.
     */
    fun play(playable: Playable) {
        callOffEpisodeLookup()
        if (playable !is Episode || playable.id in rememberedPositions || isOffline()) return playNow(playable)

        episodeLookup = scope.launch {
            rememberedPositions[playable.id] = episodeProgress(playable)
            playNow(playable)
        }
    }

    private fun callOffEpisodeLookup() {
        episodeLookup?.cancel()
    }

    private fun playNow(playable: Playable) {
        if (!isQueued(playable)) playNext(playable)
        val index = queueIds.indexOf(playable.id)
        scope.launch { playAt(index) }
    }

    fun playNext(playable: Playable) = playNext(listOf(playable))

    /** The current item stays where it is; the others go right after it, in order. */
    fun playNext(playables: List<Playable>) {
        ensureInVault(playables)
        val moved = playables.map(Playable::id).distinct() - setOfNotNull(currentId)
        if (moved.isEmpty()) return

        val remaining = queueIds - moved.toSet()
        val insertAt = (currentId?.let(remaining::indexOf) ?: -1) + 1
        setQueue(remaining.toMutableList().apply { addAll(insertAt, moved) })
    }

    fun queueToBottom(playable: Playable) = queueToBottom(listOf(playable))

    /** The current item stays where it is; the others go to the end, in order. */
    fun queueToBottom(playables: List<Playable>) {
        ensureInVault(playables)
        val moved = playables.map(Playable::id).distinct() - setOfNotNull(currentId)
        if (moved.isEmpty()) return

        setQueue(queueIds - moved.toSet() + moved)
    }

    fun removeFromQueue(playable: Playable) {
        val index = queueIds.indexOf(playable.id)
        if (index > -1) removeAt(index)
    }

    /** Removing the current item moves playback on to the next one first. */
    fun removeAt(index: Int) {
        if (index == currentIndex) {
            callOffEpisodeLookup()
            nextIndex()?.let { next -> playAtLater(queueIds[next]) }
        }

        if (index >= queueIds.size) return
        setQueue(queueIds.toMutableList().apply { removeAt(index) })
    }

    /** [to] is the drop position before the move, as in a reorderable list. */
    fun move(from: Int, to: Int) {
        val target = if (from < to) to - 1 else to
        val reordered = queueIds.toMutableList()
        reordered.add(target, reordered.removeAt(from))
        setQueue(reordered)
    }

    fun clearQueue() = setQueue(emptyList())

    fun isQueued(playable: Playable): Boolean = playable.id in queueIds

    fun play() {
        scope.launch { resume() }
    }

    fun pause() {
        callOffEpisodeLookup()
        callOffPendingCrossfade()
        playsWhenLoaded = false
        isPlaying = false
        publish()
        engine.pause()
    }

    fun togglePlayPause() {
        if (isPlaying) pause() else play()
    }

    fun stop() {
        callOffEpisodeLookup()
        if (isRadioMode) return stopRadio()

        loadGeneration++
        crossfadingFromId = null
        detachedAt = positionFlow.value
        isPlaying = false
        isBuffering = false
        publish()
        engine.stop()
    }

    fun seek(seconds: Double) {
        callOffPendingCrossfade()
        positionFlow.value = seconds
        engine.seek(seconds)
    }

    fun skipToNext() {
        if (isRadioMode) return
        callOffEpisodeLookup()
        scope.launch { advance() }
    }

    /** Past the first five seconds, "previous" restarts the current item instead. */
    fun skipToPrevious() {
        if (isRadioMode) return
        callOffEpisodeLookup()
        if (engine.position > RESTART_THRESHOLD_SECONDS) return seek(0.0)
        if (currentIndex == -1) return

        val previous = when {
            currentIndex > 0 -> currentIndex - 1
            repeatMode == RepeatMode.ALL -> queueIds.lastIndex
            else -> return
        }

        scope.launch { playAt(previous) }
    }

    fun rotateRepeatMode(): RepeatMode {
        repeatMode = repeatMode.next()
        preferences.repeatMode = repeatMode
        publish()
        return repeatMode
    }

    fun setVolume(volume: Double) {
        this.volume = volume
        preferences.volume = volume
        engine.setVolume(volume)
        publish()
    }

    /** Applies a changed loudness setting to what is playing. */
    fun refreshNormalization() {
        if (isRadioMode) return
        val playable = currentId?.let(playables::byId) ?: return
        engine.setNormalizationGain(normalizationGain(playable))
    }

    /** Where an episode was left off, in seconds; null if it never played here. */
    fun rememberedPosition(playableId: String): Double? = rememberedPositions[playableId]

    /** Seeds where an episode resumes, e.g. from the podcast's saved progress. */
    fun rememberPosition(playableId: String, seconds: Double) {
        rememberedPositions[playableId] = seconds
    }

    /** Loads the server-saved queue without starting playback, unless something is already loaded. */
    fun restore(queueState: QueueState) {
        if (!session.supports(Feature.QUEUE_STATE_SYNC) || queueState.playables.isEmpty() || currentId != null || isRadioMode) return

        ensureInVault(queueState.playables)
        queueIds = queueState.playables.map(Playable::id).distinct()
        hasFinishedQueue = false
        publish()

        scope.launch {
            val current = queueState.currentPlayable?.takeIf(::isQueued)
            if (current != null) {
                val generation = beginLoad(current)
                engine.setNormalizationGain(normalizationGain(current))
                val outcome = loadSource(sourceUrlOf(current))
                if (generation != loadGeneration) return@launch

                val savedPosition = resumablePosition(current, queueState.playbackPosition)
                if (outcome == LoadOutcome.READY) {
                    seekTo(savedPosition)
                } else {
                    detachedAt = savedPosition
                    abandonSource()
                }
            }

            syncQueueState()
        }
    }

    @Throws(Exception::class)
    suspend fun playRadio(station: RadioStation): Unit = onMain {
        callOffEpisodeLookup()
        if (!isRadioMode && currentId != null) detachedAt = positionFlow.value

        stopNowPlayingPolling()
        radioStation = station
        radioStreamTitle = null
        isPlaying = false
        isBuffering = true
        hasFailed = false
        publish()

        val generation = ++loadGeneration
        engine.setNormalizationGain(0.0)
        val outcome = loadSource(session.radioStreamUrl(station))
        if (generation != loadGeneration) return@onMain

        isBuffering = false

        if (outcome != LoadOutcome.READY) {
            radioStation = null
            publish()
            throw SourceLoadException("Could not play ${station.name}.")
        }

        isPlaying = true
        publish()
        engine.play()
        startNowPlayingPolling(station)
    }

    fun stopRadio() {
        if (!isRadioMode) return

        loadGeneration++
        stopNowPlayingPolling()
        engine.stop()
        leaveRadioMode()
        isPlaying = false
        isBuffering = false
        hasFailed = false
        publish()
    }

    /** Brings the live radio in line with an edited [station]: a new URL restarts the stream. */
    fun refreshRadioStation(station: RadioStation) {
        val playing = radioStation ?: return
        if (playing.id != station.id) return

        if (playing.url != station.url) {
            scope.launch { runCatching { playRadio(station) } }
        } else {
            radioStation = station
            publish()
        }
    }

    fun cleanUpUponLogout() {
        stopRadio()
        loadGeneration++
        engine.stop()
        queueIds = emptyList()
        currentId = null
        isPlaying = false
        isBuffering = false
        hasFailed = false
        errorCount = 0
        detachedAt = null
        hasFinishedQueue = false
        crossfadingFromId = null
        pendingCrossfadeGeneration = null
        playsWhenLoaded = true
        engineIsPlaying = false
        callOffEpisodeLookup()
        lastReportedSecond = -1
        registeredPlays.clear()
        rememberedPositions.clear()
        dropUnsentQueueState()
        positionFlow.value = 0.0
        publish()
    }

    private suspend fun resume() {
        playsWhenLoaded = true
        if (isRadioMode) {
            val station = radioStation!!
            if (hasFailed) {
                runCatching { playRadio(station) }
                return
            }

            isPlaying = true
            publish()
            engine.play()
            return
        }

        if (isLookingUpEpisode) return
        val current = currentId?.let(playables::byId) ?: return

        // The engine holds no usable source after a failure, so play has to reload the current item rather than
        // resume it.
        if (hasFailed) return startPlaying(current, startAt = detachedAt)

        if (hasFinishedQueue) return startPlaying(current, startAt = 0.0)

        val resumeAt = detachedAt
        if (resumeAt != null) return startPlaying(current, startAt = resumeAt)

        isPlaying = true
        publish()
        engine.play()
    }

    private suspend fun advance(autoPlay: Boolean = true) {
        playAt(nextIndex() ?: return, autoPlay = autoPlay)
    }

    private fun nextIndex(): Int? {
        if (currentIndex == -1) return null

        return when {
            currentIndex + 1 < queueIds.size -> currentIndex + 1
            repeatMode == RepeatMode.ALL -> 0
            else -> null
        }
    }

    private fun playAtLater(playableId: String) {
        scope.launch { playAt(queueIds.indexOf(playableId)) }
    }

    /** A [startAt] picks the current item back up where it left off; without one, it's a fresh play. */
    private suspend fun playAt(index: Int, startAt: Double? = null, autoPlay: Boolean = true) {
        startPlaying(queueIds.getOrNull(index)?.let(playables::byId) ?: return, startAt, autoPlay)
    }

    /** Also plays an item no longer queued, as the current one can be after the queue changed under it. */
    private suspend fun startPlaying(playable: Playable, startAt: Double?, autoPlay: Boolean = true) {
        val startPosition = resumablePosition(playable, startAt ?: rememberedPositions[playable.id] ?: 0.0)
        if (startAt == null) registeredPlays.remove(playable.id)
        hasFinishedQueue = false
        playsWhenLoaded = autoPlay

        if (isRadioMode) {
            stopNowPlayingPolling()
            leaveRadioMode()
        }

        val generation = beginLoad(playable)
        engine.setNormalizationGain(normalizationGain(playable))
        val outcome = loadSource(sourceUrlOf(playable))
        if (generation != loadGeneration) return

        if (outcome == LoadOutcome.READY) {
            errorCount = 0
            seekTo(startPosition)
            if (!playsWhenLoaded) return publish()

            isPlaying = true
            publish()
            engine.play()
            lastReportedSecond = engine.position.toInt()
            reportPlaybackStatus(playable.id, lastReportedSecond)
            return
        }

        errorCount++
        abandonSource()
        if (shouldSkipPast(outcome)) advance(autoPlay = playsWhenLoaded)
    }

    /**
     * A stalled load means the connection is at fault, not the item, and the next one would stall
     * just the same. Every other failure belongs to this item alone, so move past it — but a run
     * of them is something systematic that churning through the queue would only hide.
     */
    private fun shouldSkipPast(outcome: LoadOutcome) =
        outcome == LoadOutcome.FAILED && errorCount < MAX_ERROR_COUNT

    /** A position saved as the item ended would only end it again; such an item starts over. */
    private fun resumablePosition(playable: Playable, seconds: Double): Double =
        if (playable.length > 0 && seconds >= playable.length - FINISHED_MARGIN) 0.0 else seconds

    private fun beginLoad(playable: Playable): Int {
        currentId = playable.id
        hasFailed = false
        isBuffering = true
        detachedAt = null
        lastReportedSecond = -1
        positionFlow.value = 0.0
        publish()
        return ++loadGeneration
    }

    private suspend fun loadSource(url: String): LoadOutcome = awaitLoad { onReady, onFailure ->
        engine.load(url, onReady, onFailure)
    }

    private suspend fun awaitLoad(start: (onReady: () -> Unit, onFailure: (String) -> Unit) -> Unit): LoadOutcome =
        withTimeoutOrNull(sourceLoadTimeout) {
            suspendCancellableCoroutine { continuation ->
                fun settle(outcome: LoadOutcome) {
                    if (continuation.isActive) continuation.resume(outcome)
                }
                start({ settle(LoadOutcome.READY) }, { settle(LoadOutcome.FAILED) })
            }
        } ?: LoadOutcome.TIMED_OUT

    /**
     * Starts the next song [crossfadeSeconds] before the current one ends, when both are songs. After a seek into
     * that window, the fade takes what's left of the current song.
     */
    private fun crossfadeIfDue(playable: Playable, seconds: Double) {
        val duration = crossfadeSeconds()
        if (duration <= 0 || playable !is Song || repeatMode == RepeatMode.ONE || !isPlaying) return

        val remaining = playable.length - seconds
        if (remaining > duration) {
            if (crossfadingFromId == playable.id) crossfadingFromId = null
            return
        }
        if (crossfadingFromId == playable.id || remaining < MIN_CROSSFADE_SECONDS) return

        val next = nextIndex()?.let(queueIds::getOrNull)?.let(playables::byId) as? Song ?: return
        if (next.id == playable.id) return

        crossfadingFromId = playable.id
        scope.launch { crossfadeTo(next, remaining) }
    }

    /** If the next song can't load in time, the current one plays out and the queue moves on as usual. */
    private suspend fun crossfadeTo(next: Song, seconds: Double) {
        val generation = ++loadGeneration
        pendingCrossfadeGeneration = generation
        val outcome = awaitLoad { onReady, onFailure ->
            engine.crossfade(sourceUrlOf(next), seconds, normalizationGain(next), onReady, onFailure)
        }
        if (generation != loadGeneration) return

        pendingCrossfadeGeneration = null
        if (outcome != LoadOutcome.READY) return

        currentId?.let(registeredPlays::remove)
        registeredPlays.remove(next.id)
        currentId = next.id
        errorCount = 0
        detachedAt = null
        lastReportedSecond = 0
        positionFlow.value = 0.0
        publish()
        reportPlaybackStatus(next.id, 0)
    }

    /** A seek, pause or skip means the user is no longer heading into the next song. */
    private fun callOffPendingCrossfade() {
        if (pendingCrossfadeGeneration != loadGeneration) return

        pendingCrossfadeGeneration = null
        crossfadingFromId = null
        loadGeneration++
        engine.cancelCrossfade()
    }

    /** Tears down a source that stalled or errored, leaving a state the user can retry or skip out of. */
    private fun abandonSource() {
        hasFailed = true
        isPlaying = false
        engineIsPlaying = false
        isBuffering = false
        publish()
        engine.stop()
    }

    private fun seekTo(seconds: Double) {
        engine.seek(seconds)
        positionFlow.value = seconds
    }

    private fun sourceUrlOf(playable: Playable): String = localFileUrl(playable) ?: session.sourceUrl(playable)

    private fun ensureInVault(candidates: List<Playable>) {
        val missing = candidates.filter { playables.byId(it.id) == null }
        if (missing.isNotEmpty()) playables.sync(missing)
    }

    private fun setQueue(ids: List<String>) {
        queueIds = ids
        publish()
        syncQueueState()
    }

    private fun leaveRadioMode() {
        radioStation = null
        radioStreamTitle = null
    }

    private fun startNowPlayingPolling(station: RadioStation) {
        nowPlayingJob = scope.launch {
            delay(FIRST_NOW_PLAYING_POLL_DELAY)
            while (true) {
                fetchNowPlaying(station)
                delay(NOW_PLAYING_POLL_INTERVAL)
            }
        }
    }

    private fun stopNowPlayingPolling() {
        nowPlayingJob?.cancel()
        nowPlayingJob = null
    }

    private suspend fun fetchNowPlaying(station: RadioStation) {
        val response = runCatching { api.get("radio/stations/${station.id}/now-playing") }.getOrNull() ?: return
        val title = runCatching { response.jsonObject["stream_title"]?.jsonPrimitive?.contentOrNull }.getOrNull()

        if (radioStation?.id != station.id || title == radioStreamTitle) return
        radioStreamTitle = title
        publish()
    }

    private fun onPositionChanged(seconds: Double) {
        if (isRadioMode) return

        positionFlow.value = seconds
        val playable = currentId?.let(playables::byId) ?: return
        registerPlayIfDue(playable, seconds)
        reportProgressIfDue(playable, seconds)
        crossfadeIfDue(playable, seconds)
    }

    private fun registerPlayIfDue(playable: Playable, seconds: Double) {
        if (playable.length <= 0 || seconds / playable.length <= PLAY_COUNT_THRESHOLD) return
        if (!registeredPlays.add(playable.id)) return

        onPlayRegistered(playable)
        scope.launch {
            runCatching {
                val response = api.post("interaction/play", buildJsonObject { put("song", playable.id) })
                val playCount = response.jsonObject["play_count"]?.jsonPrimitive?.intOrNull ?: return@runCatching
                playables.update(playable.id) { it.withPlayCount(playCount) }
            }
        }
    }

    private fun reportProgressIfDue(playable: Playable, seconds: Double) {
        val second = seconds.toInt()
        if (second % PROGRESS_REPORT_INTERVAL_SECONDS != 0 || second == lastReportedSecond) return

        lastReportedSecond = second
        if (playable is Episode) rememberedPositions[playable.id] = second.toDouble()
        reportPlaybackStatus(playable.id, second)
    }

    private fun onFinished() {
        if (isRadioMode) return

        currentId?.let(registeredPlays::remove)
        currentId?.let(::rememberPlayedThrough)
        engineIsPlaying = false

        if (repeatMode == RepeatMode.ONE) {
            seekTo(0.0)
            engine.play()
            return
        }

        if (nextIndex() == null) {
            hasFinishedQueue = true
            isPlaying = false
            publish()
            return
        }

        scope.launch { advance() }
    }

    /** Replaying an episode played to its end starts it over, not at the last position reported before the end. */
    private fun rememberPlayedThrough(playableId: String) {
        if (playableId in rememberedPositions) rememberedPositions[playableId] = 0.0
    }

    private fun onFailed() {
        if (!isRadioMode) {
            detachedAt = positionFlow.value
            return abandonSource()
        }

        hasFailed = true
        isPlaying = false
        isBuffering = false
        publish()
    }

    private fun syncQueueState() {
        if (!session.supports(Feature.QUEUE_STATE_SYNC)) return

        val ids = queueIds
        val body = buildJsonObject {
            putJsonArray("songs") { ids.forEach { add(JsonPrimitive(it)) } }
            put("song", if (ids.isEmpty()) "" else currentId.orEmpty())
        }
        queueStateUpdates.trySend(body)
    }

    private fun dropUnsentQueueState() {
        queueStateUpdates.tryReceive()
    }

    private fun reportPlaybackStatus(playableId: String, second: Int) {
        if (!session.supports(Feature.QUEUE_STATE_SYNC)) return

        val body = buildJsonObject {
            put("song", playableId)
            put("position", second)
        }
        send { api.put("queue/playback-status", body) }
    }

    private fun send(request: suspend () -> JsonElement) {
        scope.launch { runCatching { request() } }
    }

    private fun publish() {
        stateFlow.value = PlaybackState(
            queue = queueIds.mapNotNull(playables::byId),
            currentIndex = currentIndex,
            current = currentId?.let(playables::byId),
            isPlaying = isPlaying,
            isBuffering = isBuffering,
            hasFailed = hasFailed,
            repeatMode = repeatMode,
            volume = volume,
            radioStation = radioStation,
            radioStreamTitle = radioStreamTitle,
        )
    }

    private inner class EngineListener : AudioEngineListener {
        override fun onPositionChanged(seconds: Double) = this@PlayerController.onPositionChanged(seconds)

        /** The engine stopping on its own, e.g. headphones unplugged, also calls off what is still loading. */
        override fun onPlayingChanged(playing: Boolean) {
            if (engineIsPlaying && !playing) {
                playsWhenLoaded = false
                callOffPendingCrossfade()
            }
            engineIsPlaying = playing
            isPlaying = playing
            publish()
        }

        override fun onBufferingChanged(buffering: Boolean) {
            isBuffering = buffering
            publish()
        }

        override fun onFinished() = this@PlayerController.onFinished()

        override fun onFailed(message: String) = this@PlayerController.onFailed()
    }

    private enum class LoadOutcome { READY, FAILED, TIMED_OUT }

    companion object {
        /**
         * How many items in a row may fail before playback gives up rather than keep skipping. Low,
         * because the common cause of a run of failures is a dead connection, and each skip costs
         * the user their place in the queue.
         */
        const val MAX_ERROR_COUNT = 3

        private const val PROGRESS_REPORT_INTERVAL_SECONDS = 5

        /** Seconds from the end within which an item counts as played through; the last progress report can be a full interval early. */
        private const val FINISHED_MARGIN = PROGRESS_REPORT_INTERVAL_SECONDS + 1.0

        private const val RESTART_THRESHOLD_SECONDS = 5.0

        /** Position updates come every half second; a bigger jump is a seek. */
        private const val MIN_CROSSFADE_SECONDS = 1.0
        private const val PLAY_COUNT_THRESHOLD = 0.25
        private val FIRST_NOW_PLAYING_POLL_DELAY = 2.seconds
        private val NOW_PLAYING_POLL_INTERVAL = 15.seconds
    }
}
