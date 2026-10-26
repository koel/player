@preconcurrency import Shared
import SwiftUI

/// Every song by an artist, sortable and filterable; the artist page's "Top Songs" leads here.
struct ArtistSongsView: View {
    let artistId: String

    @Environment(AppModel.self) private var app
    @State private var artist: Artist?
    @State private var songs: [any Playable] = []
    @State private var sort = SortSetting.remembered(for: Self.sortKey, default: SortSetting(field: PlayableSortField.shared.TITLE, order: .asc))
    @State private var query = ""
    @State private var loadState = LoadState()

    private static let sortKey = "artist.sort"

    private var displayedSongs: [any Playable] {
        SortingKt.filtered(SortingKt.sorted(songs, field: sort.field, order: sort.order), keywords: query)
    }

    var body: some View {
        let displayedSongs = displayedSongs

        List {
            Group {
                PlayShuffleButtons(playables: displayedSongs)

                if songs.isEmpty, loadState.isPending {
                    LoadingRows()
                }

                PlayableListContent(playables: displayedSongs, style: .artist, isSortedByTitle: sort.field == PlayableSortField.shared.TITLE)
            }
            .brandListRow()
        }
        .listStyle(.plain)
        .navigationTitle(artist?.name ?? "Songs")
        .brandMeshBackground()
        .navigationBarTitleDisplayMode(.inline)
        .filterable(text: $query, matchesNothing: !songs.isEmpty && displayedSongs.isEmpty, isShown: !songs.isEmpty || loadState.isPending)
        .refreshable { await load(forceRefresh: true) }
        .toolbar {
            SortToolbarItem(options: SortOptions.artistSongs, sort: sort, rememberKey: Self.sortKey) { sort = $0 }
        }
        .overlay {
            ListStateOverlay(isEmpty: songs.isEmpty, loadState: loadState, showsSpinner: false, retry: { Task { await load() } }) {
                ContentUnavailableView("No songs", systemImage: "music.note")
            }
        }
        .collect(app.core.artists.observe(id: artistId), id: artistId) { artist = $0 }
        .collect(app.core.playables.artistSongs(artistId: artistId), id: artistId) { songs = $0 }
        .task(id: artistId) { await load() }
    }

    private func load(forceRefresh: Bool = false) async {
        await loadState.load {
            _ = try await app.core.playables.fetchForArtist(artistId: artistId, forceRefresh: forceRefresh)
        }
    }
}
