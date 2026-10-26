package phanan.koel.app

import androidx.media3.exoplayer.ExoPlayer
import androidx.test.ext.junit.runners.AndroidJUnit4
import androidx.test.platform.app.InstrumentationRegistry
import org.junit.Assert.assertEquals
import org.junit.Assert.assertFalse
import org.junit.Assert.assertNotNull
import org.junit.Assert.assertTrue
import org.junit.Test
import org.junit.runner.RunWith
import phanan.koel.app.audio.ExoPlayerEngine
import phanan.koel.shared.models.Equalizer
import phanan.koel.shared.player.AudioEngineListener
import java.io.File
import java.nio.ByteBuffer
import java.nio.ByteOrder
import java.util.Collections
import java.util.concurrent.CountDownLatch
import java.util.concurrent.TimeUnit
import kotlin.math.PI
import kotlin.math.sin

@RunWith(AndroidJUnit4::class)
class ExoPlayerEngineTest {
    private val instrumentation = InstrumentationRegistry.getInstrumentation()
    private val context = instrumentation.targetContext

    private fun <T> onMain(block: () -> T): T {
        var result: T? = null
        instrumentation.runOnMainSync { result = block() }
        @Suppress("UNCHECKED_CAST")
        return result as T
    }

    private fun awaitLoad(start: (onReady: () -> Unit, onFailure: (String) -> Unit) -> Unit): String {
        val latch = CountDownLatch(1)
        var outcome = "timed out"
        onMain {
            start({ outcome = "ready"; latch.countDown() }, { outcome = "failed: $it"; latch.countDown() })
        }
        latch.await(10, TimeUnit.SECONDS)
        return outcome
    }

    private fun waitUntil(condition: () -> Boolean) {
        repeat(100) {
            if (onMain(condition)) return
            Thread.sleep(50)
        }
    }

    @Test
    fun crossfadesIntoTheNextSourceAndHandsTheSessionTheNewPlayer() {
        val engine = onMain { ExoPlayerEngine(context) }
        var sessionPlayer: ExoPlayer? = null
        onMain { engine.onPlayerChanged = { sessionPlayer = it } }
        val firstPlayer = onMain { engine.player }

        assertEquals("ready", awaitLoad { onReady, onFailure -> engine.load(toneFile().toURI().toString(), onReady, onFailure) })
        onMain { engine.play() }
        waitUntil { engine.player.isPlaying }

        val outcome = awaitLoad { onReady, onFailure -> engine.crossfade(toneFile().toURI().toString(), 0.5, 3.0, onReady, onFailure) }

        assertEquals("ready", outcome)
        assertTrue(onMain { engine.isFading })
        assertNotNull(sessionPlayer)
        assertTrue(sessionPlayer !== firstPlayer)
        waitUntil { !engine.isFading }
        assertFalse(onMain { engine.isFading })
        assertTrue(onMain { engine.player.isPlaying })
        assertEquals(3.0, onMain { engine.activeEqualizer.preamp }, 0.0)
        onMain { engine.stop() }
    }

    @Test
    fun aLoudnessGainAddsToTheEqualizerPreamp() {
        val engine = onMain { ExoPlayerEngine(context) }

        onMain {
            engine.setEqualizer(Equalizer.default.withPreamp(-2.0))
            engine.setNormalizationGain(3.0)
        }

        assertEquals(1.0, onMain { engine.activeEqualizer.preamp }, 0.0)
        onMain { engine.stop() }
    }

    @Test
    fun changingTracksWhilePlayingNeverReportsAPause() {
        val engine = onMain { ExoPlayerEngine(context) }
        val reportedPlaying = Collections.synchronizedList(mutableListOf<Boolean>())
        onMain { engine.listener = PlayingRecorder(reportedPlaying) }

        assertEquals("ready", awaitLoad { onReady, onFailure -> engine.load(toneFile().toURI().toString(), onReady, onFailure) })
        onMain { engine.play() }
        waitUntil { engine.player.isPlaying }
        assertEquals("ready", awaitLoad { onReady, onFailure -> engine.load(toneFile().toURI().toString(), onReady, onFailure) })
        waitUntil { engine.player.isPlaying }

        assertEquals(listOf(true), reportedPlaying.toList())
        onMain { engine.stop() }
    }

