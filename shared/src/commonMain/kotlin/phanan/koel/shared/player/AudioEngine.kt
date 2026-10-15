package phanan.koel.shared.player

/** Plays one source at a time. Implemented natively (AVPlayer on iOS) and faked in tests. */
interface AudioEngine {
    var listener: AudioEngineListener?

    /** The playhead in seconds. */
    val position: Double

    /** Loads an http(s) or file:// URL and reports once it can play, or why it can't. */
    fun load(url: String, onReady: () -> Unit, onFailure: (message: String) -> Unit)

    fun play()

    fun pause()

    fun stop()

    fun seek(seconds: Double)

    fun setVolume(volume: Double)
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
