@preconcurrency import Shared
import SwiftUI

struct PlaylistsView: View {
    private enum Sheet: Identifiable {
        case newPlaylist
        case newFolder
        case edit(Playlist)

        var id: String {
            switch self {
            case .newPlaylist: "new-playlist"
            case .newFolder: "new-folder"
            case .edit(let playlist): "edit:\(playlist.id)"
            }
        }
    }

    @Environment(AppModel.self) private var app
    @State private var playlists: [Playlist] = []
    @State private var folders: [PlaylistFolder] = []
    @State private var expandedFolderIds: Set<String> = []
    @State private var sheet: Sheet?
    @State private var playlistPendingDeletion: Playlist?

    var body: some View {
        let library = PlaylistLibrary(playlists: playlists, folders: folders)

        List {
            Group {
                ForEach(library.folderGroups) { group in
                    DisclosureGroup(isExpanded: expansion(of: group.folder)) {
                        ForEach(group.playlists, id: \.id, content: playlistLink)
                    } label: {
                        PlaylistFolderLabel(folder: group.folder, playlistCount: group.playlists.count)
                    }
                    .swipeActions(edge: .leading) {
                        queueButton(for: group.playlists)
                    }
                }
                ForEach(library.rootPlaylists, id: \.id, content: playlistLink)
            }
            .brandListRow()
        }
        .listStyle(.plain)
        .overlay {
            if playlists.isEmpty {
                NoPlaylistsView { sheet = .newPlaylist }
            }
        }
        .navigationTitle("Playlists")
        .brandMeshBackground()
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                Menu {
                    Button("New Playlist", systemImage: "music.note.list") { sheet = .newPlaylist }
                    Button("New Folder", systemImage: "folder.badge.plus") { sheet = .newFolder }
                } label: {
                    Label("Add", systemImage: "plus")
                }
            }
        }
        .refreshable { await refresh() }
        .task {
            for await value in app.core.playlists.playlists { playlists = value }
        }
        .task {
            for await value in app.core.playlistFolders.folders { folders = value }
        }
        .task { await refresh() }
        .sheet(item: $sheet) { sheet in
            switch sheet {
            case .newPlaylist: PlaylistFormSheet(mode: .create)
            case .newFolder: PlaylistFolderFormSheet()
            case .edit(let playlist): PlaylistFormSheet(mode: .edit(playlist))
            }
        }
        .playlistDeletionConfirmation($playlistPendingDeletion) { playlist in
            PlaylistActions(app: app).delete(playlist)
        }
    }

    private func playlistLink(_ playlist: Playlist) -> some View {
        NavigationLink(value: Route.playlist(id: playlist.id)) {
            PlaylistRow(playlist: playlist)
        }
        .swipeActions(edge: .leading) {
            queueButton(for: [playlist])
        }
        .swipeActions(edge: .trailing) {
            if playlist.canDelete {
                ConfirmedRemovalSwipeButton(title: "Delete", systemImage: "trash") { playlistPendingDeletion = playlist }
            }
        }
        .contextMenu {
            PlaylistMenu(
                playlist: playlist,
                onEdit: { sheet = .edit(playlist) },
                onDelete: { playlistPendingDeletion = playlist }
            )
        } preview: {
            PlaylistPreview(playlist: playlist)
        }
    }

    private func queueButton(for playlists: [Playlist]) -> some View {
        PlayLastSwipeButton {
            PlaylistActions(app: app).queue(playlists)
        }
    }

    private func expansion(of folder: PlaylistFolder) -> Binding<Bool> {
        Binding(
            get: { expandedFolderIds.contains(folder.id) },
            set: { isExpanded in
                if isExpanded {
                    expandedFolderIds.insert(folder.id)
                } else {
                    expandedFolderIds.remove(folder.id)
                }
            }
        )
    }

    private func refresh() async {
        try? await app.core.playlists.fetchAll()
        try? await app.core.playlistFolders.fetchAll()
    }
}

/// Shown wherever playlists are listed but there are none yet.
struct NoPlaylistsView: View {
    let create: () -> Void

    var body: some View {
        ContentUnavailableView {
            Label("No playlists", systemImage: "music.note.list")
        } description: {
            Text("Create a playlist to organize your favorite songs.")
        } actions: {
            Button("Create Playlist", action: create)
                .buttonStyle(.glass)
        }
    }
}
