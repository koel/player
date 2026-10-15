@preconcurrency import Shared
import SwiftUI

struct AlbumsView: View {
    @Environment(AppModel.self) private var app
    @State private var albums: [Album] = []
    @State private var hasMore = true
    @State private var sort: SortSetting?
    @State private var isLoading = false
    @State private var hasFailed = false
    @State private var containerWidth: CGFloat = 0
    @State private var editingAlbum: Album?

    private var store: AlbumStore { app.core.albums }

    private var currentSort: SortSetting {
        sort ?? SortSetting(field: store.sortField, order: store.sortOrder)
    }

    var body: some View {
        let layout = GridLayout(containerWidth: containerWidth)

        ScrollView {
            LazyVGrid(
                columns: Array(repeating: GridItem(.fixed(layout.cardSize), spacing: layout.spacing), count: layout.columnCount),
                spacing: 20
            ) {
                ForEach(albums, id: \.id) { album in
                    AlbumGridCard(album: album, size: layout.cardSize, showsYear: currentSort.field == AlbumSortField.shared.YEAR) {
                        editingAlbum = album
                    }
                }
            }
            .padding(layout.padding)

            if hasMore, !albums.isEmpty, !hasFailed {
                ProgressView()
                    .padding()
                    .task(id: albums.count) { await loadMore() }
            }
        }
        .onGeometryChange(for: CGFloat.self, of: \.size.width) { containerWidth = $0 }
        .navigationTitle("Albums")
        .refreshable { await refresh() }
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                SortMenu(options: SortOptions.albums, field: currentSort.field, order: currentSort.order) { field, order in
                    sort = SortSetting(field: field, order: order)
                    Task { await refresh() }
                }
            }
        }
        .overlay {
            ListStateOverlay(isEmpty: albums.isEmpty, isLoading: isLoading, hasFailed: hasFailed, retry: retry) {
                ContentUnavailableView("No Albums", systemImage: "square.stack")
            }
        }
        .albumEditSheet($editingAlbum)
        .task {
            for await next in store.items { albums = next }
        }
        .task {
            for await next in store.hasMore { hasMore = next.boolValue }
        }
        .task {
            if albums.isEmpty { await loadMore() }
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
            hasFailed = albums.isEmpty
        }
    }

    private func retry() {
        hasFailed = false
        Task { await loadMore() }
    }
}

private struct AlbumGridCard: View {
    let album: Album
    let size: CGFloat
    let showsYear: Bool
    let onEdit: () -> Void

    private var subtitle: String {
        guard showsYear, let year = album.year else { return album.artistName }
        return "\(album.artistName) · \(year.intValue)"
    }

    var body: some View {
        NavigationLink(value: Route.album(id: album.id)) {
            ArtworkCard(artworkUrl: album.cover, title: album.name, subtitle: subtitle, size: size)
        }
        .buttonStyle(.plain)
        .contextMenu {
            AlbumMenu(album: album, onEdit: onEdit)
        } preview: {
            ArtworkCard(artworkUrl: album.cover, title: album.name, subtitle: album.artistName, size: 240)
                .padding()
        }
    }
}
