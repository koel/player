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
    @State private var loadState = LoadState()
    @State private var editingAlbum: Album?

    private static let sortKey = "album.sort"

    private var displayedSongs: [any Playable] {
        SortingKt.filtered(SortingKt.sorted(songs, field: sort.field, order: sort.order), keywords: query)
    }

    var body: some View {
        let displayedSongs = displayedSongs

        CollectionDetailList(
            title: album?.name ?? "",
            artworkUrl: album?.cover,
            header: album.map { album in
                CollectionHeader(
                    artworkUrl: album.cover,
                    title: album.name,
                    subtitle: album.artistName,
                    subtitleAction: album.hasBrowsableArtist ? { app.navigator.push(.artist(id: album.artistId)) } : nil,
                    detail: CollectionSummary.detail(year: album.year?.int32Value, songs: displayedSongs),
                    favorite: FavoriteToggle(isFavorite: album.favorite) { try await app.core.albums.toggleFavorite(album: album) },
                    playables: displayedSongs
                )
            },
            songs: songs,
            displayedSongs: displayedSongs,
            query: $query,
            loadState: loadState,
            style: .album,
            retry: { Task { await load() } },
            refresh: { await load(forceRefresh: true) }
        ) {
            ContentUnavailableView("No songs", systemImage: "music.note")
        } footer: {
            AboutSection(title: "About", html: info?.information ?? "")
                .padding(.top, SectionHeader.sectionGap)
                .brandListRow()
        }
        .toolbar {
            if let album {
                SortToolbarItem(options: SortOptions.albumSongs, sort: sort, rememberKey: Self.sortKey) { sort = $0 }
                MoreMenuToolbarItem {
                    AlbumMenu(album: album) { editingAlbum = album }
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
        await loadState.load {
            async let resolvedAlbum = app.core.albums.resolve(id: albumId, forceRefresh: forceRefresh)
            async let fetchedSongs = app.core.playables.fetchForAlbum(albumId: albumId, forceRefresh: forceRefresh)
            _ = try await (resolvedAlbum, fetchedSongs)
        }
    }
}
