import Foundation
@preconcurrency import Shared

/// Playlists arranged the way the Playlists screen lists them: folders first, then loose playlists, all by name.
struct PlaylistLibrary {
    struct FolderGroup: Identifiable {
        let folder: PlaylistFolder
        let playlists: [Playlist]

        var id: String { folder.id }
    }

    let folderGroups: [FolderGroup]
    /// Playlists outside any folder, including those whose folder no longer exists.
    let rootPlaylists: [Playlist]

    init(playlists: [Playlist], folders: [PlaylistFolder]) {
        let playlistsByFolderId = Dictionary(grouping: playlists.sortedByName(\.name)) { $0.folderId ?? "" }
        let knownFolderIds = Set(folders.map(\.id))

        folderGroups = folders.sortedByName(\.name).map { folder in
            FolderGroup(folder: folder, playlists: playlistsByFolderId[folder.id] ?? [])
        }
        rootPlaylists = playlists.sortedByName(\.name).filter { playlist in
            playlist.folderId.map { !knownFolderIds.contains($0) } ?? true
        }
    }
}

private extension Array {
    func sortedByName(_ name: (Element) -> String) -> [Element] {
        sorted { name($0).localizedStandardCompare(name($1)) == .orderedAscending }
    }
}

/// The fields of the New Playlist and Edit Playlist sheets.
struct PlaylistDraft {
    var name = ""
    var description = ""
    var folderId: String?

    init() {}

    init(playlist: Playlist) {
        name = playlist.name
        description = playlist.description_ ?? ""
        folderId = playlist.folderId
    }

    var trimmedName: String { name.trimmingCharacters(in: .whitespacesAndNewlines) }
    var trimmedDescription: String { description.trimmingCharacters(in: .whitespacesAndNewlines) }
    var isValid: Bool { !trimmedName.isEmpty }
}

/// Sort fields for a playlist's songs. Servers that keep a custom order offer it first, as the default.
struct PlaylistSongSorting {
    let supportsCustomOrder: Bool

    var options: [(field: String, label: String)] {
        let fields = PlayableSortField.shared
        let custom = supportsCustomOrder ? [(field: fields.POSITION, label: "Custom Order")] : []
        return custom + [
            (field: fields.TITLE, label: "Title"),
            (field: fields.ARTIST_NAME, label: "Artist"),
            (field: fields.CREATED_AT, label: "Recently Added"),
        ]
    }

    /// The stored field when it's still offered, otherwise the default.
    func field(stored: String) -> String {
        options.contains { $0.field == stored } ? stored : options[0].field
    }
}
