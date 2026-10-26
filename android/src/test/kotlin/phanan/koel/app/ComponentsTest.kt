package phanan.koel.app

import org.junit.Assert.assertEquals
import org.junit.Assert.assertNull
import org.junit.Test
import phanan.koel.app.ui.components.EpisodeDates
import phanan.koel.app.ui.components.SwipeOutcome
import phanan.koel.app.ui.components.SwipeSettling
import java.time.Instant
import java.time.ZoneOffset
import java.util.Locale

class SwipeSettlingTest {
    @Test
    fun aShortSwipeSnapsBack() {
        assertEquals(SwipeOutcome.Close, SwipeSettling.outcome(distance = 30f, revealWidth = 200f, rowWidth = 1000f))
    }

    @Test
    fun swipingPastHalfTheButtonsKeepsThemOpen() {
        assertEquals(SwipeOutcome.Reveal, SwipeSettling.outcome(distance = -150f, revealWidth = 200f, rowWidth = 1000f))
    }

    @Test
    fun aLongSwipeRunsTheFirstAction() {
        assertEquals(SwipeOutcome.Trigger, SwipeSettling.outcome(distance = 600f, revealWidth = 200f, rowWidth = 1000f))
    }

    @Test
    fun aSideWithoutActionsNeverOpens() {
        assertEquals(SwipeOutcome.Close, SwipeSettling.outcome(distance = 900f, revealWidth = 0f, rowWidth = 1000f))
    }
}

class EpisodeDatesTest {
    private val now = Instant.parse("2026-10-17T12:00:00Z")

    private fun label(createdAt: String) = EpisodeDates.label(createdAt, now, ZoneOffset.UTC, Locale.US)

    @Test
    fun recentEpisodesReadRelative() {
        assertEquals("today", label("2026-10-17T08:00:00Z"))
        assertEquals("yesterday", label("2026-10-16T08:00:00Z"))
        assertEquals("3 days ago", label("2026-10-14T08:00:00Z"))
        assertEquals("last week", label("2026-10-08T08:00:00Z"))
        assertEquals("2 weeks ago", label("2026-10-01T08:00:00Z"))
        assertEquals("last month", label("2026-09-10T08:00:00Z"))
        assertEquals("4 months ago", label("2026-06-10T08:00:00+02:00"))
    }

    @Test
    fun olderEpisodesShowTheirDate() {
        assertEquals("Jan 5, 2026", label("2026-01-05T08:00:00Z"))
    }

    @Test
    fun unreadableDatesShowNothing() {
        assertNull(label("not a date"))
    }
}
