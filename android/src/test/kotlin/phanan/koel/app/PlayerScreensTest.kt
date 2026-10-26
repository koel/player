package phanan.koel.app

import org.junit.Assert.assertEquals
import org.junit.Assert.assertFalse
import org.junit.Assert.assertNull
import org.junit.Assert.assertTrue
import org.junit.Test
import phanan.koel.app.ui.collections.YearInput
import phanan.koel.app.ui.collections.hasBrowsableArtist
import phanan.koel.app.ui.collections.playlistDetail
import phanan.koel.app.ui.collections.plainText
import phanan.koel.app.ui.collections.pluralized
import phanan.koel.app.ui.player.EqualizerGeometry
import phanan.koel.app.ui.player.Marquee
import phanan.koel.app.ui.player.PlaybackSettingsFormat
import phanan.koel.app.ui.player.VolumeLevels
import phanan.koel.app.ui.player.repeatLabel
import phanan.koel.shared.models.Album
import phanan.koel.shared.models.Equalizer
import phanan.koel.shared.models.EqualizerPreset
import phanan.koel.shared.models.Playlist
import phanan.koel.shared.player.RepeatMode

class CollectionTextTest {
    @Test
    fun playlistDetailNamesTheKindThenCountsSongsAndLength() {
        assertEquals("Standard playlist • 12 songs • 48 min", playlistDetail(Playlist(id = "1", name = "Mix"), songCount = 12, totalSeconds = 48 * 60.0))
        assertEquals("Smart playlist • 1 song • 1 hr 2 min", playlistDetail(Playlist(id = "2", name = "Recent", isSmart = true), songCount = 1, totalSeconds = 62 * 60.0))
    }

    @Test
    fun emptyPlaylistsShowOnlyTheirKind() {
        assertEquals("Standard playlist", playlistDetail(Playlist(id = "1", name = "Mix"), songCount = 0, totalSeconds = 0.0))
        assertEquals("Smart playlist", playlistDetail(Playlist(id = "2", name = "Recent", isSmart = true), songCount = 0, totalSeconds = 0.0))
    }

    @Test
    fun pluralizesCounts() {
        assertEquals("1 episode", pluralized(1, "episode"))
        assertEquals("3 episodes", pluralized(3, "episode"))
    }

    @Test
    fun unknownAndVariousArtistsCannotBeBrowsed() {
        assertTrue(Album(id = "1", name = "Hunting High and Low", artistName = "a-ha").hasBrowsableArtist)
        assertFalse(Album(id = "2", name = "Hits", artistName = "Various Artists").hasBrowsableArtist)
        assertFalse(Album(id = "3", name = "Untitled", artistName = "Unknown Artist").hasBrowsableArtist)
    }

    @Test
    fun yearsKeepFourDigitsAtMost() {
        assertEquals("1988", YearInput.sanitized("19a88"))
        assertEquals("2019", YearInput.sanitized("20190"))
        assertEquals(1985, YearInput.value(" 1985 "))
        assertNull(YearInput.value("abc"))
    }

    @Test
    fun yearsTakeOnlyAsciiDigits() {
        assertEquals("19", YearInput.sanitized("19٨٨"))
    }

    @Test
    fun htmlBecomesPlainParagraphs() {
        assertEquals(
            "a-ha is a \"Norwegian\" band.\n\nIt's from Oslo & more.",
            "<p>a-ha is a &quot;Norwegian&quot; <b>band</b>.</p><br/>\n<br>It&#39;s from Oslo &amp; more.".plainText,
        )
    }
}

class MarqueeTest {
    @Test
    fun holdsStillDuringThePause() {
        assertEquals(0f, Marquee.offset(elapsed = 0f, textWidth = 200f), 0.001f)
        assertEquals(0f, Marquee.offset(elapsed = 2.4f, textWidth = 200f), 0.001f)
    }

