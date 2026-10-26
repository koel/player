package phanan.koel.shared.player

import kotlinx.serialization.json.JsonArray
import kotlinx.serialization.json.JsonObject
import kotlinx.serialization.json.JsonPrimitive
import phanan.koel.shared.models.Playable
import phanan.koel.shared.stores.PlayableStore
import phanan.koel.shared.support.Fixtures
import phanan.koel.shared.support.Harness
import kotlin.test.Test
import kotlin.test.assertEquals

class VolumeNormalizerTest {
    private val h = Harness()
    private val store = PlayableStore(h.api)

    private fun song(loudness: Double?, truePeak: Double?): Playable {
        val analysis = buildMap {
            loudness?.let { put("loudness", JsonPrimitive(it)) }
            truePeak?.let { put("true_peak", JsonPrimitive(it)) }
        }
        return store.sync(JsonArray(listOf(JsonObject(Fixtures.song("s1") + analysis)))).single()
    }

    @Test
    fun aLoudSongIsTurnedDownToTheTarget() {
        assertEquals(-6.0, VolumeNormalizer.gainDecibels(song(loudness = -8.0, truePeak = 0.0), isEnabled = true))
    }

    @Test
    fun aQuietSongIsTurnedUpOnlyAsFarAsItsPeakAllows() {
        assertEquals(6.0, VolumeNormalizer.gainDecibels(song(loudness = -20.0, truePeak = -10.0), isEnabled = true))
        assertEquals(3.0, VolumeNormalizer.gainDecibels(song(loudness = -20.0, truePeak = -4.0), isEnabled = true))
        assertEquals(0.0, VolumeNormalizer.gainDecibels(song(loudness = -20.0, truePeak = 0.5), isEnabled = true))
    }

    @Test
    fun nothingChangesWhenOffUnanalyzedOrNotASong() {
        assertEquals(0.0, VolumeNormalizer.gainDecibels(song(loudness = -8.0, truePeak = 0.0), isEnabled = false))
        assertEquals(0.0, VolumeNormalizer.gainDecibels(song(loudness = null, truePeak = null), isEnabled = true))
        val episode = store.sync(JsonArray(listOf(Fixtures.episode("e1")))).single()
        assertEquals(0.0, VolumeNormalizer.gainDecibels(episode, isEnabled = true))
    }
}
