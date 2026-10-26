package phanan.koel.app

import org.junit.Assert.assertEquals
import org.junit.Assert.assertFalse
import org.junit.Assert.assertNull
import org.junit.Assert.assertTrue
import org.junit.Test
import phanan.koel.app.audio.MediaTree
import phanan.koel.app.ui.auth.LoginQrPayload
import phanan.koel.app.ui.auth.normalizedHost
import androidx.compose.ui.graphics.luminance
import androidx.compose.ui.unit.dp
import phanan.koel.app.ui.collections.CoverColor
import phanan.koel.app.ui.collections.collectionDetail
import kotlinx.coroutines.coroutineScope
import kotlinx.coroutines.runBlocking
import phanan.koel.app.ui.components.CollectionLayout
import phanan.koel.app.ui.components.Loading
import phanan.koel.app.ui.components.SortOptions
import phanan.koel.app.ui.components.SortSetting
import phanan.koel.app.ui.home.HomeBlock
import phanan.koel.app.ui.library.AlbumGrid
import phanan.koel.app.ui.main.AppTab
import phanan.koel.app.ui.main.Navigator
import phanan.koel.app.ui.main.Route
import phanan.koel.app.ui.player.Scrubbing
import phanan.koel.app.ui.player.Waveform
import phanan.koel.app.ui.player.playbackTime
import phanan.koel.app.widgets.WidgetSnapshot
import phanan.koel.shared.models.SortOrder
import phanan.koel.shared.storage.KeyValueStore
import java.util.Base64

class HomeBlockTest {
    private val homeBlocks = HomeBlock.entries

    @Test
    fun keepsTheDefaultOrderWithoutAPreference() {
        assertEquals(homeBlocks, HomeBlock.ordered(emptyList()))
    }

    @Test
    fun putsSavedBlocksFirstAndKeepsTheRestInDefaultOrder() {
        val ordered = HomeBlock.ordered(listOf("random-artists", "most-played-songs"))

        assertEquals(listOf(HomeBlock.RandomArtists, HomeBlock.MostPlayedSongs), ordered.take(2))
        assertEquals(homeBlocks - HomeBlock.RandomArtists - HomeBlock.MostPlayedSongs, ordered.drop(2))
    }

    @Test
    fun ignoresUnknownIds() {
        assertEquals(homeBlocks, HomeBlock.ordered(listOf("not-a-block")))
    }
}

class LoginTest {
    @Test
    fun addsHttpsAndDropsTrailingSlashes() {
        assertEquals("https://koel.example.com", " koel.example.com// ".normalizedHost)
        assertEquals("http://192.168.1.2:8000", "http://192.168.1.2:8000/".normalizedHost)
    }

    @Test
    fun readsTheWebUiQrCode() {
        val code = Base64.getEncoder().encodeToString("""{"host":"https://koel.test","token":"one-time"}""".toByteArray())

        assertEquals(LoginQrPayload("https://koel.test", "one-time"), LoginQrPayload.parse(code))
    }

    @Test
    fun ignoresOtherQrCodes() {
        assertNull(LoginQrPayload.parse("https://example.com"))
        assertNull(LoginQrPayload.parse(Base64.getEncoder().encodeToString("""{"host":"x"}""".toByteArray())))
    }
}

class NavigatorTest {
    @Test
    fun eachTabKeepsItsOwnStack() {
        val navigator = Navigator()
        navigator.push(Route.Album("1"))
        navigator.select(AppTab.Library)
        navigator.push(Route.Songs)

        assertEquals(listOf(Route.Library, Route.Songs), navigator.stack(AppTab.Library).toList())
        assertEquals(listOf(Route.Home, Route.Album("1")), navigator.stack(AppTab.Home).toList())
    }

    @Test
    fun pickingTheShownTabAgainGoesBackToItsFirstScreen() {
        val navigator = Navigator()
        navigator.push(Route.RecentlyPlayed)
        navigator.select(AppTab.Home)

        assertEquals(listOf(Route.Home), navigator.stack(AppTab.Home).toList())
    }

