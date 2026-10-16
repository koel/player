@preconcurrency import Shared
import SwiftUI

struct ArtistDetailView: View {
    let artistId: String

    @Environment(AppModel.self) private var app
    @State private var artist: Artist?
    @State private var songs: [any Playable] = []
    @State private var biography = ""
    @State private var hasFailed = false
    @State private var hasLoadedSongs = false
    @State private var editingArtist: Artist?
    @State private var coverColor: Color?
    @State private var isHeroScrolledAway = false
    @State private var isShowingBiography = false

    private static let topSongCount = 5

    private var topSongs: [any Playable] {
        Array(songs.sorted { $0.playCount > $1.playCount }.prefix(Self.topSongCount))
    }

    var body: some View {
        ScrollView {
            if let artist {
                VStack(alignment: .leading, spacing: 28) {
                    ArtistHero(artist: artist, songs: songs, hasBiography: !biography.plainText.isBlank) {
                        isShowingBiography = true
                    }

                    topSongsSection

                    ArtistAlbumsShelf(songs: songs)

                    AboutSection(title: "About", html: biography)
                        .padding(.horizontal)
                }
                .padding(.bottom)
            }
        }
        .ignoresSafeArea(edges: .top)
        .background { CoverBackground(color: coverColor) }
        .tint(coverColor ?? .primary)
        .navigationTitle(isHeroScrolledAway ? artist?.name ?? "" : "")
        .navigationBarTitleDisplayMode(.inline)
        .toolbarBackgroundVisibility(.hidden, for: .navigationBar)
        .onScrollGeometryChange(for: Bool.self) { geometry in
            geometry.contentOffset.y > geometry.containerSize.width
        } action: { _, scrolledAway in
            isHeroScrolledAway = scrolledAway
        }
        .refreshable { await load(forceRefresh: true) }
        .toolbar {
            if let artist {
                ToolbarItem(placement: .primaryAction) {
                    Menu("More", systemImage: "ellipsis") {
                        ArtistMenu(artist: artist) { editingArtist = artist }
                    }
                }
            }
        }
        .overlay {
            if artist == nil {
                if hasFailed {
                    LoadFailedView { Task { await load() } }
                } else {
                    ProgressView()
                }
            }
        }
        .sheet(isPresented: $isShowingBiography) {
            BiographySheet(name: artist?.name ?? "", biography: biography)
        }
        .artistEditSheet($editingArtist)
        .collect(app.core.artists.observe(id: artistId), id: artistId) { artist = $0 }
        .collect(app.core.playables.artistSongs(artistId: artistId), id: artistId) { songs = $0 }
        .task(id: artistId) { await load() }
        .task(id: artistId) {
            biography = (try? await app.core.mediaInfo.fetchForArtist(artistId: artistId).biography) ?? ""
        }
        .task(id: artist?.imageUrl) { coverColor = await CoverColor.of(artist?.imageUrl) }
    }

    private var topSongsSection: some View {
        VStack(alignment: .leading, spacing: 4) {
            NavigationLink(value: Route.artistSongs(id: artistId)) {
                HStack(spacing: 4) {
                    Text("Top Songs")
                    Image(systemName: "chevron.forward")
                        .foregroundStyle(.secondary)
                        .imageScale(.small)
                }
                .font(.title3.bold())
            }
            .buttonStyle(.plain)
            .accessibilityHint("Shows all songs")
            .padding(.horizontal)

            LazyVStack(spacing: 0) {
                if songs.isEmpty, !hasLoadedSongs, !hasFailed {
                    LoadingRows(count: Self.topSongCount)
                        .padding(.horizontal)
                        .padding(.vertical, 6)
                }

                ForEach(topSongs, id: \.id) { playable in
                    PlayableRow(playable: playable, style: .artist)
                        .padding(.horizontal)
                        .padding(.vertical, 6)
                    Divider().padding(.leading, 72)
                }
            }
        }
    }

    private func load(forceRefresh: Bool = false) async {
        do {
            async let resolvedArtist = app.core.artists.resolve(id: artistId, forceRefresh: forceRefresh)
            async let fetchedSongs = app.core.playables.fetchForArtist(artistId: artistId, forceRefresh: forceRefresh)
            _ = try await (resolvedArtist, fetchedSongs)
            hasFailed = false
            hasLoadedSongs = true
        } catch {
            hasFailed = true
        }
    }
}

