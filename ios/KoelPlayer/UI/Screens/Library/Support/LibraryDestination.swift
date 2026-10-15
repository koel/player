import Foundation

/// The rows at the top of the Library tab, in Flutter's order.
enum LibraryDestination: CaseIterable, Identifiable {
    case songs
    case favorites
    case playlists
    case artists
    case albums
    case genres
    case podcasts
    case radioStations
    case downloads

    var id: Self { self }

    static func visible(supportsPodcasts: Bool, supportsRadioStations: Bool) -> [LibraryDestination] {
        allCases.filter { destination in
            switch destination {
            case .podcasts: supportsPodcasts
            case .radioStations: supportsRadioStations
            default: true
            }
        }
    }

    var title: String {
        switch self {
        case .songs: "Songs"
        case .favorites: "Favorites"
        case .playlists: "Playlists"
        case .artists: "Artists"
        case .albums: "Albums"
        case .genres: "Genres"
        case .podcasts: "Podcasts"
        case .radioStations: "Radio"
        case .downloads: "Downloaded"
        }
    }

    var systemImage: String {
        switch self {
        case .songs: "music.note"
        case .favorites: "star"
        case .playlists: "music.note.list"
        case .artists: "music.microphone"
        case .albums: "square.stack"
        case .genres: "guitars"
        case .podcasts: "mic"
        case .radioStations: "antenna.radiowaves.left.and.right"
        case .downloads: "arrow.down.circle"
        }
    }

    var route: Route {
        switch self {
        case .songs: .songs
        case .favorites: .favorites
        case .playlists: .playlists
        case .artists: .artists
        case .albums: .albums
        case .genres: .genres
        case .podcasts: .podcasts
        case .radioStations: .radioStations
        case .downloads: .downloads
        }
    }
}
