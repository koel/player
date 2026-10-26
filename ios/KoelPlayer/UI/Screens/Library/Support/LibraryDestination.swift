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
    case radio
    case downloads

    var id: Self { self }

    static func visible(supportsPodcasts: Bool, supportsRadio: Bool) -> [LibraryDestination] {
        allCases.filter { ($0 != .podcasts || supportsPodcasts) && ($0 != .radio || supportsRadio) }
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
        case .radio: "Radio"
        case .downloads: "Downloaded"
        }
    }

    var systemImage: String {
        switch self {
        case .songs: "music.note"
        case .favorites: "heart"
        case .playlists: "music.note.list"
        case .artists: "music.microphone"
        case .albums: "square.stack"
        case .genres: "guitars"
        case .podcasts: "mic"
        case .radio: "dot.radiowaves.left.and.right"
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
        case .radio: .radioStations
        case .downloads: .downloads
        }
    }
}
