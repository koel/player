@testable import KoelPlayer
import Testing

struct HomeBlockTests {
    @Test func keepsTheDefaultOrderWithoutAPreference() {
        #expect(HomeBlock.ordered(by: []) == HomeBlock.allCases)
    }

    @Test func putsSavedBlocksFirstAndKeepsTheRestInDefaultOrder() {
        let ordered = HomeBlock.ordered(by: ["random-artists", "most-played-songs"])

        #expect(Array(ordered.prefix(4)) == [.randomArtists, .mostPlayedSongs, .recentlyAddedAlbums, .similarSongs])
        #expect(ordered.count == HomeBlock.allCases.count)
    }

    @Test func sectionsOpenTheirFullList() {
        #expect(HomeBlock.recentlyAddedAlbums.seeAll == .albums)
        #expect(HomeBlock.randomArtists.seeAll == .artists)
        #expect(HomeBlock.leastPlayedSongs.seeAll == .songs)
    }

    @Test func ignoresUnknownIds() {
        let ordered = HomeBlock.ordered(by: ["recently-played-songs", "random-songs"])

        #expect(Array(ordered.prefix(2)) == [.randomSongs, .recentlyAddedAlbums])
    }
}
