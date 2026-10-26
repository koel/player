package phanan.koel.shared.models

import kotlin.math.PI
import kotlin.math.abs
import kotlin.math.cos
import kotlin.math.log10
import kotlin.math.sin
import kotlin.math.sqrt
import kotlin.test.Test
import kotlin.test.assertEquals
import kotlin.test.assertNull
import kotlin.test.assertTrue

class EqualizerTest {
    private val sampleRate = 44_100.0

    @Test
    fun aFlatSettingLeavesTheSoundUntouched() {
        Equalizer.filters(Equalizer.default, sampleRate).forEach { filter ->
            assertEquals(0.0, responseInDecibels(filter, 1_000.0), 1e-9)
        }
        assertEquals(1.0, Equalizer.preampGain(Equalizer.default), 1e-12)
    }

    @Test
    fun aPeakingBandBoostsItsOwnFrequencyByItsGain() {
        val boosted = Equalizer.default.withGain(4, 6.0)

        val filter = Equalizer.filters(boosted, sampleRate)[4]

        assertEquals(6.0, responseInDecibels(filter, Equalizer.frequencies[4]), 0.01)
        assertTrue(abs(responseInDecibels(filter, 100.0)) < 0.5, "A 1 kHz band barely touches 100 Hz")
    }

    @Test
    fun theShelvesReachTheirGainAtTheEdges() {
        val preset = Equalizer.default.withGain(0, -9.0).withGain(9, 12.0)
        val filters = Equalizer.filters(preset, sampleRate)

        assertEquals(-9.0, responseInDecibels(filters.first(), 5.0), 0.1)
        assertEquals(12.0, responseInDecibels(filters.last(), 20_000.0), 0.3)
    }

    @Test
    fun thePreampIsInDecibels() {
        assertEquals(0.5, Equalizer.preampGain(Equalizer.default.withPreamp(-6.0206)), 1e-4)
    }

    @Test
    fun tuningABandMakesItACustomSetting() {
        val rock = Equalizer.builtInPresets.single { it.name == "Rock" }

        val tuned = rock.withGain(0, 3.0)

        assertNull(tuned.id)
        assertNull(tuned.name)
        assertEquals(3.0, tuned.gains[0])
        assertEquals(rock.gains.drop(1), tuned.gains.drop(1))
    }

    @Test
    fun aSettingIsMatchedToItsPresetByIdOrByValue() {
        val saved = EqualizerPreset("mine", "Mine", -2.0, List(10) { 1.0 })
        val unnamedFlat = EqualizerPreset(name = "Default")

        assertEquals("Default", Equalizer.presetMatching(unnamedFlat, listOf(saved))?.name)
        assertEquals("mine", Equalizer.presetMatching(saved.copy(id = null, name = null), listOf(saved))?.id)
        assertEquals("Rock", Equalizer.presetMatching(Equalizer.builtInPresets.single { it.name == "Rock" }, emptyList())?.name)
        assertNull(Equalizer.presetMatching(Equalizer.default.withGain(3, 2.5), listOf(saved)))
    }

    @Test
    fun bandsAreDescribedForScreenReaders() {
        assertEquals("60 Hz", Equalizer.bandDescription(0))
        assertEquals("16 kHz", Equalizer.bandDescription(Equalizer.frequencies.lastIndex))
    }

    @Test
    fun bandsAreLabelledLikeOnTheWeb() {
        assertEquals(listOf("60", "170", "310", "600", "1K", "3K", "6K", "12K", "14K", "16K"), Equalizer.frequencies.indices.map(Equalizer::bandLabel))
    }

    private fun responseInDecibels(filter: Biquad, frequency: Double): Double {
        val omega = 2 * PI * frequency / sampleRate
        val numeratorReal = filter.b0 + filter.b1 * cos(omega) + filter.b2 * cos(2 * omega)
        val numeratorImaginary = -(filter.b1 * sin(omega) + filter.b2 * sin(2 * omega))
        val denominatorReal = 1 + filter.a1 * cos(omega) + filter.a2 * cos(2 * omega)
        val denominatorImaginary = -(filter.a1 * sin(omega) + filter.a2 * sin(2 * omega))
        val magnitude = sqrt(numeratorReal * numeratorReal + numeratorImaginary * numeratorImaginary) /
            sqrt(denominatorReal * denominatorReal + denominatorImaginary * denominatorImaginary)
        return 20 * log10(magnitude)
    }
}
