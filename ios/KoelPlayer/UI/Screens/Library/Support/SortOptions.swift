import Foundation
@preconcurrency import Shared

typealias SortOption = (field: String, label: String)

/// The sort fields each list offers, matching the Flutter app's sort menus.
enum SortOptions {
    static let songs = [title, artist, recentlyAdded]
    static let albums = [name, artist, year, recentlyAdded]
    static let artists = [name, recentlyAdded]
    static let genreSongs = [title, artist, album]
    static let albumSongs = [track, title, recentlyAdded]
    static let artistSongs = [title, album, recentlyAdded]
    static let podcastEpisodes = [title, recentlyAdded]
    static let podcasts = PodcastSortOption.allCases.map { SortOption($0.rawValue, $0.label) }

    /// Servers that keep a custom order offer it first, as the default.
    static func favorites(supportsCustomOrder: Bool) -> [SortOption] {
        customOrderable(supportsCustomOrder: supportsCustomOrder)
    }

    static func playlistSongs(supportsCustomOrder: Bool) -> [SortOption] {
        customOrderable(supportsCustomOrder: supportsCustomOrder)
    }

    private static func customOrderable(supportsCustomOrder: Bool) -> [SortOption] {
        (supportsCustomOrder ? [customOrder] : []) + [title, artist, recentlyAdded]
    }

    private static let title: SortOption = (PlayableSortField.shared.TITLE, "Title")
    private static let artist: SortOption = (PlayableSortField.shared.ARTIST_NAME, "Artist")
    private static let album: SortOption = (PlayableSortField.shared.ALBUM_NAME, "Album or podcast")
    private static let track: SortOption = (PlayableSortField.shared.TRACK, "Track number")
    private static let customOrder: SortOption = (PlayableSortField.shared.POSITION, "Custom order")
    private static let recentlyAdded: SortOption = (PlayableSortField.shared.CREATED_AT, "Recently added")
    private static let name: SortOption = (AlbumSortField.shared.NAME, "Name")
    private static let year: SortOption = (AlbumSortField.shared.YEAR, "Year")
}

/// The podcast sort fields, by the raw value a `SortSetting` keeps.
enum PodcastSortOption: String, CaseIterable {
    case lastPlayedAt
    case subscribedAt
    case title
    case author

    var label: String {
        switch self {
        case .lastPlayedAt: "Last played"
        case .subscribedAt: "Subscribed"
        case .title: "Title"
        case .author: "Author"
        }
    }

    var field: PodcastSortField {
        switch self {
        case .lastPlayedAt: .lastPlayedAt
        case .subscribedAt: .subscribedAt
        case .title: .title
        case .author: .author
        }
    }
}

/// A list's sort field and order, remembered per list across launches.
struct SortSetting: Equatable {
    var field: String
    var order: Shared.SortOrder

    static var defaults = UserDefaults.standard

    /// Falls back when the remembered field isn't among `options`, such as Custom Order on a server without it.
    static func remembered(for key: String, among options: [SortOption]? = nil, default fallback: SortSetting) -> SortSetting {
        guard let saved = defaults.dictionary(forKey: storageKey(key)) as? [String: String],
              let field = saved["field"],
              options?.contains(where: { $0.field == field }) ?? true
        else { return fallback }
        return SortSetting(field: field, order: saved["order"] == Shared.SortOrder.desc.value ? .desc : .asc)
    }

    func remember(for key: String) {
        Self.defaults.set(["field": field, "order": order.value], forKey: Self.storageKey(key))
    }

    private static func storageKey(_ key: String) -> String { "sort.\(key)" }
}

/// Whether a collection list shows a grid of covers or rows, remembered per list across launches like its sort.
enum CollectionLayout: String, CaseIterable {
    case grid
    case list

    var label: String {
        switch self {
        case .grid: "Grid"
        case .list: "List"
        }
    }

    var systemImage: String {
        switch self {
        case .grid: "square.grid.2x2"
        case .list: "list.bullet"
        }
    }

    static func remembered(for key: String) -> CollectionLayout {
        SortSetting.defaults.string(forKey: storageKey(key)).flatMap(CollectionLayout.init(rawValue:)) ?? .grid
    }

    func remember(for key: String) {
        SortSetting.defaults.set(rawValue, forKey: Self.storageKey(key))
    }

    private static func storageKey(_ key: String) -> String { "layout.\(key)" }
}