    @Test
    fun pickingTheSearchTabAsksForTheSearchField() {
        val navigator = Navigator()

        navigator.select(AppTab.Library)
        assertFalse(navigator.wantsSearchFocus)

        navigator.select(AppTab.Search)
        assertTrue(navigator.wantsSearchFocus)
    }

    @Test
    fun focusingSearchSwitchesToTheSearchTabAndKeepsItsScreens() {
        val store = MemoryStore()
        val navigator = Navigator(store)
        navigator.select(AppTab.Search)
        navigator.push(Route.SearchSongs("abba"))
        navigator.select(AppTab.Library)

        navigator.focusSearch()

        assertEquals(AppTab.Search, navigator.selectedTab)
        assertTrue(navigator.wantsSearchFocus)
        assertEquals(listOf(Route.Search, Route.SearchSongs("abba")), navigator.stack(AppTab.Search).toList())
        assertEquals(AppTab.Search, Navigator(store).selectedTab)
    }

    @Test
    fun reopensWhereTheAppWasLeft() {
        val store = MemoryStore()
        Navigator(store).apply {
            push(Route.Album("1"))
            select(AppTab.Library)
            push(Route.Genres)
            push(Route.Genre("7", "Jazz & Blues"))
        }

        val restored = Navigator(store)

        assertEquals(AppTab.Library, restored.selectedTab)
        assertEquals(listOf(Route.Library, Route.Genres, Route.Genre("7", "Jazz & Blues")), restored.stack(AppTab.Library).toList())
        assertEquals(listOf(Route.Home, Route.Album("1")), restored.stack(AppTab.Home).toList())
    }

    @Test
    fun loggingOutForgetsTheScreens() {
        val store = MemoryStore()
        Navigator(store).apply {
            push(Route.Songs)
            reset()
        }

        assertEquals(listOf(Route.Home), Navigator(store).stack(AppTab.Home).toList())
    }

    @Test
    fun ignoresUnreadableSavedState() {
        val store = MemoryStore().apply { set("navigation", "not json") }

        assertEquals(listOf(Route.Home), Navigator(store).stack(AppTab.Home).toList())
    }

    class MemoryStore : KeyValueStore {
        private val values = mutableMapOf<String, String>()
        override fun get(key: String): String? = values[key]
        override fun set(key: String, value: String?) {
            if (value == null) values.remove(key) else values[key] = value
        }
    }

    @Test
    fun backStopsAtTheFirstScreen() {
        val navigator = Navigator()

        assertFalse(navigator.pop())
        navigator.push(Route.Songs)
        assertTrue(navigator.pop())
        assertEquals(listOf(Route.Home), navigator.stack(AppTab.Home).toList())
    }
}

class FormattingTest {
    @Test
    fun formatsPlaybackTimes() {
        assertEquals("0:00", 0.0.playbackTime)
        assertEquals("3:07", 187.4.playbackTime)
        assertEquals("1:02:45", 3765.0.playbackTime)
    }

    @Test
    fun joinsYearSongCountAndLength() {
        assertEquals("1988 · 10 songs · 1 hr 12 min", collectionDetail(1988, 10, 4320.0))
        assertEquals("1 song · 3 min", collectionDetail(songCount = 1, totalSeconds = 200.0))
    }

    @Test
    fun showsOnlyTheYearWithoutSongs() {
        assertEquals("2019", collectionDetail(2019, 0, 0.0))
        assertNull(collectionDetail(songCount = 0, totalSeconds = 0.0))
    }
}

class SortSettingTest {
    @Test
    fun pickingAnotherFieldSortsAscending() {
        assertEquals(SortSetting("title", SortOrder.ASC), SortSetting("year", SortOrder.DESC).picking("title"))
    }

    @Test
    fun pickingTheSameFieldFlipsTheOrder() {
        assertEquals(SortSetting("title", SortOrder.DESC), SortSetting("title", SortOrder.ASC).picking("title"))
    }

