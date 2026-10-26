@preconcurrency import Shared
import SwiftUI

struct PlaylistRow: View {
    let playlist: Playlist

    var body: some View {
        MediaRow(title: playlist.name, subtitle: playlist.kindLabel) {
            PlaylistArtwork(playlist: playlist, size: 44)
        }
    }
}

/// The playlist's cover, or a symbol telling smart and standard playlists apart.
struct PlaylistArtwork: View {
    let playlist: Playlist
    let size: CGFloat

    var body: some View {
        Artwork(url: playlist.cover, size: size, cornerRadius: 6, fallbackSymbol: playlist.isSmart ? "wand.and.sparkles" : "music.note.list")
    }
}

extension Playlist {
    static let smartKindLabel = "Smart playlist"

    var kindLabel: String {
        isSmart ? Self.smartKindLabel : "Standard playlist"
    }
}

struct PlaylistFolderLabel: View {
    let folder: PlaylistFolder
    let playlistCount: Int

    var body: some View {
        MediaRow(title: folder.name, subtitle: playlistCount.pluralized("playlist")) {
            Image(systemName: "folder")
                .font(.title3)
                .foregroundStyle(.secondary)
                .frame(width: 44, height: 44)
        }
    }
}

/// Context menu items for a playlist row.
struct PlaylistMenu: View {
    let playlist: Playlist
    let onEdit: () -> Void
    let onDelete: () -> Void

    @Environment(AppModel.self) private var app

    var body: some View {
        Button("Play Last", systemImage: "text.line.last.and.arrowtriangle.forward") {
            PlaylistActions(app: app).queue([playlist])
        }

        if playlist.canEdit {
            Button("Edit…", systemImage: "pencil", action: onEdit)
            moveMenu
        }

        if playlist.canDelete {
            Button("Delete", systemImage: "trash", role: .destructive, action: onDelete)
        }
    }

    @ViewBuilder
    private var moveMenu: some View {
        let folders = app.core.playlistFolders.folders.value
        if !folders.isEmpty {
            Menu("Move to Folder", systemImage: "folder") {
                Picker("Folder", selection: Binding(get: { playlist.folderId }, set: { move(toFolderId: $0) })) {
                    Text("No folder").tag(String?.none)
                    ForEach(folders, id: \.id) { folder in
                        Text(folder.name).tag(Optional(folder.id))
                    }
                }
            }
        }
    }

    private func move(toFolderId folderId: String?) {
        PlaylistActions(app: app).move(playlist, toFolderId: folderId)
    }
}
