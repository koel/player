package phanan.koel.shared.util

import kotlin.math.abs
import kotlin.test.Test
import kotlin.test.assertEquals
import kotlin.test.assertFalse
import kotlin.test.assertTrue

class LyricsTest {
    private fun assertClose(expected: Double, actual: Double) =
        assertTrue(abs(expected - actual) < 0.0001, "Expected $expected, got $actual")

    @Test
    fun detectsSyncedLyricsWithSingleDigitMinutes() {
        assertTrue(Lyrics.isSynced("[0:12.34]First line"))
        assertFalse(Lyrics.isSynced("Just words\non lines"))
    }

    @Test
    fun parsesMultipleTimestampsOnTheSameLine() {
        val lines = Lyrics.parseSynced("[00:05.50][00:07.10]Dual tag line\n[01:02.345]Another line")

        assertEquals(3, lines.size)
        assertClose(5.5, lines[0].time)
        assertClose(7.1, lines[1].time)
        assertEquals("Dual tag line", lines[0].text)
        assertClose(62.345, lines[2].time)
        assertEquals("Another line", lines[2].text)
    }

    @Test
    fun ignoresLinesWithoutTextAfterTimestamps() {
        assertEquals(listOf("Actual text"), Lyrics.parseSynced("[00:01.00]\n[00:02.00]Actual text").map { it.text })
    }

    @Test
    fun parsesRealLrcWithSpacesAfterTimestamps() {
        val lines = Lyrics.parseSynced(
            "[00:19.83] I am my mother's only one\n[00:26.02] It's enough\n[00:34.25] I wear my garment so it shows",
        )

        assertEquals(3, lines.size)
        assertEquals("I am my mother's only one", lines[0].text)
        assertClose(26.02, lines[1].time)
    }

    @Test
    fun findsTheLineBeingSung() {
        val lines = Lyrics.parseSynced("[00:10.00]One\n[00:20.00]Two")

        assertEquals(-1, Lyrics.currentLineIndex(lines, 5.0))
        assertEquals(0, Lyrics.currentLineIndex(lines, 10.0))
        assertEquals(1, Lyrics.currentLineIndex(lines, 99.0))
    }
}
