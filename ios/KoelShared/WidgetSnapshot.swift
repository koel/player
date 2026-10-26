import Foundation

/// What the app last told its widgets, kept in the App Group container they share.
nonisolated struct WidgetSnapshot: Codable, Equatable, Sendable {
    struct NowPlaying: Codable, Equatable, Sendable {
        var title: String
        var subtitle: String
        var isPlaying: Bool
        var isRadio: Bool
        var artworkFile: String?
    }

    struct RecentItem: Codable, Equatable, Identifiable, Sendable {
        var id: String
        var title: String
        var subtitle: String
        var artworkFile: String?
    }

    var nowPlaying: NowPlaying?
    var recentlyPlayed: [RecentItem] = []

    static let empty = WidgetSnapshot()
}

nonisolated enum WidgetKind {
    static let nowPlaying = "NowPlaying"
    static let recentlyPlayed = "RecentlyPlayed"
    static let playPauseControl = "dev.koel.PlayPause"
}

/// Links from a widget into the app.
nonisolated enum WidgetLink: Equatable {
    private static let scheme = "koelplayer"

    case nowPlaying
    case playRecent(id: String)

    var url: URL {
        switch self {
        case .nowPlaying: URL(string: "\(Self.scheme)://now-playing")!
        case .playRecent(let id): URL(string: "\(Self.scheme)://recent/\(id)")!
        }
    }

    init?(url: URL) {
        guard url.scheme == Self.scheme else { return nil }
        switch url.host() {
        case "now-playing":
            self = .nowPlaying
        case "recent":
            guard let id = url.pathComponents.dropFirst().first else { return nil }
            self = .playRecent(id: id)
        default:
            return nil
        }
    }
}

nonisolated enum SharedContainer {
    private static var url: URL? {
        guard let group = Bundle.main.object(forInfoDictionaryKey: "KoelAppGroup") as? String else { return nil }
        return FileManager.default.containerURL(forSecurityApplicationGroupIdentifier: group)
    }

    private static var snapshotUrl: URL? { url?.appending(path: "widget-snapshot.json") }

    static var artworkDirectory: URL? { url?.appending(path: "WidgetArtwork", directoryHint: .isDirectory) }

    static func artworkUrl(named name: String) -> URL? {
        artworkDirectory?.appending(path: name)
    }

    static func readSnapshot() -> WidgetSnapshot {
        guard let snapshotUrl, let data = try? Data(contentsOf: snapshotUrl) else { return .empty }
        return (try? JSONDecoder().decode(WidgetSnapshot.self, from: data)) ?? .empty
    }

    static func write(_ snapshot: WidgetSnapshot) {
        guard let snapshotUrl, let data = try? JSONEncoder().encode(snapshot) else { return }
        try? data.write(to: snapshotUrl, options: .atomic)
    }
}
