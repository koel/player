package phanan.koel.app

import android.app.ActivityManager
import android.content.ComponentName
import android.content.Context
import android.content.Intent
import android.view.KeyEvent
import androidx.compose.ui.semantics.SemanticsNode
import androidx.compose.ui.test.isRoot
import androidx.compose.ui.geometry.Offset
import androidx.compose.ui.test.assertCountEquals
import androidx.compose.ui.test.hasAnyAncestor
import androidx.compose.ui.test.onAllNodesWithContentDescription
import org.junit.Assert.assertEquals
import androidx.compose.ui.semantics.SemanticsActions
import androidx.compose.ui.semantics.SemanticsProperties
import androidx.compose.ui.semantics.getOrNull
import androidx.compose.ui.test.ExperimentalTestApi
import androidx.compose.ui.test.SemanticsMatcher
import androidx.compose.ui.test.assertIsFocused
import androidx.compose.ui.test.hasSetTextAction
import androidx.compose.ui.test.onFirst
import androidx.compose.ui.test.onLast
import androidx.compose.ui.test.hasClickAction
import androidx.compose.ui.test.hasContentDescription
import androidx.compose.ui.test.hasText
import androidx.compose.ui.test.junit4.createEmptyComposeRule
import androidx.compose.ui.test.longClick
import androidx.compose.ui.test.onAllNodesWithText
import androidx.compose.ui.test.onNodeWithTag
import androidx.compose.ui.test.onNodeWithText
import androidx.compose.ui.test.performSemanticsAction
import androidx.compose.ui.test.performScrollTo
import androidx.compose.ui.test.onNodeWithContentDescription
import androidx.compose.ui.test.performClick
import androidx.compose.ui.test.performScrollToNode
import androidx.compose.ui.test.performTextInput
import androidx.compose.ui.test.performTouchInput
import androidx.compose.ui.test.swipeLeft
import androidx.compose.ui.test.SemanticsNodeInteraction
import androidx.compose.ui.test.swipeDown
import androidx.compose.ui.test.swipeRight
import androidx.compose.ui.test.swipeUp
import androidx.test.core.app.ActivityScenario
import androidx.test.ext.junit.runners.AndroidJUnit4
import androidx.test.platform.app.InstrumentationRegistry
import androidx.glance.GlanceId
import androidx.glance.action.actionParametersOf
import androidx.media3.common.Player
import androidx.media3.session.MediaBrowser
import androidx.media3.session.MediaLibraryService
import androidx.media3.session.SessionToken
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.guava.await
import kotlinx.coroutines.runBlocking
import org.junit.After
import org.junit.Assert.assertTrue
import org.junit.Before
import org.junit.Rule
import org.junit.Test
import org.junit.runner.RunWith
import java.util.Collections
import phanan.koel.app.audio.PlaybackService
import phanan.koel.app.ui.components.LoadFailure
import phanan.koel.app.ui.components.ScreenBottomPadding
import phanan.koel.app.ui.components.SortSetting
import phanan.koel.app.ui.main.AppTab
import phanan.koel.app.ui.main.Route
import phanan.koel.shared.models.AlbumSortField
import phanan.koel.shared.models.PlayableSortField
import phanan.koel.shared.models.SortOrder
import phanan.koel.app.widgets.TogglePlaybackAction
import phanan.koel.app.ui.search.SEARCH_SKELETON_TAG
import phanan.koel.shared.models.RadioStation
import phanan.koel.shared.models.Song

/** Logs in to [MockKoelServer] and drives the song menu and the queue. */
@OptIn(ExperimentalTestApi::class)
@RunWith(AndroidJUnit4::class)
class PlayerUiTest {
    @get:Rule
    val compose = createEmptyComposeRule()

    private lateinit var server: MockKoelServer
    private lateinit var scenario: ActivityScenario<MainActivity>

    @Before
    fun setUp() {
        val instrumentation = InstrumentationRegistry.getInstrumentation()
        val audio = instrumentation.context.assets.open("tone.mp3").use { it.readBytes() }
        server = MockKoelServer(audio).apply { start() }

        runBlocking(Dispatchers.Main) { app.logOut().join() }
        instrumentation.targetContext.getSharedPreferences("koel", Context.MODE_PRIVATE).edit().clear().commit()
        startLoggedIn()
    }

    /** The app model outlives the activity, so close any sheet and log out for the next test to start at the login screen. */
    @After
    fun tearDown() {
        runBlocking(Dispatchers.Main) {
            app.sheet = null
            app.logOut().join()
        }
        scenario.close()
        server.stop()
    }

    @Test
    fun longPressingAnAlbumOnTheArtistScreenShowsItsMenu() {
        openSongs()
        compose.onAllNodesWithText(MockKoelServer.SONG_TITLES[1])[0].performTouchInput { longClick() }
        compose.waitUntilAtLeastOneExists(hasText("Go to Artist"), 5_000)
        compose.onNodeWithText("Go to Artist").performClick()
        compose.waitUntilAtLeastOneExists(hasText("Albums"), 15_000)
        val screen = compose.onAllNodes(hasScrollToNodeAction).onLast()
        screen.performScrollToNode(hasText(MockKoelServer.ALBUM_NAME))
        screen.performTouchInput { swipeUp() }

        val albumCard = hasText(MockKoelServer.ALBUM_NAME) and hasAnyAncestor(SemanticsMatcher.keyIsDefined(SemanticsProperties.HorizontalScrollAxisRange))
        compose.onNode(albumCard).performTouchInput { longClick() }

        compose.waitUntilAtLeastOneExists(hasText("Play Last"), 5_000)
    }

