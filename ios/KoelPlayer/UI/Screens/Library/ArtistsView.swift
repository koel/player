@preconcurrency import Shared
import SwiftUI

struct ArtistsView: View {
    @Environment(AppModel.self) private var app
    @State private var artists: [Artist] = []
    @State private var hasMore = true
    @State private var sort: SortSetting?
    @State private var isLoading = false
    @State private var hasFailed = false
    @State private var editingArtist: Artist?

    private var store: ArtistStore { app.core.artists }

    private var currentSort: SortSetting {
        sort ?? SortSetting(field: store.sortField, order: store.sortOrder)
    }

    private var isIndexed: Bool {
        SectionIndex.isShown(itemCount: artists.count, isSortedByName: currentSort.field == ArtistSortField.shared.NAME)
    }

    var body: some View {
        List {
            if isIndexed {
                ForEach(SectionIndex.sections(artists, name: \.name)) { section in
                    Section {
                        rows(section.items)
                    }
                    .sectionIndexLabel(section.letter)
                }
            } else {
                rows(artists)
            }

            if hasMore, !artists.isEmpty, !hasFailed {
                LoadMoreRow(loadedCount: artists.count, load: loadMore)
            }
        }
        .listStyle(.plain)
        .navigationTitle("Artists")
        .refreshable { await refresh() }
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                SortMenu(options: SortOptions.artists, field: currentSort.field, order: currentSort.order) { field, order in
                    sort = SortSetting(field: field, order: order)
                    Task { await refresh() }
                }
            }
        }
        .overlay {
            ListStateOverlay(isEmpty: artists.isEmpty, isLoading: isLoading, hasFailed: hasFailed, retry: retry) {
                ContentUnavailableView("No Artists", systemImage: "music.microphone")
            }
        }
        .artistEditSheet($editingArtist)
        .task {
            for await next in store.items { artists = next }
        }
        .task {
            for await next in store.hasMore { hasMore = next.boolValue }
        }
        .task {
            if artists.isEmpty { await loadMore() }
        }
    }

    private func rows(_ artists: [Artist]) -> some View {
        ForEach(artists, id: \.id) { artist in
            ArtistRow(artist: artist) { editingArtist = artist }
        }
    }

    private func loadMore() async {
        guard !isLoading else { return }
        isLoading = true
        defer { isLoading = false }
        do {
            try await store.loadMore()
            hasFailed = false
        } catch {
            hasFailed = true
        }
    }

    private func refresh() async {
        do {
            try await store.refresh(sortField: currentSort.field, sortOrder: currentSort.order)
            hasFailed = false
        } catch {
            hasFailed = artists.isEmpty
        }
    }

    private func retry() {
        hasFailed = false
        Task { await loadMore() }
    }
}

private struct ArtistRow: View {
    let artist: Artist
    let onEdit: () -> Void

    @Environment(AppModel.self) private var app

    var body: some View {
        NavigationLink(value: Route.artist(id: artist.id)) {
            HStack(spacing: 12) {
                Artwork(url: artist.imageUrl, size: 44, isCircle: true)
                Text(artist.name).lineLimit(1)
            }
        }
        .contextMenu {
            ArtistMenu(artist: artist, onEdit: onEdit)
        } preview: {
            ArtworkCard(artworkUrl: artist.imageUrl, title: artist.name, size: 240, isCircular: true)
                .padding()
        }
        .swipeActions(edge: .trailing) {
            Button("Play Last", systemImage: "text.line.last.and.arrowtriangle.forward") {
                CollectionQueueActions.artist(artist, app: app).playLast()
            }
            .tint(.purple)
        }
    }
}
