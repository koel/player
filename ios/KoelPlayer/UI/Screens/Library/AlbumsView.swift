@preconcurrency import Shared
import SwiftUI

struct AlbumsView: View {
    @Environment(AppModel.self) private var app
    @State private var albums: [Album] = []
    @State private var hasMore = true
    @State private var sort: SortSetting?
    @State private var loadState = LoadState()
    @State private var containerWidth: CGFloat = 0
    @State private var editingAlbum: Album?
    @State private var layout = CollectionLayout.remembered(for: Self.layoutKey)

    private static let sortKey = "albums.sort"
    private static let layoutKey = "albums"

    private var store: AlbumStore { app.core.albums }

    private var currentSort: SortSetting {
        sort ?? SortSetting.remembered(for: Self.sortKey, default: SortSetting(field: store.sortField, order: store.sortOrder))
    }

    private var isIndexed: Bool {
        SectionIndex.isShown(itemCount: albums.count, isSortedByName: currentSort.field == AlbumSortField.shared.NAME)
    }

    private var isSortedByYear: Bool { currentSort.field == AlbumSortField.shared.YEAR }

    private var grid: some View {
        let gridLayout = GridLayout(containerWidth: containerWidth)

        return ScrollViewReader { scroller in
            ScrollView {
                AlbumGrid(albums: albums, layout: gridLayout, showsYear: isSortedByYear) { editingAlbum = $0 }
                    .padding(.vertical, gridLayout.padding)

                NextPageRow(hasMore: hasMore, loadedCount: albums.count, loadState: loadState, load: loadMore)
                    .padding()
            }
            .overlay(alignment: .trailing) {
                if isIndexed {
                    let sections = SectionIndex.sections(albums, name: \.name)
                    AlphabetIndexBar(letters: sections.map(\.letter)) { letter in
                        guard let first = sections.first(where: { $0.letter == letter })?.items.first else { return }
                        scroller.scrollTo(first.id, anchor: .top)
                    }
                }
            }
        }
    }

    private var list: some View {
        List {
            Group {
                if isIndexed {
                    ForEach(SectionIndex.sections(albums, name: \.name)) { section in
                        Section {
                            rows(section.items)
                        }
                        .sectionIndexLabel(section.letter)
                    }
                } else {
                    rows(albums)
                }

                NextPageRow(hasMore: hasMore, loadedCount: albums.count, loadState: loadState, load: loadMore)
            }
            .brandListRow()
        }
        .listStyle(.plain)
    }

    private func rows(_ albums: [Album]) -> some View {
        ForEach(albums, id: \.id) { album in
            AlbumRow(album: album, showsYear: isSortedByYear) { editingAlbum = album }
        }
    }

    var body: some View {
        Group {
            switch layout {
            case .grid: grid
            case .list: list
            }
        }
        .onGeometryChange(for: CGFloat.self, of: \.size.width) { containerWidth = $0 }
        .navigationTitle("Albums")
        .brandMeshBackground()
        .refreshable { await refresh() }
        .toolbar {
            SortToolbarItem(options: SortOptions.albums, sort: currentSort, rememberKey: Self.sortKey, layout: $layout) { setting in
                sort = setting
                Task { await refresh() }
            }
        }
        .overlay {
            ListStateOverlay(isEmpty: albums.isEmpty, loadState: loadState, retry: { Task { await loadMore() } }) {
                ContentUnavailableView("No albums", systemImage: "square.stack")
            }
        }
        .albumEditSheet($editingAlbum)
        .onChange(of: layout) { _, newLayout in newLayout.remember(for: Self.layoutKey) }
        .task {
            for await next in store.items { albums = next }
        }
        .task {
            for await next in store.hasMore { hasMore = next.boolValue }
        }
        .task {
            if store.items.value.isEmpty { await refresh() }
        }
    }

    private func loadMore() async {
        await loadState.load { try await store.loadMore() }
    }

    private func refresh() async {
        await loadState.refresh(hasItems: !albums.isEmpty) {
            try await store.refresh(sortField: currentSort.field, sortOrder: currentSort.order)
        }
    }
}

/// Flutter's albums list row: a small cover, the album and its artist, and the year when sorted by it.
private struct AlbumRow: View {
    let album: Album
    let showsYear: Bool
    let onEdit: () -> Void

    @Environment(AppModel.self) private var app

    var body: some View {
        NavigationLink(value: Route.album(id: album.id)) {
            HStack {
                MediaRow(title: album.name, subtitle: album.artistName) {
                    Artwork(url: album.cover, size: 40)
                }
                if showsYear, let year = album.year {
                    Spacer()
                    Text(String(year.intValue))
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                }
            }
        }
        .contextMenu {
            AlbumMenu(album: album, onEdit: onEdit)
        } preview: {
            AlbumPreview(album: album)
        }
        .swipeActions(edge: .leading) {
            QueueSwipeButton {
                CollectionQueueActions.album(album, app: app).playLast()
            }
        }
    }
}

/// Pushes with a button rather than a NavigationLink, which would get a List row's disclosure chevron inside the Library.
struct AlbumGridCard: View {
    let album: Album
    let size: CGFloat
    let showsYear: Bool
    let onEdit: () -> Void

    @Environment(AppModel.self) private var app

    private var subtitle: String {
        guard showsYear, let year = album.year else { return album.artistName }
        return "\(album.artistName) · \(year.intValue)"
    }

    var body: some View {
        Button {
            app.navigator.push(.album(id: album.id))
        } label: {
            ArtworkCard(artworkUrl: album.cover, title: album.name, subtitle: subtitle, size: size)
        }
        .buttonStyle(.plain)
        .contextMenu {
            AlbumMenu(album: album, onEdit: onEdit)
        } preview: {
            AlbumPreview(album: album)
        }
    }
}