    @Test
    fun longPressingASongShowsItsMenu() {
        openSongs()

        compose.onAllNodesWithText(MockKoelServer.SONG_TITLES[1])[0].performTouchInput { longClick() }

        compose.waitUntilAtLeastOneExists(hasText("Play Next"), 5_000)
        compose.onNodeWithText("Go to Album").assertExists()
    }

    @Test
    fun swipingAQueuedSongRemovesIt() {
        openQueue()

        val removed = MockKoelServer.SONG_TITLES[3]
        compose.onAllNodes(hasScrollToNodeAction).onLast().performScrollToNode(hasText(removed))
        val countBefore = compose.onAllNodesWithText(removed).fetchSemanticsNodes().size
        compose.onAllNodesWithText(removed)[countBefore - 1].performTouchInput { swipeLeft(startX = width * 0.8f, endX = 0f) }

        compose.waitUntil(5_000) { compose.onAllNodesWithText(removed).fetchSemanticsNodes().size == countBefore - 1 }
    }

    @Test
    fun longPressingAQueuedSongShowsItsMenu() {
        openQueue()

        val queuedRow = queuedRow(MockKoelServer.SONG_TITLES[3])
        compose.onAllNodes(hasScrollToNodeAction).onLast().performScrollToNode(queuedRow)
        compose.onNode(queuedRow).performTouchInput { longClick() }

        compose.waitUntilAtLeastOneExists(hasText("Go to Album"), 5_000)
    }

    @Test
    fun queuedSongsHaveNoDownloadOrMoreButtons() {
        openQueue()

        val queuedRow = queuedRow(MockKoelServer.SONG_TITLES[3])
        compose.onAllNodes(hasScrollToNodeAction).onLast().performScrollToNode(queuedRow)

        compose.onNode(queuedRow).assertExists()
        compose.onAllNodes(hasContentDescription("More") and hasAnyAncestor(queuedRow)).assertCountEquals(0)
        compose.onAllNodes(hasContentDescription("Download") and hasAnyAncestor(queuedRow)).assertCountEquals(0)
    }

    @Test
    fun draggingAHandleDownReordersTheQueue() {
        openQueue()
        compose.onAllNodes(hasScrollToNodeAction).onLast().performScrollToNode(queuedRow(MockKoelServer.SONG_TITLES[10]))
        val orderBefore = app.core.player.state.value.queue.map { it.id }

        compose.onAllNodesWithContentDescription("Reorder", useUnmergedTree = true)[5].performTouchInput {
            down(center)
            repeat(20) {
                advanceEventTime(30)
                moveBy(Offset(0f, 15f))
            }
            advanceEventTime(300)
            up()
        }

        compose.waitUntil(5_000) { app.core.player.state.value.queue.map { it.id } != orderBefore }
        assertEquals(orderBefore.toSet(), app.core.player.state.value.queue.map { it.id }.toSet())
    }

    @Test
    fun thePlayFavoritesShortcutPlaysTheFavorites() {
        scenario.onActivity { it.startActivity(LaunchAction.PlayFavorites.intent(it)) }

        compose.waitUntil(15_000) {
            val state = app.core.player.state.value
            state.isPlaying && state.queue.map { it.title }.toSet() == MockKoelServer.SONG_TITLES.take(MockKoelServer.FAVORITE_COUNT).toSet()
        }
    }

    @Test
    fun theSearchShortcutClosesNowPlaying() {
        scenario.onActivity { it.startActivity(LaunchAction.PlayFavorites.intent(it)) }
        compose.waitUntil(15_000) { app.core.player.state.value.isPlaying }
        runBlocking(Dispatchers.Main) { app.isNowPlayingShown = true }

        scenario.onActivity { it.startActivity(LaunchAction.Search.intent(it)) }

        compose.waitUntil(5_000) { !app.isNowPlayingShown }
        compose.onNode(hasSetTextAction()).assertIsFocused()
    }

    @Test
    fun pickingTheSearchTabFocusesTheSearchField() {
        compose.onNodeWithText("Search").performClick()

        compose.onNode(hasSetTextAction()).assertIsFocused()
    }

    @Test
    fun theLibraryShowsTheAlbumsAddedLast() {
        compose.onNodeWithText("Library").performClick()
        compose.waitUntilAtLeastOneExists(hasText("Recently added"), 10_000)
        compose.onAllNodes(hasScrollToNodeAction).onLast().performScrollToNode(hasText(MockKoelServer.ALBUM_NAME))

        compose.onNodeWithText(MockKoelServer.ALBUM_NAME).performClick()
        compose.waitUntilAtLeastOneExists(hasText(MockKoelServer.SONG_TITLES[0]), 10_000)
    }

    @Test
    fun albumsCanBeListed() {
        compose.onNodeWithText("Library").performClick()
        compose.waitUntilAtLeastOneExists(hasText("Albums"), 5_000)
        compose.onNodeWithText("Albums").performClick()
        compose.waitUntilAtLeastOneExists(hasText(MockKoelServer.ALBUM_NAME), 15_000)

        compose.onNodeWithContentDescription("Sort").performClick()
        compose.onNodeWithText("List").performClick()

        val isSingleColumn = SemanticsMatcher("is a single-column list") { it.config.getOrNull(SemanticsProperties.CollectionInfo)?.columnCount == 1 }
        compose.waitUntilAtLeastOneExists(hasText(MockKoelServer.ALBUM_NAME) and hasAnyAncestor(isSingleColumn), 5_000)
        compose.onNode(hasText("Test Artist") and hasAnyAncestor(isSingleColumn)).assertExists()
    }

