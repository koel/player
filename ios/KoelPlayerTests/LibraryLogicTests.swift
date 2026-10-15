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

    @Test func settingsAreRememberedPerList() {
        let fallback = SortSetting(field: "title", order: .asc)
        let key = "test.\(UUID().uuidString)"

        #expect(SortSetting.remembered(for: key, default: fallback) == fallback)

        SortSetting(field: "created_at", order: .desc).remember(for: key)

        #expect(SortSetting.remembered(for: key, default: fallback) == SortSetting(field: "created_at", order: .desc))
    }
}

struct LibraryDestinationTests {
    @Test func hidesPodcastsAndRadioOnOlderServers() {
        let destinations = LibraryDestination.visible(supportsPodcasts: false, supportsRadioStations: false)

        #expect(!destinations.contains(.podcasts))
        #expect(!destinations.contains(.radioStations))
        #expect(destinations.first == .songs)
        #expect(destinations.last == .downloads)
    }

    @Test func showsEverythingOnNewServers() {
        #expect(LibraryDestination.visible(supportsPodcasts: true, supportsRadioStations: true) == LibraryDestination.allCases)
    }
}

struct GridLayoutTests {
    @Test func phoneWidthFitsTwoColumns() {
        let layout = GridLayout(containerWidth: 393)

        #expect(layout.columnCount == 2)
        #expect(layout.cardSize == 172.5)
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
        let detail = CollectionSummary.detail(year: 2019, songCount: 2, totalLength: 3600)

        #expect(detail == "2019 · 2 songs · \(3600.0.totalLength)")
    }

    @Test func showsOnlyTheYearWithoutSongs() {
        #expect(CollectionSummary.detail(year: 2019, songCount: 0, totalLength: 0) == "2019")
        #expect(CollectionSummary.detail(year: nil, songCount: 0, totalLength: 0) == nil)
    }
}
