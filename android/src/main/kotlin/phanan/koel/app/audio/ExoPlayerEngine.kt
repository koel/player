package phanan.koel.app.audio

import android.content.Context
import android.net.Uri
import android.os.Handler
import android.os.Looper
import androidx.annotation.OptIn
import androidx.annotation.VisibleForTesting
import androidx.media3.common.AudioAttributes
import androidx.media3.common.C
import androidx.media3.common.MediaItem
import androidx.media3.common.MediaMetadata
import androidx.media3.common.PlaybackException
import androidx.media3.common.Player
import androidx.media3.common.util.UnstableApi
import androidx.media3.exoplayer.DefaultRenderersFactory
import androidx.media3.exoplayer.ExoPlayer
import androidx.media3.exoplayer.audio.AudioSink
import androidx.media3.exoplayer.audio.DefaultAudioSink
import phanan.koel.shared.models.Equalizer
import phanan.koel.shared.models.EqualizerPreset
import phanan.koel.shared.player.AudioEngine
import phanan.koel.shared.player.AudioEngineListener
import kotlin.math.PI
import kotlin.math.cos
import kotlin.math.sin

/**
 * The core's audio engine on Media3's ExoPlayer, which also handles audio focus and unplugged headphones. One
 * player at a time, two while crossfading.
 */
@OptIn(UnstableApi::class)
class ExoPlayerEngine(private val context: Context) : AudioEngine {
    override var listener: AudioEngineListener? = null

    /** Called when a crossfade hands playback to another player, so the media session can follow it. */
    var onPlayerChanged: ((ExoPlayer) -> Unit)? = null

    private var volume = 1f
    private var equalizer = Equalizer.default
    private var metadata = MediaMetadata.EMPTY

    private var active = makeDeck().also { it.takeAudioFocus() }
    private var incoming: Deck? = null
    private var outgoing: Deck? = null
    private var fadeStep: Runnable? = null

    val player: ExoPlayer get() = active.player

    /** True from the start of a crossfade until the previous source has faded out. */
    val isFading: Boolean get() = outgoing != null

    override val position: Double get() = active.player.currentPosition / 1000.0

    private val ticker = Handler(Looper.getMainLooper())
    private val reportPosition = object : Runnable {
        override fun run() {
            listener?.onPositionChanged(position)
            ticker.postDelayed(this, POSITION_INTERVAL_MS)
        }
    }

    override fun load(url: String, onReady: () -> Unit, onFailure: (message: String) -> Unit) {
        callOffCrossfade()
        active.load(url, onReady, onFailure)
    }

    override fun crossfade(url: String, seconds: Double, gainDecibels: Double, onReady: () -> Unit, onFailure: (message: String) -> Unit) {
        callOffCrossfade()
        val deck = makeDeck().apply {
            fadeLevel = 0f
            normalizationGain = gainDecibels
        }
        incoming = deck
        deck.load(
            url,
            onReady = {
                if (deck === incoming) {
                    incoming = null
                    fadeIn(deck, seconds)
                    onReady()
                }
            },
            onFailure = { message ->
                if (deck === incoming) {
                    incoming = null
                    deck.release()
                    onFailure(message)
                }
            },
        )
    }

    override fun cancelCrossfade() {
        incoming?.release()
        incoming = null
    }

    override fun play() {
        active.player.play()
        keepOutgoingInStep()
    }

    override fun pause() {
        cancelCrossfade()
        active.player.pause()
        keepOutgoingInStep()
    }

    override fun stop() {
        callOffCrossfade()
        active.stop()
    }

    override fun seek(seconds: Double) {
        callOffCrossfade()
        active.player.seekTo((seconds * 1000).toLong())
    }

    override fun setVolume(volume: Double) {
        this.volume = volume.toFloat()
        decks.forEach { it.volume = this.volume }
    }

    override fun setNormalizationGain(decibels: Double) {
        active.normalizationGain = decibels
    }

    override fun setEqualizer(preset: EqualizerPreset) {
        equalizer = preset
        decks.forEach { it.applyEqualizer() }
    }

    /** What the notification, lock screen and Bluetooth devices show for the current source. */
    fun describe(title: String, artist: String, artworkUrl: String?) {
        metadata = MediaMetadata.Builder()
            .setTitle(title)
            .setArtist(artist)
            .setArtworkUri(artworkUrl?.let(Uri::parse))
            .build()
        val current = player.currentMediaItem ?: return
        if (current.mediaMetadata != metadata) {
            player.replaceMediaItem(player.currentMediaItemIndex, current.buildUpon().setMediaMetadata(metadata).build())
        }
    }

    private val decks: List<Deck> get() = listOfNotNull(active, incoming, outgoing)

    /** Hands playback to [deck] and fades the previous one out as it fades in. A paused player switches at once. */
    private fun fadeIn(deck: Deck, seconds: Double) {
        val previous = active
        active = deck
        onPlayerChanged?.invoke(deck.player)

        previous.releaseAudioFocus()
        deck.takeAudioFocus()

        if (!previous.player.playWhenReady) {
            previous.release()
            deck.fadeLevel = 1f
            return
        }

        outgoing = previous
        fadeStep = object : Runnable {
            override fun run() {
                val progress = (deck.player.currentPosition / (seconds * 1000)).coerceAtMost(1.0)
                deck.fadeLevel = sin(progress * PI / 2).toFloat()
                previous.fadeLevel = cos(progress * PI / 2).toFloat()
                if (progress >= 1.0) finishFade() else ticker.postDelayed(this, FADE_STEP_MS)
            }
        }
        deck.player.play()
        listener?.onPositionChanged(0.0)
        keepOutgoingInStep()
    }

