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
    @State private var hasLoadedSongs = false
    @State private var editingAlbum: Album?
    @State private var coverColor: Color?
    @State private var isHeaderScrolledAway = false

    private static let sortKey = "album.sort"

    private var displayedSongs: [any Playable] {
        SortingKt.filtered(SortingKt.sorted(songs, field: sort.field, order: sort.order), keywords: query)
    }

    var body: some View {
        List {
            if album == nil, !hasFailed {
                LoadingRows()
            }

            if let album {
                AlbumHeader(album: album, songs: displayedSongs, tint: coverColor)
                    .listRowSeparator(.hidden)
                    .listRowBackground(Color.clear)

                if songs.isEmpty, !hasLoadedSongs, !hasFailed {
                    LoadingRows(count: 6)
                        .listRowBackground(Color.clear)
                }

                PlayableListContent(playables: displayedSongs, style: .album)
                    .listRowBackground(Color.clear)

                AboutSection(title: "About", html: info?.information ?? "")
                    .listRowBackground(Color.clear)
            }
        }
        .listStyle(.plain)
        .scrollContentBackground(.hidden)
        .background { CoverBackground(color: coverColor) }
        .tint(coverColor ?? .primary)
        .navigationTitle(isHeaderScrolledAway ? album?.name ?? "" : "")
        .navigationBarTitleDisplayMode(.inline)
        .onScrollGeometryChange(for: Bool.self) { geometry in
            geometry.contentOffset.y + geometry.contentInsets.top > AlbumHeader.height
        } action: { _, scrolledAway in
            isHeaderScrolledAway = scrolledAway
        }
        .filterable(text: $query, prompt: "Filter Songs")
        .refreshable { await load(forceRefresh: true) }
        .toolbar {
            if let album {
                CollectionToolbar(
                    isFavorite: album.favorite,
                    toggleFavorite: { try await app.core.albums.toggleFavorite(album: album) },
                    sortOptions: SortOptions.albumSongs,
                    sort: $sort,
                    sortKey: Self.sortKey,
                    showsFavorite: false
                ) {
                    AlbumMenu(album: album) { editingAlbum = album }
                }
            }
        }
        .overlay {
            if album == nil {
                if hasFailed {
                    LoadFailedView { Task { await load() } }
                }
            }
        }
        .albumEditSheet($editingAlbum)
        .collect(app.core.albums.observe(id: albumId), id: albumId) { album = $0 }
        .collect(app.core.playables.albumSongs(albumId: albumId), id: albumId) { songs = $0 }
        .task(id: albumId) { await load() }
        .task(id: albumId) { info = try? await app.core.mediaInfo.fetchForAlbum(albumId: albumId) }
        .task(id: album?.cover) { coverColor = await CoverColor.of(album?.cover) }
    }

    private func load(forceRefresh: Bool = false) async {
        do {
            async let resolvedAlbum = app.core.albums.resolve(id: albumId, forceRefresh: forceRefresh)
            async let fetchedSongs = app.core.playables.fetchForAlbum(albumId: albumId, forceRefresh: forceRefresh)
            _ = try await (resolvedAlbum, fetchedSongs)
            hasFailed = false
            hasLoadedSongs = true
        } catch {
            hasFailed = true
        }
    }
}

private struct AlbumHeader: View {
    static let height: CGFloat = 360

    let album: Album
    let songs: [any Playable]
    let tint: Color?

    @Environment(AppModel.self) private var app

    var body: some View {
        VStack(spacing: 16) {
            Artwork(url: album.cover, size: 260, cornerRadius: 12)
                .shadow(color: .black.opacity(0.4), radius: 20, y: 10)

            VStack(spacing: 4) {
                Text(album.name)
                    .font(.title2.bold())
                    .multilineTextAlignment(.center)

                Button(album.artistName) {
                    app.navigator.push(.artist(id: album.artistId))
                }
                .font(.title3)
                .foregroundStyle(tint ?? .secondary)
                .disabled(app.isOffline || !album.hasBrowsableArtist)

                if let detail = CollectionSummary.detail(year: album.year?.int32Value, songs: songs) {
                    Text(detail)
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                }
            }

            AlbumActions(album: album, songs: songs, tint: tint)
        }
        .buttonStyle(.plain)
        .frame(maxWidth: .infinity)
        .padding(.vertical, 8)
    }
}

/// Favorite and Shuffle as round icon buttons flanking a prominent Play.
private struct AlbumActions: View {
    let album: Album
    let songs: [any Playable]
    let tint: Color?

    @Environment(AppModel.self) private var app

    var body: some View {
        HStack(spacing: 16) {
            if app.core.session.supports(feature: .favoriteEntities) {
                RoundIconButton(title: album.favorite ? "Undo Favorite" : "Favorite", systemImage: album.favorite ? "star.fill" : "star", action: toggleFavorite)
            }

            playButton

            RoundIconButton(title: "Shuffle", systemImage: "shuffle") {
                app.player.play(songs, shuffled: true)
            }
            .disabled(songs.isEmpty)
        }
        .controlSize(.large)
        .padding(.horizontal)
    }

    @ViewBuilder
    private var playButton: some View {
        let button = Button {
            app.player.play(songs)
        } label: {
            Label("Play", systemImage: "play.fill")
                .frame(maxWidth: .infinity)
        }
        .disabled(songs.isEmpty)

        if let tint {
            button.buttonStyle(.glassProminent).tint(tint)
        } else {
            button.buttonStyle(.glass).tint(.primary)
        }
    }

    private func toggleFavorite() {
        Task {
            do {
                try await app.core.albums.toggleFavorite(album: album)
            } catch {
                app.toasts.showError()
            }
        }
    }
}

private struct RoundIconButton: View {
    let title: String
    let systemImage: String
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Image(systemName: systemImage)
                .contentTransition(.symbolEffect(.replace))
                .frame(width: 24, height: 24)
        }
        .accessibilityLabel(title)
        .buttonStyle(.glass)
            .buttonBorderShape(.circle)
            .tint(.primary)
    }
}
