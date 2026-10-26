package phanan.koel.shared.models

import kotlinx.serialization.Serializable
import kotlin.math.PI
import kotlin.math.cos
import kotlin.math.pow
import kotlin.math.sin
import kotlin.math.sqrt

/** A preamp and one gain per band, all in dB. Built-in and saved presets have an id; a hand-tuned setting has none. */
@Serializable
data class EqualizerPreset(
    val id: String? = null,
    val name: String? = null,
    val preamp: Double = 0.0,
    val gains: List<Double> = List(Equalizer.frequencies.size) { 0.0 },
) {
    val isFlat: Boolean get() = preamp == 0.0 && gains.all { it == 0.0 }

    fun withPreamp(decibels: Double): EqualizerPreset = copy(id = null, name = null, preamp = decibels)

    /** The same sound, [decibels] louder or quieter, e.g. to even out loudness between songs. */
    fun louderBy(decibels: Double): EqualizerPreset = copy(preamp = preamp + decibels)

    fun withGain(band: Int, decibels: Double): EqualizerPreset =
        copy(id = null, name = null, gains = gains.toMutableList().also { it[band] = decibels })
}

/** One second-order filter, normalized so a0 is 1, as `y = b0·x + b1·x₋₁ + b2·x₋₂ − a1·y₋₁ − a2·y₋₂`. */
data class Biquad(val b0: Double, val b1: Double, val b2: Double, val a1: Double, val a2: Double)

/** Koel web's 10-band equalizer: the same bands, presets and filter shapes, so a preset sounds alike everywhere. */
object Equalizer {
    val frequencies: List<Double> = listOf(60.0, 170.0, 310.0, 600.0, 1_000.0, 3_000.0, 6_000.0, 12_000.0, 14_000.0, 16_000.0)

    const val MAX_DECIBELS = 20.0

    private const val BAND_Q = 1.0

    val default = EqualizerPreset(id = "01KR9JKWWQDDJZ5HT6DBY9DH3Y", name = "Default")

    val builtInPresets: List<EqualizerPreset> = listOf(
        default,
        EqualizerPreset("01KR9JKWWQDDJZ5HT6DBY9DH3Z", "Classical", -1.0, listOf(-1.0, -1.0, -1.0, -1.0, -1.0, -1.0, -7.0, -7.0, -7.0, -9.0)),
        EqualizerPreset("01KR9JKWWQDDJZ5HT6DBY9DH40", "Club", -6.7, listOf(-1.0, -1.0, 8.0, 5.0, 5.0, 5.0, 3.0, -1.0, -1.0, -1.0)),
        EqualizerPreset("01KR9JKWWQDDJZ5HT6DBY9DH41", "Dance", -4.3, listOf(9.0, 7.0, 2.0, -1.0, -1.0, -5.0, -7.0, -7.0, -1.0, -1.0)),
        EqualizerPreset("01KR9JKWWQDDJZ5HT6DBY9DH42", "Full Bass", -7.2, listOf(-8.0, 9.0, 9.0, 5.0, 1.0, -4.0, -8.0, -10.0, -11.0, -11.0)),
        EqualizerPreset("01KR9JKWWQDDJZ5HT6DBY9DH43", "Full Treble", -12.0, listOf(-9.0, -9.0, -9.0, -4.0, 2.0, 11.0, 16.0, 16.0, 16.0, 16.0)),
        EqualizerPreset("01KR9JKWWQDDJZ5HT6DBY9DH44", "Headphone", -8.0, listOf(4.0, 11.0, 5.0, -3.0, -2.0, 1.0, 4.0, 9.0, 12.0, 14.0)),
        EqualizerPreset("01KR9JKWWQDDJZ5HT6DBY9DH45", "Large Hall", -7.2, listOf(10.0, 10.0, 5.0, 5.0, -1.0, -4.0, -4.0, -4.0, -1.0, -1.0)),
        EqualizerPreset("01KR9JKWWQDDJZ5HT6DBY9DH46", "Live", -5.3, listOf(-4.0, -1.0, 4.0, 5.0, 5.0, 5.0, 4.0, 2.0, 2.0, 2.0)),
        EqualizerPreset("01KR9JKWWQDDJZ5HT6DBY9DH47", "Pop", -6.2, listOf(-1.0, 4.0, 7.0, 8.0, 5.0, -1.0, -2.0, -2.0, -1.0, -1.0)),
        EqualizerPreset("01KR9JKWWQDDJZ5HT6DBY9DH48", "Reggae", -8.2, listOf(-1.0, -1.0, -1.0, -5.0, -1.0, 6.0, 6.0, -1.0, -1.0, -1.0)),
        EqualizerPreset("01KR9JKWWQDDJZ5HT6DBY9DH49", "Rock", -10.0, listOf(8.0, 4.0, -5.0, -8.0, -3.0, 4.0, 8.0, 11.0, 11.0, 11.0)),
        EqualizerPreset("01KR9JKWWQDDJZ5HT6DBY9DH4A", "Soft Rock", -5.3, listOf(4.0, 4.0, 2.0, -1.0, -4.0, -5.0, -3.0, -1.0, 2.0, 8.0)),
        EqualizerPreset("01KR9JKWWQDDJZ5HT6DBY9DH4B", "Techno", -7.7, listOf(8.0, 5.0, -1.0, -5.0, -4.0, -1.0, 8.0, 9.0, 9.0, 8.0)),
    )

