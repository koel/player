@testable import KoelPlayer
@preconcurrency import Shared
import Testing

struct SearchSectionTests {
    private let result = SearchResult(
        playables: [],
        artists: [Artist(id: "ar1", name: "Artist")],
        albums: [
            Album(
                id: "al1", name: "Album", cover: nil, artistId: "ar1", artistName: "Artist",
                year: nil, favorite: false, permissions: Permissions(edit: false, delete: false)
            ),
        ],
        podcasts: [
            Podcast(
                id: "p1", title: "Podcast", url: "", link: "", description: "", author: "", imageUrl: "",
                subscribedAt: "", lastPlayedAt: "", state: PodcastState(currentEpisodeId: nil, progresses: [:]), favorite: false
            ),
        ],
        radioStations: [RadioStation(id: "r1", name: "Station", url: "https://radio.test")]
    )

    @Test func listsOnlySectionsWithResultsInFlutterOrder() {
        let sections = SearchSection.visible(in: result) { _ in true }

        #expect(sections == [.albums, .artists, .podcasts, .radioStations])
    }

    @Test func hidesFeaturesTheServerDoesNotSupport() {
        let sections = SearchSection.visible(in: result) { feature in feature == .podcasts }

        #expect(sections == [.albums, .artists, .podcasts])
    }

    @Test func showsNothingForAnEmptyResult() {
        #expect(SearchSection.visible(in: SearchResult()) { _ in true }.isEmpty)
    }
}
