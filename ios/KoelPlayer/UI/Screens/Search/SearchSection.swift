@preconcurrency import Shared

/// The groups a search result is shown in, in Flutter's order.
enum SearchSection: CaseIterable {
    case songs
    case albums
    case artists
    case podcasts
    case radioStations

    var title: String {
        switch self {
        case .songs: "Songs"
        case .albums: "Albums"
        case .artists: "Artists"
        case .podcasts: "Podcasts"
        case .radioStations: "Radio Stations"
        }
    }

    /// The sections with results, leaving out features the server doesn't support.
    static func visible(in result: SearchResult, supports: (Feature) -> Bool) -> [SearchSection] {
        allCases.filter { section in
            switch section {
            case .songs: !result.playables.isEmpty
            case .albums: !result.albums.isEmpty
            case .artists: !result.artists.isEmpty
            case .podcasts: supports(.podcasts) && !result.podcasts.isEmpty
            case .radioStations: supports(.radioStations) && !result.radioStations.isEmpty
            }
        }
    }
}
