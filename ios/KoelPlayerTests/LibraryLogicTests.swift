import Foundation
@testable import KoelPlayer
@preconcurrency import Shared
import Testing

struct SectionIndexTests {
    @Test func lettersFoldNonLatinNamesIntoHash() {
        #expect(SectionIndex.letter(for: "abba") == "A")
        #expect(SectionIndex.letter(for: "Zedd") == "Z")
        #expect(SectionIndex.letter(for: "2Pac") == "#")
        #expect(SectionIndex.letter(for: "Ólafur") == "#")
        #expect(SectionIndex.letter(for: "") == "#")
    }

    @Test func sectionsKeepTheListOrder() {
        let sections = SectionIndex.sections(["Zoe", "Zara", "Bob", "!!!", "Ben"], name: { $0 })

        #expect(sections.map(\.letter) == ["Z", "B", "#"])
        #expect(sections.map(\.items) == [["Zoe", "Zara"], ["Bob", "Ben"], ["!!!"]])
    }

    @Test func indexShowsOnlyForLongNameSortedLists() {
        #expect(SectionIndex.isShown(itemCount: 100, isSortedByName: true))
        #expect(!SectionIndex.isShown(itemCount: 99, isSortedByName: true))
        #expect(!SectionIndex.isShown(itemCount: 500, isSortedByName: false))
    }
}

struct SortOptionsTests {
    @Test func favoritesOfferCustomOrderOnlyWhenSupported() {
        #expect(SortOptions.favorites(supportsCustomOrder: true).map(\.field) == ["position", "title", "artist_name", "created_at"])
        #expect(SortOptions.favorites(supportsCustomOrder: false).map(\.field) == ["title", "artist_name", "created_at"])
    }

    @Test func everySortedListOffersNamedFields() {
        let fields = PlayableSortField.shared

        #expect(SortOptions.podcastEpisodes.map(\.field) == [fields.TITLE, fields.CREATED_AT])
        #expect(SortOptions.podcasts.map(\.field) == PodcastSortOption.allCases.map(\.rawValue))
        #expect(SortOptions.songs.map(\.field) == [fields.TITLE, fields.ARTIST_NAME, fields.CREATED_AT])
    }

    @Test func settingsAreRememberedPerList() {
        let fallback = SortSetting(field: "title", order: .asc)
        let key = "test.\(UUID().uuidString)"

        #expect(SortSetting.remembered(for: key, default: fallback) == fallback)

        SortSetting(field: "created_at", order: .desc).remember(for: key)

        #expect(SortSetting.remembered(for: key, default: fallback) == SortSetting(field: "created_at", order: .desc))
    }

    @Test func settingsSurviveARestart() throws {
        let suite = "test.\(UUID().uuidString)"
        let original = SortSetting.defaults
        defer { SortSetting.defaults = original; UserDefaults().removePersistentDomain(forName: suite) }
        SortSetting.defaults = try #require(UserDefaults(suiteName: suite))
        SortSetting(field: "created_at", order: .desc).remember(for: "songs")

        SortSetting.defaults = try #require(UserDefaults(suiteName: suite))

        #expect(SortSetting.remembered(for: "songs", default: SortSetting(field: "title", order: .asc)) == SortSetting(field: "created_at", order: .desc))
    }

    @Test func layoutsStartAsAGridAndSurviveARestart() throws {
        let suite = "test.\(UUID().uuidString)"
        let original = SortSetting.defaults
        defer { SortSetting.defaults = original; UserDefaults().removePersistentDomain(forName: suite) }
        SortSetting.defaults = try #require(UserDefaults(suiteName: suite))

        #expect(CollectionLayout.remembered(for: "albums") == .grid)
        CollectionLayout.list.remember(for: "albums")

        SortSetting.defaults = try #require(UserDefaults(suiteName: suite))

        #expect(CollectionLayout.remembered(for: "albums") == .list)
        #expect(CollectionLayout.remembered(for: "artists") == .grid)
    }
}

struct LibraryDestinationTests {
    @Test func hidesWhatTheServerCantDo() {
        let destinations = LibraryDestination.visible(supportsPodcasts: false, supportsRadio: false)

        #expect(!destinations.contains(.podcasts))
        #expect(!destinations.contains(.radio))
        #expect(destinations.first == .songs)
        #expect(destinations.last == .downloads)
    }

    @Test func showsEverythingOnNewServers() {
        #expect(LibraryDestination.visible(supportsPodcasts: true, supportsRadio: true) == LibraryDestination.allCases)
    }

    @Test func radioOpensTheStations() {
        #expect(LibraryDestination.radio.route == .radioStations)
    }
}

struct GridLayoutTests {
    @Test func phoneWidthFitsTwoColumns() {
        let layout = GridLayout(containerWidth: 393)

        #expect(layout.columnCount == 2)
        #expect(layout.cardSize == 172.5)
        #expect(layout.rowSpacing == 20)
    }

    @Test func widerScreensFitMoreColumns() {
        #expect(GridLayout(containerWidth: 1024).columnCount == 6)
    }