    /** "60", "1K", "16K", as the web labels the bands. */
    fun bandLabel(band: Int): String {
        val hertz = frequencies[band].toInt()
        return if (hertz >= 1_000) "${hertz / 1_000}K" else hertz.toString()
    }

    /** "60 Hz", "1 kHz", for screen readers. */
    fun bandDescription(band: Int): String {
        val hertz = frequencies[band].toInt()
        return if (hertz >= 1_000) "${hertz / 1_000} kHz" else "$hertz Hz"
    }

    /**
     * The built-in or saved preset [setting] is: by id, or else by its values, so the server's unnamed default
     * still reads as Default. Null for a hand-tuned setting.
     */
    fun presetMatching(setting: EqualizerPreset, saved: List<EqualizerPreset>): EqualizerPreset? {
        val presets = builtInPresets + saved
        return presets.firstOrNull { it.id != null && it.id == setting.id }
            ?: presets.firstOrNull { it.preamp == setting.preamp && it.gains == setting.gains }
    }

    fun preampGain(preset: EqualizerPreset): Double = 10.0.pow(preset.preamp / 20)

    /**
     * The bands as filters at [sampleRate], in order: a low shelf, peaking filters, then a high shelf, using the
     * formulas Web Audio's BiquadFilterNode uses.
     */
    fun filters(preset: EqualizerPreset, sampleRate: Double): List<Biquad> = frequencies.mapIndexed { band, frequency ->
        val gain = preset.gains.getOrElse(band) { 0.0 }
        when (band) {
            0 -> lowShelf(frequency, gain, sampleRate)
            frequencies.lastIndex -> highShelf(frequency, gain, sampleRate)
            else -> peaking(frequency, gain, sampleRate)
        }
    }

    private fun peaking(frequency: Double, gain: Double, sampleRate: Double): Biquad {
        val amplitude = 10.0.pow(gain / 40)
        val omega = 2 * PI * frequency / sampleRate
        val alpha = sin(omega) / (2 * BAND_Q)
        val cosine = cos(omega)
        return normalized(
            b0 = 1 + alpha * amplitude, b1 = -2 * cosine, b2 = 1 - alpha * amplitude,
            a0 = 1 + alpha / amplitude, a1 = -2 * cosine, a2 = 1 - alpha / amplitude,
        )
    }

    private fun lowShelf(frequency: Double, gain: Double, sampleRate: Double): Biquad {
        val amplitude = 10.0.pow(gain / 40)
        val omega = 2 * PI * frequency / sampleRate
        val cosine = cos(omega)
        val shelf = 2 * sqrt(amplitude) * sin(omega) / 2 * sqrt(2.0)
        return normalized(
            b0 = amplitude * ((amplitude + 1) - (amplitude - 1) * cosine + shelf),
            b1 = 2 * amplitude * ((amplitude - 1) - (amplitude + 1) * cosine),
            b2 = amplitude * ((amplitude + 1) - (amplitude - 1) * cosine - shelf),
            a0 = (amplitude + 1) + (amplitude - 1) * cosine + shelf,
            a1 = -2 * ((amplitude - 1) + (amplitude + 1) * cosine),
            a2 = (amplitude + 1) + (amplitude - 1) * cosine - shelf,
        )
    }

    private fun highShelf(frequency: Double, gain: Double, sampleRate: Double): Biquad {
        val amplitude = 10.0.pow(gain / 40)
        val omega = 2 * PI * frequency / sampleRate
        val cosine = cos(omega)
        val shelf = 2 * sqrt(amplitude) * sin(omega) / 2 * sqrt(2.0)
        return normalized(
            b0 = amplitude * ((amplitude + 1) + (amplitude - 1) * cosine + shelf),
            b1 = -2 * amplitude * ((amplitude - 1) + (amplitude + 1) * cosine),
            b2 = amplitude * ((amplitude + 1) + (amplitude - 1) * cosine - shelf),
            a0 = (amplitude + 1) - (amplitude - 1) * cosine + shelf,
            a1 = 2 * ((amplitude - 1) - (amplitude + 1) * cosine),
            a2 = (amplitude + 1) - (amplitude - 1) * cosine - shelf,
        )
    }

    private fun normalized(b0: Double, b1: Double, b2: Double, a0: Double, a1: Double, a2: Double) =
        Biquad(b0 / a0, b1 / a0, b2 / a0, a1 / a0, a2 / a0)
}
