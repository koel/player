package phanan.koel.app

import org.junit.Assert.assertEquals
import org.junit.Assert.assertFalse
import org.junit.Assert.assertNull
import org.junit.Assert.assertTrue
import org.junit.Test
import phanan.koel.app.ui.collections.SongIndex
import phanan.koel.app.ui.components.SortSetting
import phanan.koel.app.ui.home.HomeBlock
import phanan.koel.app.ui.library.LibraryDestination
import phanan.koel.app.ui.library.PodcastSortOption
import phanan.koel.app.ui.library.SectionIndex
import phanan.koel.app.ui.library.isWebUrl
import phanan.koel.app.ui.library.letterIndex
import phanan.koel.app.ui.library.podcastAddFailureMessage
import phanan.koel.app.ui.main.Route
import phanan.koel.app.ui.search.SearchSection
import phanan.koel.shared.models.Album
import phanan.koel.shared.models.Artist
import phanan.koel.shared.models.PlayableSortField
import phanan.koel.shared.models.Podcast
import phanan.koel.shared.models.PodcastSortField
import phanan.koel.shared.models.RadioStation
import phanan.koel.shared.models.Song
import phanan.koel.shared.models.SortOrder
import phanan.koel.shared.models.sorted
import phanan.koel.shared.session.Feature
import phanan.koel.shared.stores.SearchResult

class SectionIndexTest {
    @Test
    fun collectionSongsGetTheIndexOnlyWhenLongAndSortedByTitle() {
        val songs = List(SectionIndex.MINIMUM_ITEM_COUNT) { Song(id = "$it", title = "Song $it") }

        assertEquals(2, SongIndex.ifSortedByTitle(songs, SortSetting(PlayableSortField.TITLE, SortOrder.ASC))?.firstRow)
        assertNull(SongIndex.ifSortedByTitle(songs, SortSetting(PlayableSortField.ARTIST_NAME, SortOrder.ASC)))
        assertNull(SongIndex.ifSortedByTitle(songs.drop(1), SortSetting(PlayableSortField.TITLE, SortOrder.ASC)))
    }

    @Test
    fun showsOnlyForLongNameSortedLists() {
        assertTrue(SectionIndex.isShown(100, isSortedByName = true))
        assertFalse(SectionIndex.isShown(99, isSortedByName = true))
        assertFalse(SectionIndex.isShown(500, isSortedByName = false))
    }

    @Test
    fun latinLettersGetTheirOwnSectionAndTheRestShareHash() {
        assertEquals("A", SectionIndex.letter("abba"))
        assertEquals("#", SectionIndex.letter("2Pac"))
        assertEquals("#", SectionIndex.letter("Édith Piaf"))
        assertEquals("#", SectionIndex.letter(""))
    }

    @Test
    fun sectionsKeepTheListOrder() {
        val sections = SectionIndex.sections(listOf("Beta", "alpha", "Bravo", "1999", "Apple")) { it }

        assertEquals(listOf("B", "A", "#"), sections.map { it.letter })
        assertEquals(listOf("alpha", "Apple"), sections[1].items)
    }

    @Test
    fun jumpsToEachLettersFirstItem() {
        assertEquals(mapOf("A" to 0, "B" to 2, "#" to 3), SectionIndex.firstPositions(listOf("Abba", "Accept", "Blur", "50 Cent")) { it })
    }

    @Test
    fun fingerPositionPicksALetterAndHoldsAtTheEnds() {
        assertEquals(0, letterIndex(-20f, 15f, 5))
        assertEquals(2, letterIndex(31f, 15f, 5))
        assertEquals(4, letterIndex(500f, 15f, 5))
        assertNull(letterIndex(10f, 15f, 0))
    }
}

class LibraryFormsTest {
    @Test
    fun acceptsOnlyWebAddresses() {
        assertTrue("https://example.com/feed.xml".isWebUrl)
        assertTrue(" http://radio.example.com:8000/stream ".isWebUrl)
        assertFalse("example.com/feed".isWebUrl)
        assertFalse("ftp://example.com".isWebUrl)
        assertFalse("https://".isWebUrl)
        assertFalse("not a url".isWebUrl)
    }

    @Test
    fun explainsAnAlreadySubscribedPodcast() {
        assertEquals("You are already subscribed to this podcast.", podcastAddFailureMessage(409))
        assertEquals("Something wrong happened. Please try again.", podcastAddFailureMessage(500))
        assertEquals("Something wrong happened. Please try again.", podcastAddFailureMessage(null))
    }
}

