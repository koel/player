@preconcurrency import Shared
import SwiftUI

struct AddToPlaylistView: View {
    let playables: [any Playable]

    @Environment(AppModel.self) private var app
    @Environment(\.dismiss) private var dismiss
    @State private var playlists: [Playlist] = []
    @State private var isCreatingPlaylist = false

    var body: some View {
        NavigationStack {
            List {
                if !playlists.isEmpty {
                    Section {
                        Button("New Playlist…", systemImage: "plus") { isCreatingPlaylist = true }
                    }
                    Section {
                        ForEach(playlists, id: \.id) { playlist in
                            Button {
                                add(to: playlist)
                            } label: {
                                PlaylistRow(playlist: playlist)
                            }
                            .buttonStyle(.plain)
                        }
                    }
                }
            }
            .overlay {
                if playlists.isEmpty {
                    ContentUnavailableView {
                        Label("No Playlists", systemImage: "music.note.list")
                    } description: {
                        Text("Create a playlist to organize your favorite songs.")
                    } actions: {
                        Button("Create Playlist") { isCreatingPlaylist = true }
                            .buttonStyle(.glassProminent)
                    }
                }
            }
            .navigationTitle("Add to a Playlist")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel", role: .cancel) { dismiss() }
                }
            }
            .task {
                for await value in app.core.playlists.standardPlaylists { playlists = value }
            }
            .sheet(isPresented: $isCreatingPlaylist) {
                PlaylistFormSheet(mode: .create, onCreate: add(to:))
            }
        }
        .presentationDetents([.medium, .large])
    }

    private func add(to playlist: Playlist) {
        app.sheet = nil
        PlaylistActions(app: app).add(playables, to: playlist)
    }
}
