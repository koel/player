@preconcurrency import Shared
import SwiftUI

/// A genre's songs, paginated and sorted by the server, filtered locally.
struct GenreDetailView: View {
    let genreId: String
    let name: String

    @Environment(AppModel.self) private var app
    @State private var loadedSongs: [any Playable] = []
    @State private var songs: [any Playable] = []
    @State private var nextPage: Int32? = 1
    @State private var sort = SortSetting.remembered(for: Self.sortKey, default: SortSetting(field: PlayableSortField.shared.TITLE, order: .asc))
    @State private var query = ""
    @State private var loadState = LoadState()

    private static let sortKey = "genre.sort"

    private var displayedSongs: [any Playable] {
        SortingKt.filtered(songs, keywords: query)
    }

    private var songCountLabel: String? {
        app.core.genres.byId(id: genreId).map { Int($0.songCount).pluralized("song") }
    }

    var body: some View {
        let displayedSongs = displayedSongs

        CollectionDetailList(
            title: name,
            artworkUrl: loadedSongs.first?.artworkUrl,
            header: loadedSongs.isEmpty ? nil : CollectionHeader(
                artworkUrl: loadedSongs.first?.artworkUrl,
                title: name,
                detail: songCountLabel,
                playables: displayedSongs
            ),
            songs: loadedSongs,
            displayedSongs: displayedSongs,
            query: $query,
            loadState: loadState,
            isSortedByTitle: sort.field == PlayableSortField.shared.TITLE,
            retry: { Task { await loadMore() } },
            refresh: refresh
        ) {
            ContentUnavailableView("No songs", systemImage: "music.note")
        } footer: {
            if loadState.canLoadMore(hasMore: nextPage != nil, loadedCount: loadedSongs.count) {
                LoadMoreRow(loadedCount: loadedSongs.count, load: loadMore)
            }
        }
        .toolbar {
            SortToolbarItem(options: SortOptions.genreSongs, sort: sort, rememberKey: Self.sortKey) { setting in
                sort = setting
                Task { await refresh() }
            }
        }
        .collect(app.core.playables.live(playables: loadedSongs), id: loadedSongs.map(\.id)) { songs = $0 }
        .task {
            if loadedSongs.isEmpty { await loadMore() }
        }
    }

    private func fetchPage(_ page: Int32) async throws -> (songs: [any Playable], nextPage: Int32?) {
        let result = try await app.core.playables.fetchPageForGenre(
            genreId: genreId,
            page: page,
            sortField: sort.field,
            sortOrder: sort.order
        )
        return (result.items.compactMap { $0 as? any Playable }, result.nextPage?.int32Value)
    }

    private func loadMore() async {
        guard let page = nextPage else { return }
        await loadState.load { try await fetchPage(page) } apply: { result in
            let loadedIds = Set(loadedSongs.map(\.id))
            loadedSongs += result.songs.filter { !loadedIds.contains($0.id) }
            nextPage = result.nextPage
        }
    }

    private func refresh() async {
        await loadState.refresh(hasItems: !loadedSongs.isEmpty) { try await fetchPage(1) } apply: { result in
            loadedSongs = result.songs
            nextPage = result.nextPage
        }
    }
}