class PodcastSortTest {
    private val podcasts = listOf(
        Podcast(id = "1", title = "Zebra", author = "Ann", lastPlayedAt = "2024-01-01", subscribedAt = "2023-05-01"),
        Podcast(id = "2", title = "Apple", author = "Cid", lastPlayedAt = "2024-06-01", subscribedAt = "2022-01-01"),
    )

    @Test
    fun lastPlayedComesFirstByDefault() {
        assertEquals(PodcastSortOption.LastPlayed, PodcastSortOption.entries.first())
        assertEquals(listOf("2", "1"), podcasts.sorted(PodcastSortOption.LastPlayed.field, SortOrder.DESC).map { it.id })
    }

    @Test
    fun unknownSavedOptionsFallBackToLastPlayed() {
        assertEquals(PodcastSortOption.Title, PodcastSortOption.named("Title"))
        assertEquals(PodcastSortOption.LastPlayed, PodcastSortOption.named("Popularity"))
        assertEquals(PodcastSortField.AUTHOR, PodcastSortOption.Author.field)
    }
}

class LibraryDestinationTest {
    @Test
    fun hidesWhatTheServerCantDo() {
        val destinations = LibraryDestination.visible(supportsPodcasts = false, supportsRadio = false, isOffline = false)

        assertFalse(LibraryDestination.Podcasts in destinations)
        assertFalse(LibraryDestination.Radio in destinations)
        assertEquals(LibraryDestination.Songs, destinations.first())
    }

    @Test
    fun radioOpensTheStations() {
        assertTrue(LibraryDestination.Radio in LibraryDestination.visible(supportsPodcasts = true, supportsRadio = true, isOffline = false))
        assertEquals(Route.RadioStations, LibraryDestination.Radio.route)
    }

    @Test
    fun offlineOnlyDownloadsRemain() {
        assertEquals(
            listOf(LibraryDestination.Downloads),
            LibraryDestination.visible(supportsPodcasts = true, supportsRadio = true, isOffline = true),
        )
    }
}

class HomeShelfTest {
    @Test
    fun shelvesOpenTheirFullList() {
        assertEquals(Route.Albums, HomeBlock.RecentlyAddedAlbums.seeAll)
        assertEquals(Route.Artists, HomeBlock.RandomArtists.seeAll)
        assertEquals(Route.Songs, HomeBlock.LeastPlayedSongs.seeAll)
    }
}

class SearchSectionTest {
    private val result = SearchResult(
        albums = listOf(Album(id = "1", name = "Album")),
        artists = listOf(Artist(id = "2", name = "Artist")),
        podcasts = listOf(Podcast(id = "3", title = "Podcast")),
        radioStations = listOf(RadioStation(id = "4", name = "Station", url = "https://radio.test")),
    )

    @Test
    fun showsSectionsWithResultsInFlutterOrder() {
        assertEquals(
            listOf(SearchSection.Albums, SearchSection.Artists, SearchSection.Podcasts, SearchSection.RadioStations),
            SearchSection.visible(result) { true },
        )
    }

    @Test
    fun leavesOutPodcastsAndRadioTheServerLacks() {
        assertEquals(listOf(SearchSection.Albums, SearchSection.Artists), SearchSection.visible(result) { it == Feature.FAVORITE_ENTITIES })
    }
}

class ServerSortTest {
    private val byTitle = SortSetting(PlayableSortField.TITLE, SortOrder.ASC)
    private val newestFirst = SortSetting(PlayableSortField.CREATED_AT, SortOrder.DESC)

    @Test
    fun aListLoadedInAnotherSortFetchesItsFirstPageInTheSavedOne() {
        assertTrue(newestFirst.needsFirstPage(loaded = byTitle, isEmpty = false, forceRefresh = false))
    }

    @Test
    fun aListAlreadyInTheSavedSortIsKept() {
        assertFalse(byTitle.needsFirstPage(loaded = byTitle, isEmpty = false, forceRefresh = false))
    }

    @Test
    fun anEmptyListOrARefreshFetchesTheFirstPage() {
        assertTrue(byTitle.needsFirstPage(loaded = byTitle, isEmpty = true, forceRefresh = false))
        assertTrue(byTitle.needsFirstPage(loaded = byTitle, isEmpty = false, forceRefresh = true))
    }
}
