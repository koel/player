package phanan.koel.app.audio

import androidx.annotation.OptIn
import androidx.media3.common.C
import androidx.media3.common.audio.AudioProcessor.AudioFormat
import androidx.media3.common.audio.AudioProcessor.StreamMetadata
import androidx.media3.common.audio.AudioProcessor.UnhandledAudioFormatException
import androidx.media3.common.audio.BaseAudioProcessor
import androidx.media3.common.util.UnstableApi
import phanan.koel.shared.models.Biquad
import phanan.koel.shared.models.Equalizer
import phanan.koel.shared.models.EqualizerPreset
import java.nio.ByteBuffer
import kotlin.math.roundToInt

/**
 * Koel's 10-band equalizer as a step in ExoPlayer's audio pipeline: the preamp, then each band's filter, on every
 * channel. It stays active even when flat, because ExoPlayer only asks whether a processor is active when a stream
 * starts, and a new [preset] has to be heard right away.
 */
@OptIn(UnstableApi::class)
class EqualizerAudioProcessor : BaseAudioProcessor() {
    @Volatile
    var preset: EqualizerPreset = Equalizer.default

    private var appliedPreset: EqualizerPreset? = null
    private var isBypassed = true
    private var preampGain = 1.0
    private var filters: List<Biquad> = emptyList()

    /** Two delayed values per band per channel, for the transposed direct form II. */
    private var filterState = DoubleArray(0)

    override fun onConfigure(inputAudioFormat: AudioFormat): AudioFormat {
        if (inputAudioFormat.encoding != C.ENCODING_PCM_16BIT && inputAudioFormat.encoding != C.ENCODING_PCM_FLOAT) {
            throw UnhandledAudioFormatException(inputAudioFormat)
        }
        return inputAudioFormat
    }

    override fun onFlush(streamMetadata: StreamMetadata) {
        val stateSize = inputAudioFormat.channelCount * Equalizer.frequencies.size * STATES_PER_BAND
        if (filterState.size == stateSize) filterState.fill(0.0) else filterState = DoubleArray(stateSize)
        appliedPreset = null
    }

    override fun onReset() {
        filterState = DoubleArray(0)
        appliedPreset = null
    }

    override fun queueInput(inputBuffer: ByteBuffer) {
        val byteCount = inputBuffer.remaining()
        if (byteCount == 0) return
        val requested = preset
        if (requested !== appliedPreset) apply(requested)

        val output = replaceOutputBuffer(byteCount)
        when {
            isBypassed -> output.put(inputBuffer)
            inputAudioFormat.encoding == C.ENCODING_PCM_FLOAT -> filterFloats(inputBuffer, output)
            else -> filterShorts(inputBuffer, output)
        }
        output.flip()
    }

    private fun apply(requested: EqualizerPreset) {
        appliedPreset = requested
        isBypassed = requested.isFlat
        preampGain = Equalizer.preampGain(requested)
        filters = Equalizer.filters(requested, inputAudioFormat.sampleRate.toDouble())
        if (isBypassed) filterState.fill(0.0)
    }

    private fun filterFloats(input: ByteBuffer, output: ByteBuffer) {
        var channel = 0
        while (input.hasRemaining()) {
            output.putFloat(filter(input.float.toDouble(), channel).toFloat())
            channel = (channel + 1) % inputAudioFormat.channelCount
        }
    }

    private fun filterShorts(input: ByteBuffer, output: ByteBuffer) {
        var channel = 0
        while (input.hasRemaining()) {
            val filtered = filter(input.short / SHORT_SCALE, channel) * SHORT_SCALE
            output.putShort(filtered.coerceIn(Short.MIN_VALUE.toDouble(), Short.MAX_VALUE.toDouble()).roundToInt().toShort())
            channel = (channel + 1) % inputAudioFormat.channelCount
        }
    }

    private fun filter(sample: Double, channel: Int): Double {
        var signal = sample * preampGain
        var stateIndex = channel * filters.size * STATES_PER_BAND
        for (band in filters.indices) {
            val biquad = filters[band]
            val filtered = biquad.b0 * signal + filterState[stateIndex]
            filterState[stateIndex] = biquad.b1 * signal - biquad.a1 * filtered + filterState[stateIndex + 1]
            filterState[stateIndex + 1] = biquad.b2 * signal - biquad.a2 * filtered
            signal = filtered
            stateIndex += STATES_PER_BAND
        }
        return signal
    }

    private companion object {
        const val STATES_PER_BAND = 2
        const val SHORT_SCALE = 32_768.0
    }
}
