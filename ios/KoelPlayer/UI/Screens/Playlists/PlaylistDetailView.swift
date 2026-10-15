@preconcurrency import Shared
import SwiftUI

struct PlaylistDetailView: View {
    let playlistId: String

    @Environment(AppModel.self) private var app
    @Environment(\.dismiss) private var dismiss
    @State private var playlist: Playlist?
    @State private var songs: [any Playable] = []
    @State private var isLoading = true
    @State private var loadFailed = false
    @State private var searchText = ""
    @State private var isEditing = false
    @State private var playlistPendingDeletion: Playlist?
    @AppStorage("playlistSongSortField") private var storedSortField = ""
    @AppStorage("playlistSongSortDescending") private var isSortDescending = false

    private var sorting: PlaylistSongSorting {
        PlaylistSongSorting(supportsCustomOrder: app.core.session.supports(feature: .customPlaylistOrder))
    }

    private var sortField: String { sorting.field(stored: storedSortField) }
    private var sortOrder: Shared.SortOrder { isSortDescending ? .desc : .asc }

    private var displayedSongs: [any Playable] {
        SortingKt.filtered(SortingKt.sorted(songs, field: sortField, order: sortOrder), keywords: searchText)
    }

    private var canRemoveSongs: Bool {
        playlist.map { !$0.isSmart && $0.canEdit } ?? false
    }

    var body: some View {
        let displayedSongs = displayedSongs

        List {
            if songs.isEmpty, isLoading {
                LoadingRows()
            }
            if let playlist {
                PlaylistHeader(playlist: playlist, songs: displayedSongs)
                    .asListHeaderRow()
            }
            ForEach(displayedSongs, id: \.id) { song in
                PlayableRow(playable: song, removal: canRemoveSongs ? .init(title: "Remove", systemImage: "minus.circle") { remove(song) } : nil)
            }
        }
        .listStyle(.plain)
        .overlay { placeholder }
        .filterable(text: $searchText, prompt: "Filter")
        .navigationTitle(playlist?.name ?? "")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar { toolbarContent }
        .refreshable { await load(forceRefresh: true) }
        .collect(app.core.playables.playlistSongs(playlistId: playlistId)) { songs = $0 }
        .task { await followPlaylist() }
        .task { await load() }
        .sheet(isPresented: $isEditing) {
            if let playlist { PlaylistFormSheet(mode: .edit(playlist)) }
        }
        .playlistDeletionConfirmation($playlistPendingDeletion) { playlist in
            PlaylistActions(app: app).delete(playlist)
        }
    }

    @ViewBuilder
    private var placeholder: some View {
        if songs.isEmpty {
            if isLoading {
                EmptyView()
            } else if loadFailed {
                ContentUnavailableView {
                    Label("Couldn't Load Playlist", systemImage: "exclamationmark.triangle")
                } actions: {
                    Button("Try Again") { Task { await load() } }
                        .buttonStyle(.glass)
                }
            } else {
                ContentUnavailableView("The Playlist Is Empty", systemImage: "music.note.list")
            }
        } else if !searchText.isEmpty, displayedSongs.isEmpty {
            ContentUnavailableView.search(text: searchText)
        }
    }

    @ToolbarContentBuilder
    private var toolbarContent: some ToolbarContent {
        ToolbarItem(placement: .primaryAction) {
            SortMenu(options: sorting.options, field: sortField, order: sortOrder) { field, order in
                storedSortField = field
                isSortDescending = order == .desc
            }
        }
        if let playlist, playlist.canEdit || playlist.canDelete {
            ToolbarItem(placement: .primaryAction) {
                Menu {
                    PlaylistMenu(
                        playlist: playlist,
                        onEdit: { isEditing = true },
                        onDelete: { playlistPendingDeletion = playlist }
                    )
                } label: {
                    Label("More", systemImage: "ellipsis")
                }
            }
        }
    }

    private func followPlaylist() async {
        for await playlists in app.core.playlists.playlists {
            let current = playlists.first { $0.id == playlistId }
            if current == nil, playlist != nil {
                dismiss()
            }
            playlist = current
        }
    }

    private func load(forceRefresh: Bool = false) async {
        isLoading = true
        defer { isLoading = false }
        do {
            _ = try await app.core.playables.fetchForPlaylist(playlistId: playlistId, forceRefresh: forceRefresh)
            loadFailed = false
        } catch {
            loadFailed = true
        }
    }

    private func remove(_ song: any Playable) {
        guard let playlist else { return }
        PlaylistActions(app: app).remove(song, from: playlist)
    }
}

private struct PlaylistHeader: View {
    let playlist: Playlist
    let songs: [any Playable]

    var body: some View {
        CollectionHeader(
            artworkUrl: playlist.cover ?? songs.first?.artworkUrl,
            title: playlist.name,
            subtitle: playlist.description_.flatMap { $0.isEmpty ? nil : $0 },
            detail: detail,
            playables: songs
        )
    }

    private var detail: String {
        let kind = playlist.isSmart ? "Smart Playlist" : "Playlist"
        guard !songs.isEmpty else { return kind }
        let length = songs.reduce(0) { $0 + $1.length }
        return "\(kind) • \(songs.count.pluralized("song")) • \(length.totalLength)"
    }
}