    @Test
    fun playlistsOfferCustomOrderFirstWhenTheServerSupportsIt() {
        assertEquals("position", SortOptions.playlistSongs(supportsCustomOrder = true).first().field)
        assertFalse(SortOptions.playlistSongs(supportsCustomOrder = false).any { it.field == "position" })
    }

    @Test
    fun listsKeepTheirSortInTheSavedPreferences() {
        val savedPreferences = NavigatorTest.MemoryStore()
        val fallback = SortSetting("title", SortOrder.ASC)
        SortSetting.store = savedPreferences

        assertEquals(fallback, SortSetting.remembered("albums", fallback))
        SortSetting.remember("albums", SortSetting("year", SortOrder.DESC))

        assertEquals("year:desc", savedPreferences.get("sort.albums"))
        assertEquals(SortSetting("year", SortOrder.DESC), SortSetting.remembered("albums", fallback))
    }

    @Test
    fun layoutsStartAsAGridAndAreKeptInTheSavedPreferences() {
        val savedPreferences = NavigatorTest.MemoryStore()
        SortSetting.store = savedPreferences

        assertEquals(CollectionLayout.Grid, CollectionLayout.remembered("albums"))
        CollectionLayout.remember("albums", CollectionLayout.List)

        assertEquals("List", savedPreferences.get("layout.albums"))
        assertEquals(CollectionLayout.List, CollectionLayout.remembered("albums"))
        assertEquals(CollectionLayout.Grid, CollectionLayout.remembered("artists"))
    }
}

class MediaTreeTest {
    @Test
    fun playableItemsNameTheirList() {
        assertEquals("album:42" to "song-1", MediaTree.playableLocation("album:42|song-1"))
        assertEquals("favorites" to "song-1", MediaTree.playableLocation("favorites|song-1"))
    }

    @Test
    fun foldersAreNotPlayable() {
        assertNull(MediaTree.playableLocation("albums"))
        assertNull(MediaTree.playableLocation("|song-1"))
        assertNull(MediaTree.playableLocation("album:42|"))
    }
}

class ScrubberTest {
    @Test
    fun dragMovesByTheDistanceDragged() {
        assertEquals(150.0, Scrubbing.target(start = 100.0, moved = 50f, width = 200f, length = 200.0), 0.001)
    }

    @Test
    fun dragStopsAtTheEnds() {
        assertEquals(0.0, Scrubbing.target(10.0, -500f, 200f, 200.0), 0.001)
        assertEquals(200.0, Scrubbing.target(190.0, 500f, 200f, 200.0), 0.001)
    }

    @Test
    fun barsTakeTheLoudestSliceTheyCover() {
        assertEquals(listOf(0.5, 0.9), Waveform.resampled(listOf(0.1, 0.5, 0.9, 0.2), 2))
        assertEquals(listOf(0.0, 0.0, 0.0), Waveform.resampled(emptyList(), 3))
    }

    @Test
    fun levelsStretchToTheFullRange() {
        val levels = List(20) { 0.5 + it * 0.01 }
        val normalized = Waveform.normalized(levels)
        assertEquals(1.0, normalized.last(), 0.001)
        assertTrue(normalized.first() < 0.5 * normalized.last())
        assertEquals(normalized.sorted(), normalized)
    }

    @Test
    fun barsGlowOnlyBehindThePlayhead() {
        assertEquals(1f, Waveform.glow(0f), 0.001f)
        assertEquals(0f, Waveform.glow(0.5f), 0.001f)
        assertEquals(0f, Waveform.glow(-1f), 0.001f)
    }

    @Test
    fun barsRiseLeftToRight() {
        assertEquals(1f, Waveform.rise(0, 10, 0.5f), 0.001f)
        assertEquals(0f, Waveform.rise(9, 10, 0.5f), 0.001f)
        assertEquals(1f, Waveform.rise(9, 10, 1f), 0.001f)
    }
}

class CoverColorTest {
    @Test
    fun greyCoversStayNeutral() {
        assertNull(CoverColor.legibleTint(120, 120, 125))
    }

