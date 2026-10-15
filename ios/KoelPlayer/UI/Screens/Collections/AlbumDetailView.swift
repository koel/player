@preconcurrency import Shared
import SwiftUI

struct AlbumDetailView: View {
    let albumId: String

    @Environment(AppModel.self) private var app
    @State private var album: Album?
    @State private var songs: [any Playable] = []
    @State private var info: AlbumInfo?
    @State private var sort = SortSetting.remembered(for: Self.sortKey, default: SortSetting(field: PlayableSortField.shared.TRACK, order: .asc))
    @State private var query = ""
    @State private var hasFailed = false
    @State private var editingAlbum: Album?

    private static let sortKey = "album.sort"

    private var displayedSongs: [any Playable] {
        SortingKt.filtered(SortingKt.sorted(songs, field: sort.field, order: sort.order), keywords: query)
    }

    var body: some View {
        List {
            if let album {
                CollectionHeader(
                    artworkUrl: album.cover,
                    title: album.name,
                    subtitle: album.artistName,
                    detail: CollectionSummary.detail(year: album.year?.int32Value, songs: songs),
                    playables: displayedSongs
                )
                .listRowSeparator(.hidden)

                PlayableListContent(playables: displayedSongs, style: .album)

                AboutSection(title: "About", html: info?.information ?? "")
            }
        }
        .listStyle(.plain)
        .navigationTitle(album?.name ?? "")
        .navigationBarTitleDisplayMode(.inline)
        .searchable(text: $query, prompt: "Filter Songs")
        .refreshable { await load(forceRefresh: true) }
        .toolbar {
            if let album {
                CollectionToolbar(
                    isFavorite: album.favorite,
                    toggleFavorite: { try await app.core.albums.toggleFavorite(album: album) },
                    sortOptions: SortOptions.albumSongs,
                    sort: $sort,
                    sortKey: Self.sortKey
                ) {
                    AlbumMenu(album: album) { editingAlbum = album }
                }
            }
        }
        .overlay {
            if album == nil {
                if hasFailed {
                    LoadFailedView { Task { await load() } }
                } else {
                    ProgressView()
                }
            }
        }
        .albumEditSheet($editingAlbum)
        .collect(app.core.albums.observe(id: albumId), id: albumId) { album = $0 }
        .collect(app.core.playables.albumSongs(albumId: albumId), id: albumId) { songs = $0 }
        .task(id: albumId) { await load() }
        .task(id: albumId) { info = try? await app.core.mediaInfo.fetchForAlbum(albumId: albumId) }
    }

    private func load(forceRefresh: Bool = false) async {
        do {
            async let resolvedAlbum = app.core.albums.resolve(id: albumId, forceRefresh: forceRefresh)
            async let fetchedSongs = app.core.playables.fetchForAlbum(albumId: albumId, forceRefresh: forceRefresh)
            _ = try await (resolvedAlbum, fetchedSongs)
            hasFailed = false
        } catch {
            hasFailed = true
        }
    }
}
