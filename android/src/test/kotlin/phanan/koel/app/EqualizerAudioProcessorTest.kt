package phanan.koel.app

import androidx.media3.common.C
import androidx.media3.common.audio.AudioProcessor.AudioFormat
import org.junit.Assert.assertArrayEquals
import org.junit.Assert.assertEquals
import org.junit.Assert.assertTrue
import org.junit.Test
import phanan.koel.app.audio.EqualizerAudioProcessor
import phanan.koel.shared.models.Equalizer
import phanan.koel.shared.models.EqualizerPreset
import java.nio.ByteBuffer
import java.nio.ByteOrder
import kotlin.math.PI
import kotlin.math.abs
import kotlin.math.log10
import kotlin.math.sin
import kotlin.math.sqrt

class EqualizerAudioProcessorTest {
    private val oneKilohertzBoost = Equalizer.default.withGain(Equalizer.frequencies.indexOf(1_000.0), 6.0)

    @Test
    fun leavesSamplesUntouchedWhenFlat() {
        val input = sine(1_000.0, amplitude = 0.5)
        assertArrayEquals(input, processFloats(Equalizer.default, input), 0f)
    }

    @Test
    fun boostsTheBandItsGainIsFor() {
        val boosted = rms(settled(processFloats(oneKilohertzBoost, sine(1_000.0)))) / rms(settled(sine(1_000.0)))
        assertEquals(6.0, decibels(boosted), 0.5)
    }

    @Test
    fun barelyTouchesFrequenciesFarFromTheBand() {
        val boosted = rms(settled(processFloats(oneKilohertzBoost, sine(100.0)))) / rms(settled(sine(100.0)))
        assertEquals(0.0, decibels(boosted), 0.5)
    }

    @Test
    fun preampScalesTheSignal() {
        val input = sine(440.0, amplitude = 0.5)
        val output = processFloats(Equalizer.default.withPreamp(-6.0206), input)
        input.indices.forEach { assertEquals(input[it] / 2, output[it], 1e-4f) }
    }

    @Test
    fun clipsSixteenBitSamplesInsteadOfWrappingAround() {
        val loud = EqualizerPreset(preamp = Equalizer.MAX_DECIBELS)
        val input = ShortArray(FRAME_COUNT) { if (it % 2 == 0) 20_000 else -20_000 }
        val output = processShorts(loud, input)
        output.indices.forEach { assertEquals(if (input[it] > 0) Short.MAX_VALUE else Short.MIN_VALUE, output[it]) }
    }

    @Test
    fun processesEveryChannelOnItsOwn() {
        val processor = processor(C.ENCODING_PCM_FLOAT, channelCount = 2)
        processor.preset = Equalizer.default.withPreamp(-6.0206)
        val left = sine(440.0)
        val interleaved = FloatArray(left.size * 2) { if (it % 2 == 0) left[it / 2] else 0f }
        val output = processor.process(interleaved)
        assertTrue(output.filterIndexed { index, _ -> index % 2 == 1 }.all { it == 0f })
        assertEquals(rms(left) / 2, rms(output.filterIndexed { index, _ -> index % 2 == 0 }.toFloatArray()), 1e-3)
    }

    @Test
    fun takesANewPresetMidStream() {
        val processor = processor(C.ENCODING_PCM_FLOAT)
        val input = sine(440.0, amplitude = 0.5)
        assertArrayEquals(input, processor.process(input), 0f)

        processor.preset = Equalizer.default.withPreamp(-6.0206)
        val quieter = processor.process(input)
        input.indices.forEach { assertEquals(input[it] / 2, quieter[it], 1e-4f) }
    }

    private fun processor(encoding: Int, channelCount: Int = 1) = EqualizerAudioProcessor().apply {
        configure(AudioFormat(SAMPLE_RATE, channelCount, encoding))
        flush()
    }

    private fun processFloats(preset: EqualizerPreset, input: FloatArray): FloatArray =
        processor(C.ENCODING_PCM_FLOAT).also { it.preset = preset }.process(input)

    private fun processShorts(preset: EqualizerPreset, input: ShortArray): ShortArray {
        val processor = processor(C.ENCODING_PCM_16BIT).also { it.preset = preset }
        val buffer = ByteBuffer.allocateDirect(input.size * 2).order(ByteOrder.nativeOrder())
        input.forEach(buffer::putShort)
        buffer.flip()
        processor.queueInput(buffer)
        val output = processor.output
        return ShortArray(output.remaining() / 2) { output.short }
    }

    private fun EqualizerAudioProcessor.process(input: FloatArray): FloatArray {
        val buffer = ByteBuffer.allocateDirect(input.size * 4).order(ByteOrder.nativeOrder())
        input.forEach(buffer::putFloat)
        buffer.flip()
        queueInput(buffer)
        val output = output
        return FloatArray(output.remaining() / 4) { output.float }
    }

    private fun sine(frequency: Double, amplitude: Double = 0.25) =
        FloatArray(FRAME_COUNT) { (amplitude * sin(2 * PI * frequency * it / SAMPLE_RATE)).toFloat() }

    /** Skips the filters' start-up ripple. */
    private fun settled(samples: FloatArray) = samples.copyOfRange(samples.size / 2, samples.size)

    private fun rms(samples: FloatArray) = sqrt(samples.sumOf { it.toDouble() * it } / samples.size)

    private fun decibels(ratio: Double) = 20 * log10(abs(ratio))

    private companion object {
        const val SAMPLE_RATE = 44_100
        const val FRAME_COUNT = SAMPLE_RATE / 2
    }
}
