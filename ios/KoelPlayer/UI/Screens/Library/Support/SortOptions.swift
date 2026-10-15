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

    static func favorites(supportsCustomOrder: Bool) -> [SortOption] {
        (supportsCustomOrder ? [customOrder] : []) + [title, artist, recentlyAdded]
    }

    private static let title: SortOption = (PlayableSortField.shared.TITLE, "Title")
    private static let artist: SortOption = (PlayableSortField.shared.ARTIST_NAME, "Artist")
    private static let album: SortOption = (PlayableSortField.shared.ALBUM_NAME, "Album")
    private static let track: SortOption = (PlayableSortField.shared.TRACK, "Track Number")
    private static let customOrder: SortOption = (PlayableSortField.shared.POSITION, "Custom Order")
    private static let recentlyAdded: SortOption = (PlayableSortField.shared.CREATED_AT, "Recently Added")
    private static let name: SortOption = (AlbumSortField.shared.NAME, "Name")
    private static let year: SortOption = (AlbumSortField.shared.YEAR, "Year")
}

/// A list's sort field and order, remembered per list for the session like Flutter's AppState.
struct SortSetting: Equatable {
    var field: String
    var order: Shared.SortOrder

    private static var rememberedSettings: [String: SortSetting] = [:]

    static func remembered(for key: String, default fallback: SortSetting) -> SortSetting {
        rememberedSettings[key] ?? fallback
    }

    func remember(for key: String) {
        Self.rememberedSettings[key] = self
    }
}