    @Test
    fun theLibraryShowsTheMostPlayedSongs() {
        compose.onNodeWithText("Library").performClick()
        compose.waitUntilAtLeastOneExists(hasText("Recently added"), 10_000)
        val list = compose.onAllNodes(hasScrollToNodeAction).onLast()

        list.performScrollToNode(hasText("Most played"))
        list.performScrollToNode(hasText(MockKoelServer.SONG_TITLES[0]))
        compose.onAllNodesWithText(MockKoelServer.SONG_TITLES[0]).onFirst().assertExists()
    }

    @Test
    fun podcastsListTheNewEpisodesFirst() {
        compose.onNodeWithText("Library").performClick()
        compose.onNodeWithText("Podcasts").performClick()

        compose.waitUntilAtLeastOneExists(hasText("New Episodes"), 10_000)
        compose.waitUntilAtLeastOneExists(hasText("Episode 3"), 10_000)
        compose.waitUntilAtLeastOneExists(hasText(MockKoelServer.PODCAST_TITLE), 10_000)
    }

    @Test
    fun theLibrarysRadioCanAddAStation() {
        compose.onNodeWithText("Library").performClick()
        compose.onNodeWithText("Radio").performClick()
        compose.onNodeWithContentDescription("New Station").performClick()

        compose.waitUntilAtLeastOneExists(hasText("New Station"), 5_000)
    }

    @Test
    fun aUserWhoCannotManageRadioCannotAddAStation() {
        server.canManageRadioStations = false
        runBlocking(Dispatchers.Main) { app.core.auth.fetchCurrentUser() }
        compose.onNodeWithText("Library").performClick()
        compose.onNodeWithText("Radio").performClick()
        compose.waitUntilAtLeastOneExists(hasText("No radio stations"), 10_000)

        compose.onNodeWithContentDescription("New Station").assertDoesNotExist()
        compose.onNodeWithText("Add a Station").assertDoesNotExist()
    }

    @Test
    fun theEndOfAListStaysClearOfTheNavigationBar() {
        openSongs()
        val list = compose.onAllNodes(hasScrollToNodeAction).onLast()
        val lastSong = hasText(MockKoelServer.SONG_TITLES.last())
        list.performScrollToNode(lastSong)
        list.performTouchInput { swipeUp() }
        compose.waitForIdle()

        val listBottom = list.fetchSemanticsNode().boundsInRoot.bottom
        val rowBottom = compose.onAllNodes(hasClickAction() and lastSong).onLast().fetchSemanticsNode().boundsInRoot.bottom
        val gap = with(compose.density) { (listBottom - rowBottom).toDp() }
        assertTrue("The last song sits against the navigation bar ($gap)", gap >= ScreenBottomPadding)
    }

    @Test
    fun searchingShowsSkeletonsUntilTheResultsArrive() {
        compose.onNodeWithText("Search").performClick()
        compose.onNode(hasSetTextAction()).performTextInput("song")

        compose.onNodeWithTag(SEARCH_SKELETON_TAG).assertExists()
        compose.waitUntilAtLeastOneExists(hasText(MockKoelServer.SONG_TITLES[0]), 10_000)
        compose.onNodeWithTag(SEARCH_SKELETON_TAG).assertDoesNotExist()
    }

    @Test
    fun theAlbumScreenMenuOffersWhatTheAlbumLongPressMenuDoes() {
        compose.onNodeWithText("Library").performClick()
        compose.waitUntilAtLeastOneExists(hasText("Recently added"), 10_000)
        compose.onAllNodes(hasScrollToNodeAction).onLast().performScrollToNode(hasText(MockKoelServer.ALBUM_NAME))
        val longPressMenu = longPressMenuLabels(MockKoelServer.ALBUM_NAME)

        compose.onNodeWithText(MockKoelServer.ALBUM_NAME).performClick()
        compose.waitUntilAtLeastOneExists(hasText(MockKoelServer.SONG_TITLES[0]), 10_000)

        assertEquals(longPressMenu, overflowMenuLabels())
        assertTrue(longPressMenu.containsAll(listOf("Play", "Shuffle", "Play Next", "Play Last", "Go to Artist")))
    }

    @Test
    fun thePlaylistScreenMenuOffersWhatThePlaylistLongPressMenuDoes() {
        openLibrary("Playlists")
        compose.waitUntilAtLeastOneExists(hasText(MockKoelServer.PLAYLIST_NAME), 10_000)
        val longPressMenu = longPressMenuLabels(MockKoelServer.PLAYLIST_NAME)

        compose.onNodeWithText(MockKoelServer.PLAYLIST_NAME).performClick()
        compose.waitUntilAtLeastOneExists(hasText(MockKoelServer.SONG_TITLES[0]), 10_000)

        assertEquals(longPressMenu, overflowMenuLabels())
        assertEquals(listOf("Play Last", "Edit…", "Delete"), longPressMenu)
    }

    @Test
    fun thePodcastScreenMenuOffersWhatThePodcastLongPressMenuDoes() {
        openLibrary("Podcasts")
        compose.waitUntilAtLeastOneExists(hasText(MockKoelServer.PODCAST_TITLE), 10_000)
        val longPressMenu = longPressMenuLabels(MockKoelServer.PODCAST_TITLE)

        compose.onNodeWithText(MockKoelServer.PODCAST_TITLE).performClick()
        compose.waitUntilAtLeastOneExists(hasText("Episode 1"), 10_000)

        assertEquals(longPressMenu, overflowMenuLabels())
        assertTrue(longPressMenu.containsAll(listOf("Play All", "Shuffle", "Refresh", "Unsubscribe")))
    }

