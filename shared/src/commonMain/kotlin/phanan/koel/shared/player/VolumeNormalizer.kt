package phanan.koel.shared.player

import phanan.koel.shared.models.Playable
import phanan.koel.shared.models.Song

/** Koel web's loudness normalization: songs are turned toward the same loudness, never boosted into clipping. */
object VolumeNormalizer {
    private const val TARGET_LOUDNESS_LUFS = -14.0
    private const val MAX_TRUE_PEAK_DBTP = -1.0

    /** How many dB to turn [playable] up or down; 0 when [isEnabled] is false or it hasn't been analyzed. */
    fun gainDecibels(playable: Playable?, isEnabled: Boolean): Double {
        if (!isEnabled || playable !is Song) return 0.0
        val loudness = playable.loudness ?: return 0.0
        val truePeak = playable.truePeak ?: return 0.0

        val gain = TARGET_LOUDNESS_LUFS - loudness
        if (gain <= 0) return gain

        return minOf(gain, maxOf(0.0, MAX_TRUE_PEAK_DBTP - truePeak))
    }
}
