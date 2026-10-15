@preconcurrency import Shared

/// Sheets that any screen can open, presented once at the root of the main UI.
enum AppSheet: Identifiable {
    case addToPlaylist([any Playable])
    case details(any Playable)

    var id: String {
        switch self {
        case .addToPlaylist(let playables): "add-to-playlist:" + playables.map(\.id).joined(separator: ",")
        case .details(let playable): "details:\(playable.id)"
        }
    }
}
