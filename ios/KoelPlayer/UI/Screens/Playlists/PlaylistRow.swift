@preconcurrency import Shared
import SwiftUI

struct PlaylistRow: View {
    let playlist: Playlist

    var body: some View {
        HStack(spacing: 12) {
            PlaylistArtwork(playlist: playlist, size: 44)
            VStack(alignment: .leading, spacing: 2) {
                Text(playlist.name)
                    .lineLimit(1)
                Text(playlist.isSmart ? "Smart Playlist" : "Playlist")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
        }
    }
}

/// The playlist's cover, or a symbol telling smart and standard playlists apart.
struct PlaylistArtwork: View {
    let playlist: Playlist
    let size: CGFloat

    var body: some View {
        if let cover = playlist.cover, !cover.isEmpty {
            Artwork(url: cover, size: size, cornerRadius: 6)
        } else {
            Image(systemName: playlist.isSmart ? "gearshape" : "music.note.list")
                .font(.system(size: size * 0.4))
                .foregroundStyle(.secondary)
                .frame(width: size, height: size)
                .background(.quaternary, in: .rect(cornerRadius: 6))
                .accessibilityHidden(true)
        }
    }
}

struct PlaylistFolderLabel: View {
    let folder: PlaylistFolder
    let playlistCount: Int

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: "folder")
                .font(.title3)
                .foregroundStyle(.secondary)
                .frame(width: 44, height: 44)
            VStack(alignment: .leading, spacing: 2) {
                Text(folder.name)
                    .lineLimit(1)
                Text(playlistCount.pluralized("playlist"))
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
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
                    Text("None").tag(String?.none)
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
