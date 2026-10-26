@preconcurrency import Shared
import SwiftUI

struct ArtistDetailView: View {
    let artistId: String

    @Environment(AppModel.self) private var app
    @State private var artist: Artist?
    @State private var songs: [any Playable] = []
    @State private var biography = ""
    @State private var loadState = LoadState()
    @State private var editingArtist: Artist?

    private static let topSongCount = 5

    private var topSongs: [any Playable] {
        Array(songs.sorted { $0.playCount > $1.playCount }.prefix(Self.topSongCount))
    }

    var body: some View {
        ScrollView {
            if let artist {
                VStack(alignment: .leading, spacing: SectionHeader.sectionGap) {
                    ArtistHero(artist: artist, songs: songs)

                    PlayableSection(
                        title: "Top Songs",
                        destination: .artistSongs(id: artistId),
                        playables: topSongs,
                        style: .artist,
                        isLoading: songs.isEmpty && loadState.isPending,
                        placeholderCount: Self.topSongCount
                    )

                    ArtistAlbumsShelf(songs: songs)

                    AboutSection(title: "About", html: biography)
                }
                .padding(.bottom)
            } else {
                ListStateOverlay(isEmpty: true, loadState: loadState, retry: { Task { await load() } }) {
                    ContentUnavailableView("No artist", systemImage: "music.microphone")
                }
                .containerRelativeFrame([.horizontal, .vertical])
            }
        }
        .collectionScreen(
            title: artist?.name ?? "",
            artworkUrl: artist?.imageUrl,
            headerHeight: { $0.containerSize.width },
            extendsUnderNavigationBar: true
        )
        .refreshable { await load(forceRefresh: true) }
        .toolbar {
            if let artist {
                MoreMenuToolbarItem {
                    ArtistMenu(artist: artist) { editingArtist = artist }
                }
            }
        }
        .artistEditSheet($editingArtist)
        .collect(app.core.artists.observe(id: artistId), id: artistId) { artist = $0 }
        .collect(app.core.playables.artistSongs(artistId: artistId), id: artistId) { songs = $0 }
        .task(id: artistId) { await load() }
        .task(id: artistId) {
            biography = (try? await app.core.mediaInfo.fetchForArtist(artistId: artistId).biography) ?? ""
        }
    }

    private func load(forceRefresh: Bool = false) async {
        await loadState.load {
            async let resolvedArtist = app.core.artists.resolve(id: artistId, forceRefresh: forceRefresh)
            async let fetchedSongs = app.core.playables.fetchForArtist(artistId: artistId, forceRefresh: forceRefresh)
            _ = try await (resolvedArtist, fetchedSongs)
        }
    }
}

/// The artist's photo across the full width, fading into the page, with the name and actions centered below.
private struct ArtistHero: View {
    let artist: Artist
    let songs: [any Playable]

    @Environment(AppModel.self) private var app

    private static let overlap: CGFloat = 96

    var body: some View {
        VStack(spacing: 20) {
            ArtworkImage(url: artist.imageUrl, pointSize: 430)
                .containerRelativeFrame(.horizontal)
                .aspectRatio(1, contentMode: .fit)
                .clipped()
                .mask {
                    LinearGradient(stops: [.init(color: .black, location: 0.6), .init(color: .clear, location: 1)], startPoint: .top, endPoint: .bottom)
                }
                .padding(.bottom, -Self.overlap)
                .accessibilityHidden(true)

            Text(artist.name)
                .font(.largeTitle.bold())
                .multilineTextAlignment(.center)
                .lineLimit(2)
                .shadow(color: .black.opacity(0.5), radius: 8)
                .padding(.horizontal)

            CollectionActions(
                favorite: FavoriteToggle(isFavorite: artist.favorite) { try await app.core.artists.toggleFavorite(artist: artist) },
                playables: songs
            )
        }
        .frame(maxWidth: .infinity)
    }
}

/// The artist's albums, gathered from their songs, newest first.
private struct ArtistAlbumsShelf: View {
    let songs: [any Playable]

    private var albums: [ArtistAlbumSummary] {
        var seen = Set<String>()
        return songs
            .compactMap { $0 as? Song }
            .filter { !$0.albumId.isEmpty && seen.insert($0.albumId).inserted }
            .map { ArtistAlbumSummary(id: $0.albumId, name: $0.albumName, cover: $0.albumCover, year: $0.year?.intValue) }
            .sorted { ($0.year ?? 0) > ($1.year ?? 0) }
    }

    var body: some View {
        let albums = albums
        if !albums.isEmpty {
            CardCarousel(title: "Albums") {
                ForEach(albums) { ArtistAlbumCard(summary: $0) }
            }
        }
    }
}

private struct ArtistAlbumSummary: Identifiable {
    let id: String
    let name: String
    let cover: String?
    let year: Int?
}

/// An album on the artist's shelf. The artist's songs only carry the album's name and cover, so the
/// album itself loads when a long press starts, in time for its menu.
private struct ArtistAlbumCard: View {
    let summary: ArtistAlbumSummary

    @Environment(AppModel.self) private var app
    @State private var album: Album?

    var body: some View {
        NavigationLink(value: Route.album(id: summary.id)) {
            ArtworkCard(artworkUrl: summary.cover, title: summary.name, subtitle: summary.year.map(String.init), size: CarouselCardSize.standard)
        }
        .buttonStyle(.plain)
        .simultaneousGesture(LongPressGesture(minimumDuration: 0.1).onEnded { _ in loadAlbum() })
        .contextMenu {
            if let album {
                AlbumMenu(album: album)
            } else {
                Text("Loading…")
            }
        } preview: {
            ContextMenuPreview(title: summary.name, subtitle: summary.year.map(String.init), artworkUrl: summary.cover)
        }
        .collect(app.core.albums.observe(id: summary.id), id: summary.id) { album = $0 }
    }

    private func loadAlbum() {
        guard album == nil else { return }
        Task { _ = try? await app.core.albums.resolve(id: summary.id, forceRefresh: false) }
    }
}