    @Test
    fun pausingWhileTheNextSongLoadsCallsOffTheCrossfade() {
        assertCrossfadeCalledOff { engine -> engine.pause() }
    }

    @Test
    fun seekingWhileTheNextSongLoadsCallsOffTheCrossfade() {
        assertCrossfadeCalledOff { engine -> engine.seek(1.0) }
    }

    @Test
    fun aSystemPauseWhileTheNextSongLoadsCallsOffTheCrossfade() {
        assertCrossfadeCalledOff { engine -> engine.player.pause() }
    }

    @Test
    fun aSystemPauseMidFadePausesTheOutgoingPlayerUntilPlaybackResumes() {
        val engine = onMain { ExoPlayerEngine(context) }
        val outgoingPlayer = onMain { engine.player }
        assertEquals("ready", awaitLoad { onReady, onFailure -> engine.load(toneFile(seconds = 20).toURI().toString(), onReady, onFailure) })
        onMain { engine.play() }
        waitUntil { engine.player.isPlaying }
        assertEquals("ready", awaitLoad { onReady, onFailure -> engine.crossfade(toneFile(seconds = 20).toURI().toString(), 10.0, 0.0, onReady, onFailure) })

        onMain { engine.player.pause() }

        assertFalse(onMain { outgoingPlayer.playWhenReady })
        assertTrue(onMain { engine.isFading })

        onMain { engine.play() }
        waitUntil { outgoingPlayer.isPlaying }
        assertTrue(onMain { outgoingPlayer.isPlaying })
        onMain { engine.stop() }
    }

    @Test
    fun stoppingLeavesTheNextLoadPaused() {
        val engine = onMain { ExoPlayerEngine(context) }
        assertEquals("ready", awaitLoad { onReady, onFailure -> engine.load(toneFile().toURI().toString(), onReady, onFailure) })
        onMain { engine.play() }
        waitUntil { engine.player.isPlaying }

        onMain { engine.stop() }
        assertEquals("ready", awaitLoad { onReady, onFailure -> engine.load(toneFile().toURI().toString(), onReady, onFailure) })

        assertFalse(onMain { engine.player.playWhenReady })
        onMain { engine.stop() }
    }

    private fun assertCrossfadeCalledOff(interrupt: (ExoPlayerEngine) -> Unit) {
        val engine = onMain { ExoPlayerEngine(context) }
        val firstPlayer = onMain { engine.player }
        assertEquals("ready", awaitLoad { onReady, onFailure -> engine.load(toneFile().toURI().toString(), onReady, onFailure) })
        onMain { engine.play() }
        waitUntil { engine.player.isPlaying }

        val outcome = awaitLoad { onReady, onFailure ->
            engine.crossfade(toneFile().toURI().toString(), 0.5, 0.0, onReady, onFailure)
            interrupt(engine)
        }

        assertEquals("timed out", outcome)
        assertTrue(onMain { engine.player === firstPlayer })
        assertFalse(onMain { engine.isFading })
        onMain { engine.stop() }
    }

    private class PlayingRecorder(private val reports: MutableList<Boolean>) : AudioEngineListener {
        override fun onPositionChanged(seconds: Double) = Unit

        override fun onPlayingChanged(playing: Boolean) {
            reports += playing
        }

        override fun onBufferingChanged(buffering: Boolean) = Unit

        override fun onFinished() = Unit

        override fun onFailed(message: String) = Unit
    }

    private fun toneFile(seconds: Int = 3): File {
        val sampleRate = 44_100
        val samples = sampleRate * seconds
        val data = ByteBuffer.allocate(44 + samples * 2).order(ByteOrder.LITTLE_ENDIAN)
        data.put("RIFF".toByteArray()).putInt(36 + samples * 2).put("WAVE".toByteArray())
        data.put("fmt ".toByteArray()).putInt(16).putShort(1).putShort(1).putInt(sampleRate).putInt(sampleRate * 2).putShort(2).putShort(16)
        data.put("data".toByteArray()).putInt(samples * 2)
        repeat(samples) { i -> data.putShort((sin(i * 2 * PI * 440 / sampleRate) * 3_000).toInt().toShort()) }
        return File.createTempFile("tone", ".wav", context.cacheDir).apply { writeBytes(data.array()) }
    }
}