/// The artist's photo across the full width, fading into the page, with the name and actions centered below.
private struct ArtistHero: View {
    let artist: Artist
    let songs: [any Playable]
    let hasBiography: Bool
    let showBiography: () -> Void

    @Environment(AppModel.self) private var app
    @State private var image: UIImage?

    private static let overlap: CGFloat = 96

    var body: some View {
        VStack(spacing: 20) {
            photo
                .containerRelativeFrame(.horizontal)
                .aspectRatio(1, contentMode: .fit)
                .clipped()
                .mask {
                    LinearGradient(stops: [.init(color: .black, location: 0.6), .init(color: .clear, location: 1)], startPoint: .top, endPoint: .bottom)
                }
                .padding(.bottom, -Self.overlap)

            Text(artist.name)
                .font(.largeTitle.bold())
                .multilineTextAlignment(.center)
                .lineLimit(2)
                .shadow(color: .black.opacity(0.5), radius: 8)
                .padding(.horizontal)

            HStack(spacing: 28) {
                RoundIconButton(title: "About", systemImage: "info", action: showBiography)
                    .disabled(!hasBiography)

                Button {
                    app.player.play(songs)
                } label: {
                    Image(systemName: "play.fill")
                        .font(.title)
                        .foregroundStyle(.black)
                        .frame(width: 64, height: 64)
                }
                .buttonStyle(.glassProminent)
                .buttonBorderShape(.circle)
                .tint(.white)
                .disabled(songs.isEmpty)
                .accessibilityLabel("Play")

                if app.core.session.supports(feature: .favoriteEntities) {
                    RoundIconButton(title: artist.favorite ? "Undo Favorite" : "Favorite", systemImage: artist.favorite ? "star.fill" : "star", action: toggleFavorite)
                }
            }
            .controlSize(.large)
        }
        .frame(maxWidth: .infinity)
        .task(id: artist.imageUrl) {
            guard let url = artist.imageUrl.flatMap(URL.init(string:)) else { return }
            image = await ImagePipeline.shared.image(for: url, pointSize: 430)
        }
    }

    @ViewBuilder
    private var photo: some View {
        if let image {
            Image(uiImage: image).resizable().scaledToFill()
        } else {
            Image("default-image").resizable().scaledToFill()
        }
    }

    private func toggleFavorite() {
        Task {
            do {
                try await app.core.artists.toggleFavorite(artist: artist)
            } catch {
                app.toasts.showError()
            }
        }
    }
}

/// The artist's albums, gathered from their songs, newest first.
private struct ArtistAlbumsShelf: View {
    let songs: [any Playable]

    private struct AlbumSummary: Identifiable {
        let id: String
        let name: String
        let cover: String?
        let year: Int?
    }

    private var albums: [AlbumSummary] {
        var seen = Set<String>()
        return songs
            .compactMap { $0 as? Song }
            .filter { !$0.albumId.isEmpty && seen.insert($0.albumId).inserted }
            .map { AlbumSummary(id: $0.albumId, name: $0.albumName, cover: $0.albumCover, year: $0.year?.intValue) }
            .sorted { ($0.year ?? 0) > ($1.year ?? 0) }
    }

    var body: some View {
        let albums = albums
        if !albums.isEmpty {
            CardCarousel(title: "Albums") {
                ForEach(albums) { album in
                    NavigationLink(value: Route.album(id: album.id)) {
                        ArtworkCard(artworkUrl: album.cover, title: album.name, subtitle: album.year.map(String.init), size: CarouselCardSize.standard)
                    }
                    .buttonStyle(.plain)
                }
            }
        }
    }
}

private struct BiographySheet: View {
    let name: String
    let biography: String

    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            ScrollView {
                Text(biography.plainText)
                    .textSelection(.enabled)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding()
            }
            .navigationTitle(name)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done", systemImage: "checkmark") { dismiss() }
                }
            }
        }
        .presentationDetents([.medium, .large])
    }
}
