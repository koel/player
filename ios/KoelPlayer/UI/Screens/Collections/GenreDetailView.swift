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
    @State private var isLoading = false
    @State private var hasFailed = false

    private static let sortKey = "genre.sort"

    private var displayedSongs: [any Playable] {
        SortingKt.filtered(songs, keywords: query)
    }

    private var songCountLabel: String? {
        app.core.genres.byId(id: genreId).map { Int($0.songCount).pluralized("song") }
    }

    var body: some View {
        List {
            if !loadedSongs.isEmpty {
                CollectionHeader(
                    artworkUrl: loadedSongs.first?.artworkUrl,
                    title: name,
                    detail: songCountLabel,
                    playables: displayedSongs
                )
                .listRowSeparator(.hidden)
            }

            PlayableListContent(playables: displayedSongs, isSortedByTitle: sort.field == PlayableSortField.shared.TITLE)

            if nextPage != nil, !loadedSongs.isEmpty, !hasFailed {
                LoadMoreRow(loadedCount: loadedSongs.count, load: loadMore)
            }
        }
        .listStyle(.plain)
        .navigationTitle(name)
        .navigationBarTitleDisplayMode(.inline)
        .filterable(text: $query, prompt: "Filter Songs")
        .refreshable { await refresh() }
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                SortMenu(options: SortOptions.genreSongs, field: sort.field, order: sort.order) { field, order in
                    sort = SortSetting(field: field, order: order)
                    sort.remember(for: Self.sortKey)
                    Task { await refresh() }
                }
            }
        }
        .overlay {
            ListStateOverlay(isEmpty: loadedSongs.isEmpty, isLoading: isLoading, hasFailed: hasFailed, retry: retry) {
                ContentUnavailableView("No Songs", systemImage: "music.note")
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
        guard !isLoading, let page = nextPage else { return }
        isLoading = true
        defer { isLoading = false }
        do {
            let result = try await fetchPage(page)
            let loadedIds = Set(loadedSongs.map(\.id))
            loadedSongs += result.songs.filter { !loadedIds.contains($0.id) }
            nextPage = result.nextPage
            hasFailed = false
        } catch {
            hasFailed = true
        }
    }

    private func refresh() async {
        do {
            let result = try await fetchPage(1)
            loadedSongs = result.songs
            nextPage = result.nextPage
            hasFailed = false
        } catch {
            hasFailed = loadedSongs.isEmpty
        }
    }

    private func retry() {
        hasFailed = false
        Task { await loadMore() }
    }
}