    @Test
    fun thenScrollsThirtyPointsASecond() {
        assertEquals(-30f, Marquee.offset(elapsed = 3.5f, textWidth = 200f), 0.001f)
    }

    @Test
    fun startsOverOnceOneCopyAndTheGapHaveScrolledBy() {
        val cycle = Marquee.PAUSE + (200f + Marquee.GAP) / Marquee.POINTS_PER_SECOND
        assertEquals(0f, Marquee.offset(elapsed = cycle + 1f, textWidth = 200f), 0.001f)
    }
}

class PlayerControlsTest {
    @Test
    fun volumeSnapsToTheNearestStep() {
        assertEquals(0, VolumeLevels.level(0f, 15))
        assertEquals(8, VolumeLevels.level(0.5f, 15))
        assertEquals(15, VolumeLevels.level(1.4f, 15))
        assertEquals(0, VolumeLevels.level(-0.2f, 15))
    }

    @Test
    fun repeatModesReadLikeOnIos() {
        assertEquals("Off", repeatLabel(RepeatMode.NONE))
        assertEquals("All", repeatLabel(RepeatMode.ALL))
        assertEquals("One", repeatLabel(RepeatMode.ONE))
    }
}

class EqualizerGeometryTest {
    @Test
    fun mapsGainsFromTheTopOfTheTrack() {
        assertEquals(0f, EqualizerGeometry.fractionFromTop(20f), 1e-6f)
        assertEquals(0.5f, EqualizerGeometry.fractionFromTop(0f), 1e-6f)
        assertEquals(1f, EqualizerGeometry.fractionFromTop(-20f), 1e-6f)
        assertEquals(0.25f, EqualizerGeometry.fractionFromTop(10f), 1e-6f)
        assertEquals(1f, EqualizerGeometry.fractionFromTop(-30f), 1e-6f)
    }

    @Test
    fun readsDragsBackAsSnappedGains() {
        assertEquals(20.0, EqualizerGeometry.decibelsAt(0f), 1e-9)
        assertEquals(0.0, EqualizerGeometry.decibelsAt(0.5f), 1e-9)
        assertEquals(-6.7, EqualizerGeometry.decibelsAt(0.6666f), 1e-9)
        assertEquals(-20.0, EqualizerGeometry.decibelsAt(1.4f), 1e-9)
    }

    @Test
    fun spreadsHandlesEdgeToEdgeAtTheirGains() {
        val handles = EqualizerGeometry.handleCenters(listOf(20f, 0f, -20f), width = 224f)

        assertEquals(listOf(12.0, 112.0, 212.0), handles.map { it.x })
        assertEquals(listOf(0.0, 50.0, 100.0), handles.map { it.y })
    }
}

class PlaybackSettingsFormatTest {
    @Test
    fun groupsPresetsAsBuiltInAndCustomOnlyOnceSomeAreSaved() {
        val builtInOnly = PlaybackSettingsFormat.presetSections(emptyList())
        assertEquals(listOf<String?>(null), builtInOnly.map { it.title })
        assertEquals(Equalizer.builtInPresets.size, builtInOnly.single().options.size)

        val grouped = PlaybackSettingsFormat.presetSections(listOf(EqualizerPreset("saved-1", "Mine")))
        assertEquals(listOf("Built-in", "Custom"), grouped.map { it.title })
        assertEquals(listOf("saved-1" to "Mine"), grouped.last().options)
    }

    @Test
    fun snapsDragsToTenthsWithinTheRange() {
        assertEquals(3.4, PlaybackSettingsFormat.snapped(3.4321f), 1e-9)
        assertEquals(Equalizer.MAX_DECIBELS, PlaybackSettingsFormat.snapped(25f), 1e-9)
    }

    @Test
    fun crossfadeReadsOffAtZero() {
        assertEquals("Off", PlaybackSettingsFormat.crossfade(0))
        assertEquals("5 s", PlaybackSettingsFormat.crossfade(5))
    }
}