    @Test
    fun colorfulCoversGetADarkenedTintOfTheirHue() {
        val tint = CoverColor.legibleTint(230, 40, 40)!!

        assertEquals(0.18f, tint.luminance(), 0.01f)
        assertTrue(tint.red > tint.green && tint.red > tint.blue)
    }
}

class AlbumGridTest {
    @Test
    fun aPhoneFitsTwoColumns() = assertEquals(2, AlbumGrid.columnCount(379.dp))

    @Test
    fun widerScreensFitMoreColumns() = assertEquals(4, AlbumGrid.columnCount(700.dp))

    @Test
    fun neverFewerThanOneColumn() = assertEquals(1, AlbumGrid.columnCount(100.dp))
}

class AppShortcutsTest {
    @Test
    fun offersPlayMostRecentOnlyOnceSomethingHasPlayed() {
        val always = listOf(LaunchAction.Search, LaunchAction.PlayFavorites, LaunchAction.PlayDownloaded)

        assertEquals(always, AppShortcuts.actions(hasRecent = false))
        assertEquals(always + LaunchAction.PlayRecent, AppShortcuts.actions(hasRecent = true))
    }
}

class WidgetSnapshotTest {
    private val nowPlaying = WidgetSnapshot.NowPlaying("Take On Me", "a-ha", "https://example.com/cover.jpg", isPlaying = true, isRadio = false)

    private fun recent(vararg ids: String) = ids.map { WidgetSnapshot.RecentItem(it, "Song $it", "Artist", null) }

    @Test
    fun survivesBeingSavedAndReadBack() {
        val store = NavigatorTest.MemoryStore()
        val snapshot = WidgetSnapshot(nowPlaying, recent("1", "2"))

        WidgetSnapshot.write(store, snapshot)

        assertEquals(snapshot, WidgetSnapshot.read(store))
    }

    @Test
    fun readsNothingWhenNothingWasSaved() {
        assertEquals(WidgetSnapshot(), WidgetSnapshot.read(NavigatorTest.MemoryStore()))
    }

    @Test
    fun showsNothingPlayingAfterAFreshStart() {
        assertFalse(WidgetSnapshot(nowPlaying).stopped().nowPlaying!!.isPlaying)
    }

    @Test
    fun keepsTheOlderSavedSongsBelowWhatWasPlayedSinceStarting() {
        val saved = WidgetSnapshot(recentlyPlayed = recent("1", "2", "3"))

        val merged = WidgetSnapshot(recentlyPlayed = recent("3", "9")).keepingOlderRecent(saved)

        assertEquals(listOf("3", "9", "1", "2"), merged.recentlyPlayed.map { it.id })
    }

    @Test
    fun keepsNoMoreSongsThanTheWidgetsShow() {
        val saved = WidgetSnapshot(recentlyPlayed = recent(*Array(WidgetSnapshot.MAX_RECENT_ITEMS) { "old$it" }))

        val merged = WidgetSnapshot(recentlyPlayed = recent("new")).keepingOlderRecent(saved)

        assertEquals(WidgetSnapshot.MAX_RECENT_ITEMS, merged.recentlyPlayed.size)
        assertEquals("new", merged.recentlyPlayed.first().id)
    }
}

class LoadingTest {
    @Test
    fun tryAgainRunsTheSameLoadAsPullToRefresh() = runBlocking {
        val runs = mutableListOf<Boolean>()
        coroutineScope {
            val loading = Loading(this) { forceRefresh -> runs += forceRefresh }
            loading.retry()
            loading.refresh()
        }
        assertEquals(listOf(false, true), runs)
    }

    @Test
    fun aFailedLoadStopsBeingBusyAndRecoversOnTheNextSuccess() = runBlocking {
        var shouldFail = true
        val loading = Loading(this) { if (shouldFail) throw IllegalStateException() }
        assertTrue(loading.isBusy)

        loading.run()
        assertTrue(loading.hasFailed)
        assertFalse(loading.isBusy)

        shouldFail = false
        loading.run(forceRefresh = true)
        assertFalse(loading.hasFailed)
    }
}
