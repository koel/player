@preconcurrency import Shared
import SwiftUI

struct PlaylistFormSheet: View {
    enum Mode {
        case create
        case edit(Playlist)
    }

    let mode: Mode
    let onCreate: (Playlist) -> Void

    @Environment(AppModel.self) private var app
    @State private var draft: PlaylistDraft
    @FocusState private var isNameFocused: Bool

    init(mode: Mode, onCreate: @escaping (Playlist) -> Void = { _ in }) {
        self.mode = mode
        self.onCreate = onCreate
        if case .edit(let playlist) = mode {
            _draft = State(initialValue: PlaylistDraft(playlist: playlist))
        } else {
            _draft = State(initialValue: PlaylistDraft())
        }
    }

    private var editedPlaylist: Playlist? {
        if case .edit(let playlist) = mode { playlist } else { nil }
    }

    var body: some View {
        let folders = app.core.playlistFolders.folders.value
        let isEditing = editedPlaylist != nil

        FormSheet(
            title: isEditing ? "Edit Playlist" : "New Playlist",
            submitLabel: isEditing ? "Save" : "Create",
            canSubmit: draft.isValid,
            failureMessage: { _ in isEditing ? "Could not update playlist." : "Could not create playlist." },
            submit: save
        ) {
            TextField("Playlist Name", text: $draft.name)
                .focused($isNameFocused)
            TextField("Description (optional)", text: $draft.description, axis: .vertical)
                .lineLimit(2...4)
            if !folders.isEmpty {
                Picker("Folder", selection: $draft.folderId) {
                    Text("No folder").tag(String?.none)
                    ForEach(folders, id: \.id) { folder in
                        Text(folder.name).tag(Optional(folder.id))
                    }
                }
            }
        }
        .onAppear { isNameFocused = true }
    }

    private func save() async throws {
        if let editedPlaylist {
            try await app.core.playlists.update(
                playlist: editedPlaylist,
                name: draft.trimmedName,
                description: draft.trimmedDescription,
                folderId: draft.folderId
            )
            app.toasts.show("Playlist updated")
        } else {
            let playlist = try await app.core.playlists.create(
                name: draft.trimmedName,
                description: draft.trimmedDescription,
                folderId: draft.folderId
            )
            app.toasts.show("Playlist added")
            onCreate(playlist)
        }
    }
}

struct PlaylistFolderFormSheet: View {
    @Environment(AppModel.self) private var app
    @State private var name = ""
    @FocusState private var isNameFocused: Bool

    private var trimmedName: String { name.trimmingCharacters(in: .whitespacesAndNewlines) }

    var body: some View {
        FormSheet(
            title: "New Folder",
            submitLabel: "Create",
            canSubmit: !trimmedName.isEmpty,
            failureMessage: { _ in "Could not create folder." },
            submit: save
        ) {
            TextField("Folder Name", text: $name)
                .focused($isNameFocused)
        }
        .onAppear { isNameFocused = true }
    }

    private func save() async throws {
        _ = try await app.core.playlistFolders.create(name: trimmedName)
        app.toasts.show("Folder created", systemImage: "folder.badge.plus")
    }
}
