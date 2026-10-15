@preconcurrency import Shared
import SwiftUI

/// All songs, paginated and sorted by the server. Filtering searches the server instead.
struct SongsView: View {
    @Environment(AppModel.self) private var app
    @State private var songs: [any Playable] = []
    @State private var hasMore = true
    @State private var sort: SortSetting?
    @State private var query = ""
    @State private var searchResults: [any Playable]?
    @State private var isLoading = false
    @State private var hasFailed = false

    private var store: PlayableStore { app.core.playables }

    private var currentSort: SortSetting {
        sort ?? SortSetting(field: store.songSortField, order: store.songSortOrder)
    }

    private var isSearching: Bool {
        !query.trimmingCharacters(in: .whitespaces).isEmpty
    }

    private var displayedSongs: [any Playable] {
        guard isSearching else { return songs }
        return SortingKt.sorted(searchResults ?? [], field: currentSort.field, order: currentSort.order)
    }

    var body: some View {
        List {
            if !isSearching {
                AllSongsPlayButtons(sort: currentSort)
                    .listRowSeparator(.hidden)
            }

            PlayableListContent(
                playables: displayedSongs,
                isSortedByTitle: currentSort.field == PlayableSortField.shared.TITLE
            )

            if !isSearching, hasMore, !songs.isEmpty, !hasFailed {
                LoadMoreRow(loadedCount: songs.count, load: loadMore)
            }
        }
        .listStyle(.plain)
        .navigationTitle("Songs")
        .filterable(text: $query, prompt: "Search Songs")
        .refreshable { await refresh() }
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                SortMenu(options: SortOptions.songs, field: currentSort.field, order: currentSort.order) { field, order in
                    sort = SortSetting(field: field, order: order)
                    guard !isSearching else { return }
                    Task { await refresh() }
                }
            }
        }
        .overlay {
            if isSearching {
                if searchResults?.isEmpty == true {
                    ContentUnavailableView.search(text: query)
                }
            } else {
                ListStateOverlay(isEmpty: songs.isEmpty, isLoading: isLoading, hasFailed: hasFailed, retry: retry) {
                    ContentUnavailableView("No Songs", systemImage: "music.note")
                }
            }
        }
        .task {
            for await next in store.songs { songs = next }
        }
        .task {
            for await next in store.hasMoreSongs { hasMore = next.boolValue }
        }
        .task {
            if songs.isEmpty { await loadMore() }
        }
        .task(id: query) { await search() }
    }

    private func loadMore() async {
        guard !isLoading else { return }
        isLoading = true
        defer { isLoading = false }
        do {
            try await store.loadMoreSongs()
            hasFailed = false
        } catch {
            hasFailed = true
        }
    }

    private func refresh() async {
        do {
            try await store.refreshSongs(sortField: currentSort.field, sortOrder: currentSort.order)
            hasFailed = false
        } catch {
            hasFailed = songs.isEmpty
        }
    }

    private func retry() {
        hasFailed = false
        Task { await loadMore() }
    }

    private func search() async {
        let keywords = query.trimmingCharacters(in: .whitespaces)
        guard !keywords.isEmpty else {
            searchResults = nil
            return
        }

        do {
            try await Task.sleep(for: .milliseconds(300))
            searchResults = try await app.core.search.searchPlayables(keywords: keywords)
        } catch is CancellationError {
            return
        } catch {
            searchResults = []
        }
    }
}

/// Plays every song in the library in the current order, or shuffles a random selection, as Flutter did.
private struct AllSongsPlayButtons: View {
    let sort: SortSetting

    @Environment(AppModel.self) private var app
    @State private var isFetching = false

    var body: some View {
        HStack(spacing: 12) {
            Button {
                fetchAndPlay { try await app.core.playables.fetchInOrder(sortField: sort.field, sortOrder: sort.order) }
            } label: {
                Label("Play", systemImage: "play.fill").frame(maxWidth: .infinity)
            }
            Button {
                fetchAndPlay(shuffled: true) { try await app.core.playables.fetchRandom() }
            } label: {
                Label("Shuffle", systemImage: "shuffle").frame(maxWidth: .infinity)
            }
        }
        .buttonStyle(.glass)
        .controlSize(.large)
        .disabled(isFetching)
    }

    private func fetchAndPlay(shuffled: Bool = false, fetch: @escaping () async throws -> [any Playable]) {
        isFetching = true
        Task {
            defer { isFetching = false }
            do {
                app.player.play(try await fetch(), shuffled: shuffled)
            } catch {
                app.toasts.showError()
            }
        }
    }
}