    @Test func neverFewerThanTwoColumns() {
        #expect(GridLayout(containerWidth: 200).columnCount == 2)
    }
}

struct YearInputTests {
    @Test func keepsAtMostFourDigits() {
        #expect(YearInput.sanitized("19a99x5") == "1999")
        #expect(YearInput.value("2024") == 2024)
        #expect(YearInput.value("") == nil)
    }
}

struct CollectionSummaryTests {
    @Test func joinsYearSongCountAndLength() {
        let detail = CollectionSummary.detail(label: "2019", songCount: 2, totalLength: 3600)

        #expect(detail == "2019 · 2 songs · \(3600.0.totalLength)")
    }

    @Test func showsOnlyTheLabelWithoutSongs() {
        #expect(CollectionSummary.detail(label: "2019", songCount: 0, totalLength: 0) == "2019")
        #expect(CollectionSummary.detail(label: nil, songCount: 0, totalLength: 0) == nil)
    }

    @Test func playlistsUseTheSameSeparatorAsAlbums() {
        let detail = CollectionSummary.detail(label: "Smart playlist", songCount: 3, totalLength: 600)

        #expect(detail == "Smart playlist · 3 songs · \(600.0.totalLength)")
    }
}

@MainActor
struct LoadStateTests {
    private struct Failure: Error {}

    @Test func isPendingUntilTheFirstFetchSucceeds() async {
        let state = LoadState()
        #expect(state.isPending)

        await state.load {}

        #expect(state.hasLoaded)
        #expect(!state.isPending)
        #expect(!state.hasFailed)
    }

    @Test func aFailedLoadShowsTheFailureUntilARetrySucceeds() async {
        let state = LoadState()

        await state.load { throw Failure() }
        #expect(state.hasFailed)
        #expect(!state.isPending)

        await state.load {}
        #expect(!state.hasFailed)
        #expect(state.hasLoaded)
    }

    @Test func aCancelledLoadIsNotAFailure() async {
        let state = LoadState()

        await state.load { throw CancellationError() }

        #expect(!state.hasFailed)
    }

    @Test func aLoadStartedWhileAnotherRunsIsSkipped() async {
        let state = LoadState()
        let (gate, opener) = AsyncStream<Void>.makeStream()
        let first = Task { await state.load { for await _ in gate { break } } }
        while !state.isLoading { await Task.yield() }

        var secondFetchRan = false
        await state.load { secondFetchRan = true }
        opener.yield()
        await first.value

        #expect(!secondFetchRan)
    }

    @Test func aPageFetchedBeforeARefreshIsDropped() async {
        let state = LoadState()
        let (gate, opener) = AsyncStream<Void>.makeStream()
        var shown: [String] = []
        let page = Task {
            await state.load {
                for await _ in gate { break }
                return "old page 2"
            } apply: { shown.append($0) }
        }
        while !state.isLoading { await Task.yield() }

        await state.refresh(hasItems: true) { "new page 1" } apply: { shown = [$0] }
        opener.yield()
        await page.value

        #expect(shown == ["new page 1"])
    }

    @Test func aPageAskedForDuringARefreshIsSkipped() async {
        let state = LoadState()
        let (gate, opener) = AsyncStream<Void>.makeStream()
        let refresh = Task { await state.refresh(hasItems: true) { for await _ in gate { break } } }
        await Task.yield()

        var pageFetched = false
        await state.load { pageFetched = true }
        opener.yield()
        await refresh.value

        #expect(!pageFetched)
    }

    @Test func onlyTheLatestRefreshIsApplied() async {
        let state = LoadState()
        let (gate, opener) = AsyncStream<Void>.makeStream()
        var shown = ""
        let older = Task {
            await state.refresh(hasItems: true) {
                for await _ in gate { break }
                return "old sort"
            } apply: { shown = $0 }
        }
        await Task.yield()

        await state.refresh(hasItems: true) { "new sort" } apply: { shown = $0 }
        opener.yield()
        await older.value

        #expect(shown == "new sort")
    }

    @Test func aFailedRefreshKeepsLoadedItemsOnScreen() async {
        let state = LoadState()
        await state.load {}

        await state.refresh(hasItems: true) { throw Failure() }
        #expect(!state.hasFailed)

        await state.refresh(hasItems: false) { throw Failure() }
        #expect(state.hasFailed)
    }

    @Test func aFailedPageOffersARetryUntilTheNextSuccess() async {
        let state = LoadState()
        await state.load {}
        #expect(state.nextPage(hasMore: true, loadedCount: 20) == .loadable)

        await state.load { throw Failure() }
        #expect(state.nextPage(hasMore: true, loadedCount: 20) == .failed)

        await state.load {}
        #expect(state.nextPage(hasMore: true, loadedCount: 20) == .loadable)
        #expect(state.nextPage(hasMore: false, loadedCount: 20) == .none)
        #expect(state.nextPage(hasMore: true, loadedCount: 0) == .none)
    }
}
