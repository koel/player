package phanan.koel.shared.player

import phanan.koel.shared.models.EqualizerPreset

/** Plays one source at a time, two while crossfading. Implemented natively (AVPlayer on iOS) and faked in tests. */
interface AudioEngine {
    var listener: AudioEngineListener?

    /** The playhead in seconds. */
    val position: Double

    /** Loads an http(s) or file:// URL and reports once it can play, or why it can't. Never starts playback by itself: only [play] does. */
    fun load(url: String, onReady: () -> Unit, onFailure: (message: String) -> Unit)

    /**
     * Loads [url] next to what is playing, [gainDecibels] louder or quieter, and once it can play, fades one into
     * the other over [seconds]. From
     * [onReady] on, [url] is the current source; the one before fades out without reporting anything more.
     * [load], [stop] or [cancelCrossfade] call off a crossfade that hasn't finished.
     */
    fun crossfade(url: String, seconds: Double, gainDecibels: Double, onReady: () -> Unit, onFailure: (message: String) -> Unit)

    /** Discards a [crossfade] source that hasn't become ready, without calling back; the current source plays on. */
    fun cancelCrossfade()

    fun play()

    fun pause()

    /** Drops the current source and leaves the engine paused, so a later [load] stays silent until [play]. */
    fun stop()

    fun seek(seconds: Double)

    fun setVolume(volume: Double)

    /** Turns the current source, and those [load]ed after it, up or down by [decibels] to even out loudness. */
    fun setNormalizationGain(decibels: Double)

    /** Applies to everything played from now on, and to what is playing right away. */
    fun setEqualizer(preset: EqualizerPreset)
}

interface AudioEngineListener {
    fun onPositionChanged(seconds: Double)

    fun onPlayingChanged(playing: Boolean)

    fun onBufferingChanged(buffering: Boolean)

    /** The current source played to its end. */
    fun onFinished()

    /** The current source failed after it had loaded, e.g. the connection dropped mid-stream. */
    fun onFailed(message: String)
}