    @Test
    fun newPlaylistFromAddToPlaylistOpensThePlaylistForm() {
        openSongs()
        compose.onAllNodesWithText(MockKoelServer.SONG_TITLES[1])[0].performTouchInput { longClick() }
        compose.waitUntilAtLeastOneExists(hasText("Add to a Playlist…"), 5_000)
        compose.onNodeWithText("Add to a Playlist…").performClick()

        compose.waitUntilAtLeastOneExists(hasText("New Playlist…"), 5_000)
        compose.onNodeWithText("New Playlist…").performClick()

        compose.waitUntilAtLeastOneExists(hasText("Playlist Name"), 5_000)
        compose.onNodeWithText("Description (optional)").assertExists()
        compose.onNodeWithText("Create").assertExists()
    }

    @Test
    fun nowPlayingOpensThePlaybackSettings() {
        openQueue()

        compose.onNodeWithContentDescription("Playback settings").performClick()

        compose.waitUntilAtLeastOneExists(hasText("Equalizer"), 5_000)
        compose.onNodeWithText("Crossfade").assertExists()
    }

    @Test
    fun aSongThatWontPlayShowsABriefError() {
        openQueue()
        server.streamsAudio = false
        compose.onAllNodesWithContentDescription("Next").onLast().performClick()

        compose.waitUntilAtLeastOneExists(hasText("Couldn't play this item"), 20_000)
        compose.waitUntilDoesNotExist(hasText("Couldn't play this item"), 5_000)
    }

    @Test
    fun pickingAPresetChangesTheEqualizer() {
        openPlaybackSettingsFromProfile()

        compose.onNodeWithText("Preset").performClick()
        compose.onNodeWithText("Rock").performScrollTo().performClick()

        compose.waitUntil(5_000) { app.core.playbackSettings.equalizer.value.name == "Rock" }
    }

    @Test
    fun draggingABandTunesTheEqualizerByHand() {
        openPlaybackSettingsFromProfile()

        compose.onNodeWithContentDescription("60 Hz").performSemanticsAction(SemanticsActions.SetProgress) { it(6f) }

        compose.waitUntil(5_000) { app.core.playbackSettings.equalizer.value.gains.first() == 6.0 }
        assertEquals(null, app.core.playbackSettings.equalizer.value.id)
        compose.onNodeWithText("Custom").assertExists()
    }

    @Test
    fun presetsCanBeSavedAndRemovedOnlyWhenTheServerKeepsThem() {
        openPlaybackSettingsFromProfile()
        tuneTheFirstBand(6f)
        compose.onNodeWithText("Save as…").assertDoesNotExist()

        server.keepsEqualizerPresets = true
        runBlocking(Dispatchers.Main) { app.core.auth.fetchCurrentUser() }
        compose.waitUntilAtLeastOneExists(hasText("Save as…"), 5_000)

        compose.onNodeWithText("Preset").performClick()
        compose.onNodeWithText("Built-in").assertExists()
        compose.onNodeWithText(MockKoelServer.SAVED_PRESET_NAME).performScrollTo().performClick()
        compose.onNodeWithText("Save as…").assertDoesNotExist()
        compose.onNodeWithText("Remove").performClick()
        compose.waitUntilAtLeastOneExists(hasText("Remove preset?"), 5_000)
        compose.onAllNodesWithText("Remove").onLast().performClick()
        compose.waitUntil(5_000) { app.core.playbackSettings.customPresets.value.isEmpty() }

        compose.waitUntilAtLeastOneExists(hasText("Save as…"), 5_000)
        compose.onNodeWithText("Save as…").performClick()
        compose.waitUntilAtLeastOneExists(hasText("Name"), 5_000)
        compose.onNodeWithText("Name").performTextInput("Loud")
        compose.onNodeWithText("Save").performClick()
        compose.waitUntil(5_000) { app.core.playbackSettings.equalizer.value.name == "Loud" }
    }

    @Test
    fun pickingAPresetHidesSaveAs() {
        server.keepsEqualizerPresets = true
        runBlocking(Dispatchers.Main) { app.core.auth.fetchCurrentUser() }
        openPlaybackSettingsFromProfile()
        tuneTheFirstBand(6f)
        compose.waitUntilAtLeastOneExists(hasText("Save as…"), 5_000)

        compose.onNodeWithText("Preset").performClick()
        compose.onNodeWithText("Rock").performScrollTo().performClick()

        compose.waitUntil(5_000) { compose.onAllNodesWithText("Save as…").fetchSemanticsNodes().isEmpty() }
        compose.onNodeWithText("Remove").assertDoesNotExist()
    }

    @Test
    fun tappingAnAlbumSongQueuesItAfterTheCurrentOneInsteadOfReplacingTheQueue() {
        playFavorites()
        openAlbum()

        tapSongRow(MockKoelServer.SONG_TITLES[9])

        assertTappedSongJoinedTheQueue(MockKoelServer.SONG_TITLES[9])
    }

