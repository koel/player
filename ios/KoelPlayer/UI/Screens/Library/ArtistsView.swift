@preconcurrency import Shared
import SwiftUI

struct ArtistsView: View {
    @Environment(AppModel.self) private var app
    @State private var artists: [Artist] = []
    @State private var hasMore = true
    @State private var sort: SortSetting?
    @State private var loadState = LoadState()
    @State private var editingArtist: Artist?

    private static let sortKey = "artists.sort"

    private var store: ArtistStore { app.core.artists }

    private var currentSort: SortSetting {
        sort ?? SortSetting.remembered(for: Self.sortKey, default: SortSetting(field: store.sortField, order: store.sortOrder))
    }

    private var isIndexed: Bool {
        SectionIndex.isShown(itemCount: artists.count, isSortedByName: currentSort.field == ArtistSortField.shared.NAME)
    }

    var body: some View {
        List {
            Group {
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

                NextPageRow(hasMore: hasMore, loadedCount: artists.count, loadState: loadState, load: loadMore)
            }
            .brandListRow()
        }
        .listStyle(.plain)
        .navigationTitle("Artists")
        .brandMeshBackground()
        .refreshable { await refresh() }
        .toolbar {
            SortToolbarItem(options: SortOptions.artists, sort: currentSort, rememberKey: Self.sortKey) { setting in
                sort = setting
                Task { await refresh() }
            }
        }
        .overlay {
            ListStateOverlay(isEmpty: artists.isEmpty, loadState: loadState, retry: { Task { await loadMore() } }) {
                ContentUnavailableView("No artists", systemImage: "music.microphone")
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
            if store.items.value.isEmpty { await refresh() }
        }
    }

    private func rows(_ artists: [Artist]) -> some View {
        ForEach(artists, id: \.id) { artist in
            ArtistRow(artist: artist) { editingArtist = artist }
        }
    }

    private func loadMore() async {
        await loadState.load { try await store.loadMore() }
    }

    private func refresh() async {
        await loadState.refresh(hasItems: !artists.isEmpty) {
            try await store.refresh(sortField: currentSort.field, sortOrder: currentSort.order)
        }
    }
}

private struct ArtistRow: View {
    let artist: Artist
    let onEdit: () -> Void

    @Environment(AppModel.self) private var app

    var body: some View {
        NavigationLink(value: Route.artist(id: artist.id)) {
            MediaRow(title: artist.name) {
                Artwork(url: artist.imageUrl, size: 44, isCircle: true)
            }
        }
        .contextMenu {
            ArtistMenu(artist: artist, onEdit: onEdit)
        } preview: {
            ArtistPreview(artist: artist)
        }
        .swipeActions(edge: .trailing) {
            PlayLastSwipeButton {
                CollectionQueueActions.artist(artist, app: app).playLast()
            }
        }
    }
}
