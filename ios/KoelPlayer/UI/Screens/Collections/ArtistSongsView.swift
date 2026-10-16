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
    @State private var hasLoaded = false
    @State private var hasFailed = false

    private static let sortKey = "artist.sort"

    private var displayedSongs: [any Playable] {
        SortingKt.filtered(SortingKt.sorted(songs, field: sort.field, order: sort.order), keywords: query)
    }

    var body: some View {
        List {
            PlayShuffleButtons(playables: displayedSongs)
                .listRowSeparator(.hidden)
                .listRowInsets(EdgeInsets(top: 8, leading: 0, bottom: 8, trailing: 0))

            if songs.isEmpty, !hasLoaded, !hasFailed {
                LoadingRows(count: 8)
            }

            PlayableListContent(playables: displayedSongs, style: .artist)
        }
        .listStyle(.plain)
        .navigationTitle(artist?.name ?? "Songs")
        .navigationBarTitleDisplayMode(.inline)
        .filterable(text: $query, prompt: "Filter Songs")
        .refreshable { await load(forceRefresh: true) }
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                SortMenu(options: SortOptions.artistSongs, field: sort.field, order: sort.order) { field, order in
                    sort = SortSetting(field: field, order: order)
                    sort.remember(for: Self.sortKey)
                }
            }
        }
        .overlay {
            if hasFailed, songs.isEmpty {
                LoadFailedView { Task { await load() } }
            }
        }
        .collect(app.core.artists.observe(id: artistId), id: artistId) { artist = $0 }
        .collect(app.core.playables.artistSongs(artistId: artistId), id: artistId) { songs = $0 }
        .task(id: artistId) { await load() }
    }

    private func load(forceRefresh: Bool = false) async {
        do {
            _ = try await app.core.playables.fetchForArtist(artistId: artistId, forceRefresh: forceRefresh)
            hasFailed = false
            hasLoaded = true
        } catch {
            hasFailed = true
        }
    }
}