    @Test
    fun tappingAPlaylistSongQueuesItAfterTheCurrentOneInsteadOfReplacingTheQueue() {
        playFavorites()
        openLibrary("Playlists")
        compose.waitUntilAtLeastOneExists(hasText(MockKoelServer.PLAYLIST_NAME), 10_000)
        compose.onNodeWithText(MockKoelServer.PLAYLIST_NAME).performClick()
        compose.waitUntilAtLeastOneExists(hasText(MockKoelServer.SONG_TITLES[0]), 10_000)

        tapSongRow(MockKoelServer.SONG_TITLES[4])

        assertTappedSongJoinedTheQueue(MockKoelServer.SONG_TITLES[4])
    }

    @Test
    fun theAlbumScreenMenuPlaysTheWholeAlbumWhileFiltered() {
        openAlbum()
        compose.onNode(hasSetTextAction()).performTextInput(MockKoelServer.SONG_TITLES[0])
        compose.waitUntil(5_000) { compose.onAllNodesWithText(MockKoelServer.SONG_TITLES[1]).fetchSemanticsNodes().isEmpty() }

        openOverflowMenu()
        compose.onAllNodesWithText("Play").onLast().performClick()

        compose.waitUntil(10_000) { app.core.player.state.value.queue.size == MockKoelServer.SONG_TITLES.size }
    }

    @Test
    fun theAlbumYearFieldKeepsOnlyFourDigitsWhileTyping() {
        openAlbum()
        openOverflowMenu()
        compose.onNodeWithText("Edit…").performClick()
        compose.waitUntilAtLeastOneExists(hasText("Year (optional)"), 5_000)

        compose.onNodeWithText("Year (optional)").performTextInput("19a885")

        compose.onNode(hasSetTextAction() and hasText("1988")).assertExists()
    }

    @Test
    fun homesRecentlyPlayedFollowsWhatWasJustPlayed() {
        val justPlayed = MockKoelServer.SONG_TITLES[19]
        compose.onAllNodesWithText(justPlayed).assertCountEquals(0)

        runBlocking(Dispatchers.Main) { app.core.recentlyPlayed.add(Song(id = "song-20", title = justPlayed)) }

        compose.waitUntilAtLeastOneExists(hasText(justPlayed), 5_000)
    }

    @Test
    fun homesRecentlyPlayedRowsHaveNoQueueSwipes() {
        compose.waitUntilAtLeastOneExists(hasText(MockKoelServer.SONG_TITLES[0]), 10_000)

        revealLeadingSwipe(compose.onAllNodesWithText(MockKoelServer.SONG_TITLES[0]).onFirst())

        compose.onNodeWithText("Play Next").assertDoesNotExist()
    }

    @Test
    fun searchSongResultsHaveNoQueueSwipes() {
        compose.onNodeWithText("Search").performClick()
        compose.onNode(hasSetTextAction()).performTextInput("song")
        compose.waitUntilAtLeastOneExists(hasText(MockKoelServer.SONG_TITLES[0]), 10_000)

        revealLeadingSwipe(compose.onAllNodesWithText(MockKoelServer.SONG_TITLES[0]).onFirst())

        compose.onNodeWithText("Play Next").assertDoesNotExist()
    }

    @Test
    fun recentlyPlayedLoadsOnceAndHasNoPullToRefresh() {
        openRecentlyPlayed()
        compose.waitUntil(10_000) { server.requestCount(RECENTLY_PLAYED_PATH) == 1 }
        compose.onAllNodes(hasScrollToNodeAction).onLast().performTouchInput { swipeDown() }
        goBack()
        openRecentlyPlayed()

        assertRequestedOnce(RECENTLY_PLAYED_PATH)
    }

    @Test
    fun filteringFavoritesToNothingShowsNoResults() {
        openLibrary("Favorites")
        compose.waitUntilAtLeastOneExists(hasText(MockKoelServer.SONG_TITLES[0]), 15_000)

        compose.onNode(hasSetTextAction() and hasText("Filter")).performTextInput("zzzz")

        compose.waitUntilAtLeastOneExists(hasText("No Results", substring = true), 5_000)
    }

    @Test
    fun favoritesDoNotRefetchWhenOpenedAgain() {
        openLibrary("Favorites")
        compose.waitUntil(10_000) { server.requestCount(FAVORITES_PATH) == 1 }
        goBack()
        compose.waitUntil(5_000) { compose.onAllNodesWithText("Favorites").fetchSemanticsNodes().size == 1 }
        compose.onNodeWithText("Favorites").performClick()

        assertRequestedOnce(FAVORITES_PATH)
    }

    @Test
    fun aTitleSortedGenreHasASideIndexThatStaysWhileFiltering() {
        openGenre()
        compose.onNodeWithContentDescription("Section Index").assertExists()

        compose.onNode(hasSetTextAction()).performTextInput("Genre Song")

        compose.onNodeWithContentDescription("Section Index").assertExists()
    }

    @Test
    fun aGenreKeepsLoadingPagesWhileFiltering() {
        openGenre()

        compose.onNode(hasSetTextAction()).performTextInput(MockKoelServer.GENRE_LAST_PAGE_SONG)

        compose.waitUntilAtLeastOneExists(hasText(MockKoelServer.GENRE_LAST_PAGE_SONG), 10_000)
    }

    @Test
    fun addingASongToAPlaylistReachesTheServerAfterTheSheetCloses() {
        openAddToPlaylist()
        compose.waitUntilAtLeastOneExists(hasText(MockKoelServer.PLAYLIST_NAME), 5_000)
        compose.onAllNodesWithText(MockKoelServer.PLAYLIST_NAME).onLast().performClick()

        compose.waitUntilAtLeastOneExists(hasText("Item added to playlist."), 10_000)
        assertEquals(1, server.requestCount("/api/playlists/playlist-1/songs"))
    }