    /** Only the active player holds audio focus, so the fading-out one follows it when focus or headphones pause it. */
    private fun keepOutgoingInStep() {
        val fading = outgoing ?: return
        val step = fadeStep ?: return
        ticker.removeCallbacks(step)
        if (active.isAudible) {
            fading.player.play()
            ticker.post(step)
        } else {
            fading.player.pause()
        }
    }

    private fun finishFade() {
        fadeStep?.let(ticker::removeCallbacks)
        fadeStep = null
        outgoing?.release()
        outgoing = null
        active.fadeLevel = 1f
    }

    private fun callOffCrossfade() {
        cancelCrossfade()
        finishFade()
    }


    private fun makeDeck(): Deck = Deck().apply {
        volume = this@ExoPlayerEngine.volume
        applyEqualizer()
    }

    @VisibleForTesting
    internal val activeEqualizer: EqualizerPreset get() = active.equalizerProcessor.preset

    private inner class Deck {
        val equalizerProcessor = EqualizerAudioProcessor()

        val player: ExoPlayer = ExoPlayer.Builder(context, EqualizedRenderersFactory(context, equalizerProcessor))
            .setAudioAttributes(MUSIC, false)
            .setHandleAudioBecomingNoisy(true)
            .setWakeMode(C.WAKE_MODE_NETWORK)
            .build()

        var volume = 1f
            set(value) {
                field = value
                applyVolume()
            }

        /** Turns this player's source up or down, in dB, on top of the equalizer. */
        var normalizationGain = 0.0
            set(value) {
                field = value
                applyEqualizer()
            }

        fun applyEqualizer() {
            equalizerProcessor.preset = equalizer.louderBy(normalizationGain)
        }

        /** Where the player is in a crossfade, from silent (0) to full (1). */
        var fadeLevel = 1f
            set(value) {
                field = value
                applyVolume()
            }

        private var pendingLoad: PendingLoad? = null
        private val isActive: Boolean get() = this === active

        val isAudible: Boolean
            get() = player.playWhenReady && player.playbackSuppressionReason == Player.PLAYBACK_SUPPRESSION_REASON_NONE

        init {
            player.addListener(object : Player.Listener {
                override fun onPlaybackStateChanged(state: Int) {
                    if (state == Player.STATE_READY) {
                        pendingLoad?.let { load ->
                            pendingLoad = null
                            load.onReady()
                        }
                    }
                    if (!isActive) return
                    listener?.onBufferingChanged(state == Player.STATE_BUFFERING)
                    if (state == Player.STATE_ENDED) listener?.onFinished()
                }

                override fun onPlayWhenReadyChanged(playWhenReady: Boolean, reason: Int) {
                    if (!isActive) return
                    if (!playWhenReady) cancelCrossfade()
                    listener?.onPlayingChanged(playWhenReady)
                    keepOutgoingInStep()
                }

                override fun onPlaybackSuppressionReasonChanged(reason: Int) {
                    if (isActive) keepOutgoingInStep()
                }

                override fun onIsPlayingChanged(isPlaying: Boolean) {
                    if (!isActive) return
                    ticker.removeCallbacks(reportPosition)
                    if (isPlaying) ticker.post(reportPosition)
                }

                override fun onPlayerError(error: PlaybackException) {
                    val message = error.localizedMessage ?: "Playback failed."
                    val load = pendingLoad
                    pendingLoad = null
                    when {
                        load != null -> load.onFailure(message)
                        isActive -> listener?.onFailed(message)
                    }
                }
            })
        }

        fun load(url: String, onReady: () -> Unit, onFailure: (String) -> Unit) {
            pendingLoad = PendingLoad(onReady, onFailure)
            player.setMediaItem(MediaItem.Builder().setUri(url).setMediaMetadata(metadata).build())
            player.prepare()
        }

        fun stop() {
            pendingLoad = null
            player.pause()
            player.stop()
            player.clearMediaItems()
        }

        fun release() {
            pendingLoad = null
            player.release()
        }

        fun takeAudioFocus() = player.setAudioAttributes(MUSIC, true)

        fun releaseAudioFocus() = player.setAudioAttributes(MUSIC, false)

        private fun applyVolume() {
            player.volume = volume * fadeLevel
        }
    }

    private class EqualizedRenderersFactory(context: Context, private val equalizer: EqualizerAudioProcessor) : DefaultRenderersFactory(context) {
        override fun buildAudioSink(context: Context, enableFloatOutput: Boolean, enableAudioOutputPlaybackParams: Boolean): AudioSink =
            DefaultAudioSink.Builder(context)
                .setEnableFloatOutput(enableFloatOutput)
                .setEnableAudioOutputPlaybackParameters(enableAudioOutputPlaybackParams)
                .setAudioProcessors(arrayOf(equalizer))
                .build()
    }

    private class PendingLoad(val onReady: () -> Unit, val onFailure: (String) -> Unit)

    private companion object {
        const val POSITION_INTERVAL_MS = 500L
        const val FADE_STEP_MS = 30L

        val MUSIC: AudioAttributes = AudioAttributes.Builder()
            .setUsage(C.USAGE_MEDIA)
            .setContentType(C.AUDIO_CONTENT_TYPE_MUSIC)
            .build()
    }
}
