package phanan.koel.shared.player

import phanan.koel.shared.onMain
import kotlinx.coroutines.CoroutineScope
import kotlinx.coroutines.Job
import kotlinx.coroutines.delay
import kotlinx.coroutines.flow.MutableStateFlow
import kotlinx.coroutines.flow.StateFlow
import kotlinx.coroutines.flow.asStateFlow
import kotlinx.coroutines.launch
import kotlinx.coroutines.suspendCancellableCoroutine
import kotlinx.coroutines.withTimeoutOrNull
import kotlinx.serialization.json.JsonElement
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

    /** Set once the engine no longer holds the current item's source (stopped, or replaced by radio). */
    private var detachedAt: Double? = null

    private var nowPlayingJob: Job? = null
    private var lastReportedSecond = -1
    private val registeredPlays = mutableSetOf<String>()
    private val rememberedPositions = mutableMapOf<String, Double>()

    private val currentIndex: Int get() = currentId?.let(queueIds::indexOf) ?: -1
    private val isRadioMode: Boolean get() = radioStation != null

    init {
        engine.listener = EngineListener()
        engine.setVolume(volume)
        publish()
        scope.launch { playables.vault.entities.collect { publish() } }
    }

    fun replaceQueue(playables: List<Playable>, shuffle: Boolean, autoPlay: Boolean) {
        ensureInVault(playables)
        val ids = playables.map(Playable::id).distinct()
        setQueue(if (shuffle) ids.shuffled(random) else ids)

        if (autoPlay) scope.launch { playAt(0) }
    }

    /** Jumps to [playable] if it's queued, otherwise queues it after the current item first. */
    fun play(playable: Playable) {
        if (!isQueued(playable)) playNext(playable)
        val index = queueIds.indexOf(playable.id)
        scope.launch { playAt(index) }
    }

    fun playNext(playable: Playable) {
        ensureInVault(listOf(playable))
        val remaining = queueIds - playable.id
        val insertAt = (currentId?.let(remaining::indexOf) ?: -1) + 1
        setQueue(remaining.toMutableList().apply { add(insertAt, playable.id) })
    }

    fun queueToBottom(playable: Playable) {
        ensureInVault(listOf(playable))
        setQueue(queueIds - playable.id + playable.id)
    }

    fun removeFromQueue(playable: Playable) {
        if (isQueued(playable)) setQueue(queueIds - playable.id)
    }

    /** Removing the current item moves playback on to the next one first. */
    fun removeAt(index: Int) {
        if (index == currentIndex) {
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
        isPlaying = false
        publish()
        engine.pause()
    }

    fun togglePlayPause() {
        if (isPlaying) pause() else play()
    }

    fun stop() {
        if (isRadioMode) return stopRadio()

        detachedAt = positionFlow.value
        isPlaying = false
        publish()
        engine.stop()
    }

    fun seek(seconds: Double) {
        positionFlow.value = seconds
        engine.seek(seconds)
    }

    fun skipToNext() {
        scope.launch { advance() }
    }

    /** Past the first five seconds, "previous" restarts the current item instead. */
    fun skipToPrevious() {
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

    /** Where an episode was left off, in seconds; null if it never played here. */
    fun rememberedPosition(playableId: String): Double? = rememberedPositions[playableId]

    /** Seeds where an episode resumes, e.g. from the podcast's saved progress. */
    fun rememberPosition(playableId: String, seconds: Double) {
        rememberedPositions[playableId] = seconds
    }

    /** Loads the server-saved queue without starting playback. */
    fun restore(queueState: QueueState) {
        if (!session.supports(Feature.QUEUE_STATE_SYNC) || queueState.playables.isEmpty()) return

        ensureInVault(queueState.playables)
        queueIds = queueState.playables.map(Playable::id).distinct()
        publish()

        scope.launch {
            val current = queueState.currentPlayable?.takeIf(::isQueued)
            if (current != null) {
                val generation = beginLoad(current)
                val outcome = loadSource(sourceUrlOf(current))
                if (generation != loadGeneration) return@launch

                if (outcome == LoadOutcome.READY) {
                    seekTo(queueState.playbackPosition)
                } else {
                    abandonSource()
                }
            }

            syncQueueState()
        }
    }

    @Throws(Exception::class)
    suspend fun playRadio(station: RadioStation): Unit = onMain {
        if (!isRadioMode && currentId != null) detachedAt = positionFlow.value

        stopNowPlayingPolling()
        radioStation = station
        radioStreamTitle = null
        isPlaying = false
        isBuffering = true
        hasFailed = false
        publish()

        val generation = ++loadGeneration
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
        clearQueue()
        currentId = null
        isPlaying = false
        isBuffering = false
        hasFailed = false
        errorCount = 0
        detachedAt = null
        registeredPlays.clear()
        rememberedPositions.clear()
        positionFlow.value = 0.0
        publish()
    }

    private suspend fun resume() {
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

        // The engine holds no usable source after a failed load, so play has to start the current
        // item over rather than resume it.
        if (hasFailed && currentIndex > -1) return playAt(currentIndex)

        val resumeAt = detachedAt
        if (resumeAt != null && currentIndex > -1) return playAt(currentIndex, startAt = resumeAt)

        isPlaying = true
        publish()
        engine.play()
    }

    private suspend fun advance() {
        playAt(nextIndex() ?: return)
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

    private suspend fun playAt(index: Int, startAt: Double? = null) {
        val playable = queueIds.getOrNull(index)?.let(playables::byId) ?: return
        val startPosition = startAt ?: rememberedPositions[playable.id] ?: 0.0

        if (isRadioMode) {
            stopNowPlayingPolling()
            leaveRadioMode()
        }

        val generation = beginLoad(playable)
        val outcome = loadSource(sourceUrlOf(playable))
        if (generation != loadGeneration) return

        if (outcome == LoadOutcome.READY) {
            errorCount = 0
            seekTo(startPosition)
            isPlaying = true
            publish()
            engine.play()
            lastReportedSecond = engine.position.toInt()
            reportPlaybackStatus(playable.id, lastReportedSecond)
            return
        }

        errorCount++
        abandonSource()
        if (shouldSkipPast(outcome)) advance()
    }

    /**
     * A stalled load means the connection is at fault, not the item, and the next one would stall
     * just the same. Every other failure belongs to this item alone, so move past it — but a run
     * of them is something systematic that churning through the queue would only hide.
     */
    private fun shouldSkipPast(outcome: LoadOutcome) =
        outcome == LoadOutcome.FAILED && errorCount < MAX_ERROR_COUNT

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

    private suspend fun loadSource(url: String): LoadOutcome =
        withTimeoutOrNull(sourceLoadTimeout) {
            suspendCancellableCoroutine { continuation ->
                fun settle(outcome: LoadOutcome) {
                    if (continuation.isActive) continuation.resume(outcome)
                }
                engine.load(url, onReady = { settle(LoadOutcome.READY) }, onFailure = { settle(LoadOutcome.FAILED) })
            }
        } ?: LoadOutcome.TIMED_OUT

    /** Tears down a source that stalled or errored, leaving a state the user can retry or skip out of. */
    private fun abandonSource() {
        hasFailed = true
        isPlaying = false
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

        if (repeatMode == RepeatMode.ONE) {
            seekTo(0.0)
            engine.play()
            return
        }

        if (nextIndex() == null) {
            isPlaying = false
            publish()
            return
        }

        scope.launch { advance() }
    }

    private fun onFailed() {
        if (!isRadioMode) return abandonSource()

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
        send { api.put("queue/state", body) }
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

        override fun onPlayingChanged(playing: Boolean) {
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

        private const val RESTART_THRESHOLD_SECONDS = 5.0
        private const val PLAY_COUNT_THRESHOLD = 0.25
        private const val PROGRESS_REPORT_INTERVAL_SECONDS = 5
        private val FIRST_NOW_PLAYING_POLL_DELAY = 2.seconds
        private val NOW_PLAYING_POLL_INTERVAL = 15.seconds
    }
}