    @Test
    fun theNewPlaylistFormKeepsWhatWasTypedWhenFoldersShowUp() {
        openAddToPlaylist()
        compose.waitUntilAtLeastOneExists(hasText("New Playlist…"), 5_000)
        compose.onNodeWithText("New Playlist…").performClick()
        compose.waitUntilAtLeastOneExists(hasText("Playlist Name"), 5_000)
        compose.onNodeWithText("Playlist Name").performTextInput("Road Trip")

        server.hasPlaylistFolders = true
        runBlocking(Dispatchers.Main) { app.core.playlistFolders.fetchAll() }
        compose.waitUntilAtLeastOneExists(hasText("Folder"), 5_000)
        compose.onNodeWithText("Create").performClick()

        compose.waitUntil(10_000) { app.core.playlists.playlists.value.any { it.name == "Road Trip" } }
    }

    @Test
    fun songsLoadInTheSortSavedBeforeARestart() {
        SortSetting.remember("songs", SortSetting(PlayableSortField.CREATED_AT, SortOrder.DESC))

        openSongs()

        compose.waitUntil(5_000) { server.lastQuery("/api/songs")?.contains("sort=created_at&order=desc") == true }
    }

    @Test
    fun albumsLoadInTheSortSavedBeforeARestart() {
        SortSetting.remember("albums", SortSetting(AlbumSortField.YEAR, SortOrder.DESC))

        openLibrary("Albums")

        compose.waitUntil(10_000) { server.lastQuery("/api/albums")?.contains("sort=year&order=desc") == true }
    }

    @Test
    fun pullingAnEmptyListRefreshesIt() {
        openLibrary("Radio")
        compose.waitUntilAtLeastOneExists(hasText("No radio stations"), 10_000)
        val requestsBefore = server.requestCount(RADIO_STATIONS_PATH)

        compose.onNodeWithText("No radio stations").performTouchInput { swipeDown(startY = centerY, endY = centerY + 800f, durationMillis = 500) }

        compose.waitUntil(5_000) { server.requestCount(RADIO_STATIONS_PATH) > requestsBefore }
    }

    @Test
    fun aPlaylistThatNoLongerExistsLeavesItsScreen() {
        compose.onNodeWithText("Library").performClick()
        runBlocking(Dispatchers.Main) { app.navigator.push(Route.Playlist("deleted-playlist")) }

        compose.waitUntil(10_000) { app.navigator.stack(AppTab.Library).last() == Route.Library }
    }

    @Test
    fun aGenreSortChangeDropsThePageStillLoading() {
        server.slowsTitleSortedGenrePages = true
        openLibrary("Genres")
        compose.waitUntilAtLeastOneExists(hasText(MockKoelServer.GENRE_NAME), 10_000)
        compose.onNodeWithText(MockKoelServer.GENRE_NAME).performClick()

        compose.onNodeWithContentDescription("Sort").performClick()
        compose.onAllNodesWithText("Artist").onLast().performClick()

        compose.waitUntilAtLeastOneExists(hasText(MockKoelServer.GENRE_OTHER_SORT_SONG), 10_000)
        runCatching { compose.waitUntilAtLeastOneExists(hasText("Genre Song 001"), (MockKoelServer.SLOW_GENRE_PAGE_SECONDS + 1) * 1_000) }
        compose.onNodeWithText("Genre Song 001").assertDoesNotExist()
    }

    @Test
    fun aGenrePageThatFailsToLoadOffersRetry() {
        server.failsLaterGenrePages = true
        openGenre()
        val list = compose.onAllNodes(hasScrollToNodeAction).onLast()
        list.performScrollToNode(hasText("Genre Song %03d".format(MockKoelServer.GENRE_FIRST_PAGE_SIZE)))
        compose.waitUntilAtLeastOneExists(hasText(LoadFailure.RETRY), 10_000)

        server.failsLaterGenrePages = false
        list.performScrollToNode(hasText(LoadFailure.RETRY))
        compose.onNodeWithText(LoadFailure.RETRY).performClick()

        compose.waitUntil(10_000) { runCatching { list.performScrollToNode(hasText(MockKoelServer.GENRE_LAST_PAGE_SONG)) }.isSuccess }
    }

    @Test
    fun theCoreKnowsWhenTheAppIsOffline() {
        runBlocking(Dispatchers.Main) { app.goOffline() }
        compose.waitUntil(5_000) { app.core.isOffline }

        runBlocking(Dispatchers.Main) { app.didLogIn() }
        compose.waitUntil(5_000) { !app.core.isOffline }
    }

    @Test
    fun loggingOutDoesNotWaitForTheServer() {
        server.logsOutSlowly = true
        compose.onNodeWithContentDescription("Profile").performClick()
        compose.onNodeWithText("Log out").performClick()
        compose.onNodeWithText("Confirm").performClick()

        compose.waitUntil(MockKoelServer.SLOW_LOGOUT_SECONDS * 1_000 / 2) { app.phase.value == AppModel.Phase.Login }
    }

