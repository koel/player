package phanan.koel.shared.player

/** Loads succeed at once unless a URL is set to fail or stall. */
class FakeAudioEngine : AudioEngine {
    override var listener: AudioEngineListener? = null
    override var position: Double = 0.0

    val loadedUrls = mutableListOf<String>()
    var playCount = 0
    var pauseCount = 0
    var stopCount = 0
    val seeks = mutableListOf<Double>()
    var volume: Double? = null

    val failingUrls = mutableSetOf<String>()
    val stallingUrls = mutableSetOf<String>()
    var failEveryLoad = false

    var stalledLoad: (() -> Unit)? = null
        private set

    override fun load(url: String, onReady: () -> Unit, onFailure: (message: String) -> Unit) {
        loadedUrls += url
        stalledLoad = null
        when {
            failEveryLoad || url in failingUrls -> onFailure("404")
            url in stallingUrls -> stalledLoad = onReady
            else -> onReady()
        }
    }

    fun loadsOf(url: String) = loadedUrls.count { it == url }

    override fun play() {
        playCount++
    }

    override fun pause() {
        pauseCount++
    }

    override fun stop() {
        stopCount++
    }

    override fun seek(seconds: Double) {
        seeks += seconds
        position = seconds
    }

    override fun setVolume(volume: Double) {
        this.volume = volume
    }

    fun reachPosition(seconds: Double) {
        position = seconds
        listener?.onPositionChanged(seconds)
    }

    fun finish() = listener?.onFinished()

    fun failMidStream() = listener?.onFailed("decoding failure")
}
