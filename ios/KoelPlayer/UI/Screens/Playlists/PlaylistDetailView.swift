@preconcurrency import Shared
import SwiftUI

struct PlaylistDetailView: View {
    let playlistId: String

    @Environment(AppModel.self) private var app
    @Environment(\.dismiss) private var dismiss
    @State private var playlist: Playlist?
    @State private var songs: [any Playable] = []
    @State private var loadState = LoadState()
    @State private var query = ""
    @State private var sort: SortSetting?
    @State private var isEditing = false
    @State private var playlistPendingDeletion: Playlist?

    private static let sortKey = "playlist.sort"

    private var sortOptions: [SortOption] {
        SortOptions.playlistSongs(supportsCustomOrder: app.core.session.supports(feature: .customPlaylistOrder))
    }

    private var currentSort: SortSetting {
        sort ?? SortSetting.remembered(
            for: Self.sortKey,
            among: sortOptions,
            default: SortSetting(field: sortOptions[0].field, order: .asc)
        )
    }

    private var displayedSongs: [any Playable] {
        SortingKt.filtered(SortingKt.sorted(songs, field: currentSort.field, order: currentSort.order), keywords: query)
    }

    private var artworkUrl: String? {
        playlist?.cover ?? songs.first?.artworkUrl
    }

    var body: some View {
        let displayedSongs = displayedSongs

        CollectionDetailList(
            title: playlist?.name ?? "",
            artworkUrl: artworkUrl,
            header: playlist.map { header(of: $0, songs: displayedSongs) },
            songs: songs,
            displayedSongs: displayedSongs,
            query: $query,
            loadState: loadState,
            isSortedByTitle: currentSort.field == PlayableSortField.shared.TITLE,
            removal: songRemoval,
            retry: { Task { await load() } },
            refresh: { await load(forceRefresh: true) }
        ) {
            ContentUnavailableView("The playlist is empty.", systemImage: "music.note.list")
        }
        .toolbar {
            SortToolbarItem(options: sortOptions, sort: currentSort, rememberKey: Self.sortKey) { sort = $0 }
            if let playlist, playlist.canEdit || playlist.canDelete {
                MoreMenuToolbarItem {
                    PlaylistMenu(
                        playlist: playlist,
                        onEdit: { isEditing = true },
                        onDelete: { playlistPendingDeletion = playlist }
                    )
                }
            }
        }
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
        await loadState.load {
            _ = try await app.core.playables.fetchForPlaylist(playlistId: playlistId, forceRefresh: forceRefresh)
        }
    }

    private func header(of playlist: Playlist, songs: [any Playable]) -> CollectionHeader<EmptyView> {
        CollectionHeader(
            artworkUrl: artworkUrl,
            title: playlist.name,
            subtitle: playlist.description_.flatMap { $0.isEmpty ? nil : $0 },
            detail: CollectionSummary.detail(label: playlist.kindLabel, songs: songs),
            playables: songs
        )
    }

    private var songRemoval: ((any Playable) -> PlayableRow.Removal)? {
        guard let playlist, !playlist.isSmart, playlist.canEdit else { return nil }
        return { song in
            PlayableRow.Removal(title: "Remove", systemImage: "minus.circle") {
                PlaylistActions(app: app).remove(song, from: playlist)
            }
        }
    }
}