    @Test
    fun androidAutoReloadsItsLibraryWhenTheLoginChanges() {
        val changedFolders = Collections.synchronizedSet(mutableSetOf<String>())
        val listener = object : MediaBrowser.Listener {
            override fun onChildrenChanged(browser: MediaBrowser, parentId: String, itemCount: Int, params: MediaLibraryService.LibraryParams?) {
                changedFolders += parentId
            }
        }
        val browser = runBlocking(Dispatchers.Main) {
            MediaBrowser.Builder(context, SessionToken(context, ComponentName(context, PlaybackService::class.java)))
                .setListener(listener)
                .buildAsync()
                .await()
        }
        try {
            val rootId = runBlocking(Dispatchers.Main) {
                val rootId = browser.getLibraryRoot(null).await().value!!.mediaId
                browser.subscribe(rootId, null).await()
                rootId
            }
            // Subscribing reports the folder as changed once by itself.
            compose.waitUntil(5_000) { rootId in changedFolders }
            changedFolders.clear()

            runBlocking(Dispatchers.Main) { app.logOut().join() }

            compose.waitUntil(5_000) { rootId in changedFolders }
        } finally {
            runBlocking(Dispatchers.Main) { browser.release() }
        }
    }

    @Test
    fun theWidgetStartsPlaybackInTheForegroundService() {
        playFavorites()
        runBlocking(Dispatchers.Main) { app.core.player.pause() }
        scenario.close()
        context.stopService(Intent(context, PlaybackService::class.java))
        compose.waitUntil(10_000) { playbackServiceInfo() == null }

        runBlocking(Dispatchers.Main) { TogglePlaybackAction().onAction(context, object : GlanceId {}, actionParametersOf()) }

        compose.waitUntil(15_000) { app.core.player.state.value.isPlaying && playbackServiceInfo()?.foreground == true }
    }

    @Test
    fun theWidgetPausesFromGlancesBackgroundThread() {
        playFavorites()
        compose.waitUntil(15_000) { app.core.player.state.value.isPlaying }

        runBlocking(Dispatchers.Default) { TogglePlaybackAction().onAction(context, object : GlanceId {}, actionParametersOf()) }

        compose.waitUntil(5_000) { !app.core.player.state.value.isPlaying }
    }

    @Test
    fun theSystemControlsCannotSkipWhileTheRadioPlays() {
        val session = runBlocking(Dispatchers.Main) { PlaybackService.connect(context).await() }
        fun canSkip() = runBlocking(Dispatchers.Main) {
            session.isCommandAvailable(Player.COMMAND_SEEK_TO_NEXT) || session.isCommandAvailable(Player.COMMAND_SEEK_TO_PREVIOUS)
        }
        try {
            playFavorites()
            compose.waitUntil(10_000) { canSkip() }

            runBlocking(Dispatchers.Main) { app.core.player.playRadio(RadioStation("station-1", "Test Radio", "")) }
            compose.waitUntil(10_000) { !canSkip() }

            runBlocking(Dispatchers.Main) { app.core.player.stopRadio() }
            compose.waitUntil(10_000) { canSkip() }
        } finally {
            runBlocking(Dispatchers.Main) { session.release() }
        }
    }

    @Suppress("DEPRECATION")
    private fun playbackServiceInfo(): ActivityManager.RunningServiceInfo? =
        context.getSystemService(ActivityManager::class.java).getRunningServices(Int.MAX_VALUE)
            .firstOrNull { it.service.className == PlaybackService::class.java.name }

    private val context: Context get() = InstrumentationRegistry.getInstrumentation().targetContext

    private fun playFavorites() {
        runBlocking(Dispatchers.Main) { app.actions.play(app.core.favorites.fetch()) }
        compose.waitUntil(15_000) { app.core.player.state.value.current != null }
    }

    private fun tapSongRow(title: String) {
        compose.onAllNodes(hasScrollToNodeAction).onLast().performScrollToNode(hasText(title))
        compose.onAllNodes(hasText(title) and hasClickAction()).onLast().performClick()
    }

    private fun assertTappedSongJoinedTheQueue(title: String) {
        compose.waitUntil(10_000) { app.core.player.state.value.current?.title == title }
        assertEquals(MockKoelServer.FAVORITE_COUNT + 1, app.core.player.state.value.queue.size)
    }

    private fun revealLeadingSwipe(row: SemanticsNodeInteraction) {
        row.performTouchInput { swipeRight(startX = left + 10f, endX = left + width * 0.3f) }
        compose.waitForIdle()
    }

    private fun openAlbum() {
        compose.onNodeWithText("Library").performClick()
        compose.waitUntilAtLeastOneExists(hasText("Recently added"), 10_000)
        compose.onAllNodes(hasScrollToNodeAction).onLast().performScrollToNode(hasText(MockKoelServer.ALBUM_NAME))
        compose.onNodeWithText(MockKoelServer.ALBUM_NAME).performClick()
        compose.waitUntilAtLeastOneExists(hasText(MockKoelServer.SONG_TITLES[0]), 10_000)
    }

    private fun openGenre() {
        openLibrary("Genres")
        compose.waitUntilAtLeastOneExists(hasText(MockKoelServer.GENRE_NAME), 10_000)
        compose.onNodeWithText(MockKoelServer.GENRE_NAME).performClick()
        compose.waitUntilAtLeastOneExists(hasText("Genre Song 001"), 10_000)
    }

    private fun openRecentlyPlayed() {
        compose.onNodeWithContentDescription("Recently Played").performClick()
        compose.waitUntilAtLeastOneExists(hasText("Recently Played"), 10_000)
    }

    /** Gives a second request time to arrive before checking there was only the first. */
    private fun assertRequestedOnce(path: String) {
        runCatching { compose.waitUntil(2_000) { server.requestCount(path) > 1 } }
        assertEquals(1, server.requestCount(path))
    }

