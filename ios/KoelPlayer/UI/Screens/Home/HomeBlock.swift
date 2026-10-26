/// The carousels on Home, in koel web's default order. Raw values are the ids the server stores in
/// the user's `home_blocks_order` preference.
enum HomeBlock: String, CaseIterable {
    case recentlyAddedAlbums = "recently-added-albums"
    case similarSongs = "similar-songs"
    case mostPlayedAlbums = "most-played-albums"
    case mostPlayedSongs = "most-played-songs"
    case mostPlayedArtists = "most-played-artists"
    case recentlyAddedSongs = "recently-added-songs"
    case recentlyAddedArtists = "recently-added-artists"
    case leastPlayedSongs = "least-played-songs"
    case randomSongs = "random-songs"
    case randomAlbums = "random-albums"
    case randomArtists = "random-artists"

    var title: String {
        switch self {
        case .recentlyAddedAlbums: "Latest Albums"
        case .similarSongs: "You Might Also Like"
        case .mostPlayedAlbums: "Top Albums"
        case .mostPlayedSongs: "Most Played"
        case .mostPlayedArtists: "Top Artists"
        case .recentlyAddedSongs: "New Songs"
        case .recentlyAddedArtists: "New Artists"
        case .leastPlayedSongs: "Hidden Gems"
        case .randomSongs: "Random Songs"
        case .randomAlbums: "Random Albums"
        case .randomArtists: "Random Artists"
        }
    }

    /// The full list a section's header opens.
    var seeAll: Route {
        switch self {
        case .recentlyAddedAlbums, .mostPlayedAlbums, .randomAlbums: .albums
        case .mostPlayedArtists, .recentlyAddedArtists, .randomArtists: .artists
        default: .songs
        }
    }

    /// Blocks named in `savedOrder` come first, in that order; the rest keep their default order.
    static func ordered(by savedOrder: [String]) -> [HomeBlock] {
        func rank(_ block: HomeBlock, defaultIndex: Int) -> Int {
            savedOrder.firstIndex(of: block.rawValue) ?? savedOrder.count + defaultIndex
        }

        return allCases.enumerated()
            .sorted { rank($0.element, defaultIndex: $0.offset) < rank($1.element, defaultIndex: $1.offset) }
            .map(\.element)
    }
}
