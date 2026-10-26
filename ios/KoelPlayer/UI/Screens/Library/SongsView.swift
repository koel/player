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
    @State private var loadState = LoadState()

    private static let sortKey = "songs.sort"

    private var store: PlayableStore { app.core.playables }

    private var currentSort: SortSetting {
        sort ?? SortSetting.remembered(for: Self.sortKey, default: SortSetting(field: store.songSortField, order: store.songSortOrder))
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
            Group {
                if !isSearching {
                    AllSongsPlayButtons(sort: currentSort)
                }

                if !isSearching, songs.isEmpty, loadState.isPending {
                    LoadingRows()
                }

                PlayableListContent(
                    playables: displayedSongs,
                    isSortedByTitle: currentSort.field == PlayableSortField.shared.TITLE
                )

                if !isSearching {
                    NextPageRow(hasMore: hasMore, loadedCount: songs.count, loadState: loadState, load: loadMore)
                }
            }
            .brandListRow()
        }
        .listStyle(.plain)
        .navigationTitle("All songs")
        .brandMeshBackground()
        .filterable(text: $query, matchesNothing: isSearching && searchResults?.isEmpty == true, isShown: isSearching || !songs.isEmpty || loadState.isPending, prompt: "Search Songs")
        .refreshable { await refresh() }
        .toolbar {
            SortToolbarItem(options: SortOptions.songs, sort: currentSort, rememberKey: Self.sortKey) { setting in
                sort = setting
                guard !isSearching else { return }
                Task { await refresh() }
            }
        }
        .overlay {
            if !isSearching {
                ListStateOverlay(isEmpty: songs.isEmpty, loadState: loadState, showsSpinner: false, retry: { Task { await loadMore() } }) {
                    ContentUnavailableView("No songs", systemImage: "music.note")
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
            if store.songs.value.isEmpty { await refresh() }
        }
        .task(id: query) { await search() }
        .collect(store.live(playables: searchResults ?? []), id: searchResults?.map(\.id)) { live in
            if searchResults != nil { searchResults = live }
        }
    }

    private func loadMore() async {
        await loadState.load { try await store.loadMoreSongs() }
    }

    private func refresh() async {
        await loadState.refresh(hasItems: !songs.isEmpty) {
            try await store.refreshSongs(sortField: currentSort.field, sortOrder: currentSort.order)
        }
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
        PlayShuffleRow(isDisabled: isFetching) {
            fetchAndPlay { try await app.core.playables.fetchInOrder(sortField: sort.field, sortOrder: sort.order) }
        } shuffle: {
            fetchAndPlay(shuffled: true) { try await app.core.playables.fetchRandom() }
        }
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