    private fun goBack() {
        InstrumentationRegistry.getInstrumentation().sendKeyDownUpSync(KeyEvent.KEYCODE_BACK)
        compose.waitForIdle()
    }

    private fun tuneTheFirstBand(decibels: Float) {
        compose.onNodeWithContentDescription("60 Hz").performSemanticsAction(SemanticsActions.SetProgress) { it(decibels) }
        compose.waitUntil(5_000) { app.core.playbackSettings.equalizer.value.gains.first() == decibels.toDouble() }
    }

    private val app get() = (InstrumentationRegistry.getInstrumentation().targetContext.applicationContext as KoelApplication).app

    private fun hasClickLabel(label: String) = SemanticsMatcher("click label is $label") {
        it.config.getOrNull(SemanticsActions.OnClick)?.label == label
    }

    private val hasScrollToNodeAction = SemanticsMatcher.keyIsDefined(SemanticsActions.ScrollToIndex) and
        SemanticsMatcher.keyIsDefined(SemanticsProperties.VerticalScrollAxisRange)

    /** Starts the app already logged in to the mock server, skipping the login form. */
    private fun startLoggedIn() {
        runBlocking(Dispatchers.Main) {
            app.core.auth.startSession(server.host, MockKoelServer.TOKEN, MockKoelServer.TOKEN)
            app.core.auth.fetchCurrentUser()
            app.didLogIn()
        }
        scenario = ActivityScenario.launch(MainActivity::class.java)
        compose.waitUntilAtLeastOneExists(hasContentDescription("Recently Played"), 30_000)
    }

    /** The labels of the actions in the topmost menu or sheet, in order, passing over windows without actions such as tooltips. */
    private fun shownMenuLabels(): List<String> {
        fun labels(node: SemanticsNode): List<String> {
            val text = node.config.getOrNull(SemanticsProperties.Text)?.joinToString(" ") { it.text }
            val own = if (text != null && node.config.contains(SemanticsActions.OnClick)) listOf(text) else emptyList()
            return own + node.children.flatMap(::labels)
        }
        return compose.onAllNodes(isRoot()).fetchSemanticsNodes().reversed().map(::labels).first { it.isNotEmpty() }
    }

    private fun longPressMenuLabels(title: String): List<String> {
        val rootsBefore = compose.onAllNodes(isRoot()).fetchSemanticsNodes().size
        compose.onAllNodesWithText(title).onFirst().performTouchInput { longClick() }
        compose.waitUntil(5_000) { compose.onAllNodes(isRoot()).fetchSemanticsNodes().size > rootsBefore }
        compose.waitForIdle()
        val labels = shownMenuLabels()
        InstrumentationRegistry.getInstrumentation().sendKeyDownUpSync(KeyEvent.KEYCODE_BACK)
        compose.waitUntil(5_000) { compose.onAllNodes(isRoot()).fetchSemanticsNodes().size == rootsBefore }
        return labels
    }

    private fun overflowMenuLabels(): List<String> {
        openOverflowMenu()
        return shownMenuLabels()
    }

    private fun openOverflowMenu() {
        val rootsBefore = compose.onAllNodes(isRoot()).fetchSemanticsNodes().size
        compose.onNode(hasContentDescription("More") and hasClickAction() and !hasAnyAncestor(hasScrollToNodeAction)).performClick()
        compose.waitUntil(5_000) { compose.onAllNodes(isRoot()).fetchSemanticsNodes().size > rootsBefore }
        compose.waitForIdle()
    }

    private fun openPlaybackSettingsFromProfile() {
        compose.onNodeWithContentDescription("Profile").performClick()
        compose.waitUntilAtLeastOneExists(hasText("Playback settings"), 5_000)
        compose.onNodeWithText("Playback settings").performClick()
        compose.waitUntilAtLeastOneExists(hasText("Equalizer"), 5_000)
    }

    private fun openLibrary(destination: String) {
        compose.onNodeWithText("Library").performClick()
        compose.waitUntilAtLeastOneExists(hasText(destination), 5_000)
        compose.onNodeWithText(destination).performClick()
    }

    private fun queuedRow(title: String) = hasText(title) and hasContentDescription("Reorder")

    private fun openQueue() {
        openSongs()
        compose.onNodeWithText("Play").performClick()
        compose.waitUntilAtLeastOneExists(hasContentDescription("Pause"), 20_000)
        compose.onAllNodesWithContentDescription("Pause").onFirst().performClick()

        compose.onNode(hasClickLabel("Open Now Playing")).performClick()
        compose.waitUntilAtLeastOneExists(hasText("Queued"), 10_000)
    }

    private fun openAddToPlaylist() {
        openSongs()
        compose.onAllNodesWithText(MockKoelServer.SONG_TITLES[1])[0].performTouchInput { longClick() }
        compose.waitUntilAtLeastOneExists(hasText("Add to a Playlist…"), 5_000)
        compose.onNodeWithText("Add to a Playlist…").performClick()
    }

    private fun openSongs() {
        compose.onNodeWithText("Library").performClick()
        compose.waitUntilAtLeastOneExists(hasText("Songs"), 5_000)
        compose.onNodeWithText("Songs").performClick()
        compose.waitUntilAtLeastOneExists(hasText(MockKoelServer.SONG_TITLES[1]), 15_000)
    }

    private companion object {
        const val RECENTLY_PLAYED_PATH = "/api/songs/recently-played"
        const val FAVORITES_PATH = "/api/songs/favorite"
        const val RADIO_STATIONS_PATH = "/api/radio/stations"
    }
}
