@preconcurrency import Shared
import SwiftUI

struct ArtistDetailView: View {
    let artistId: String

    @Environment(AppModel.self) private var app
    @State private var artist: Artist?
    @State private var songs: [any Playable] = []
    @State private var biography = ""
    @State private var sort = SortSetting.remembered(for: Self.sortKey, default: SortSetting(field: PlayableSortField.shared.TITLE, order: .asc))
    @State private var hasFailed = false
    @State private var editingArtist: Artist?
    @State private var coverColor: Color?
    @State private var isBannerScrolledAway = false

    private static let sortKey = "artist.sort"

    private var displayedSongs: [any Playable] {
        SortingKt.sorted(songs, field: sort.field, order: sort.order)
    }

    var body: some View {
        ScrollView {
            if let artist {
                VStack(alignment: .leading, spacing: 0) {
                    ArtistBanner(artist: artist, songs: displayedSongs)

                    if let summary = CollectionSummary.detail(songs: songs) {
                        Text(summary)
                            .font(.footnote)
                            .foregroundStyle(.secondary)
                            .padding(.horizontal)
                            .padding(.bottom, 8)
                    }

                    LazyVStack(spacing: 0) {
                        ForEach(displayedSongs, id: \.id) { playable in
                            PlayableRow(playable: playable, style: .artist)
                                .padding(.horizontal)
                                .padding(.vertical, 6)
                            Divider().padding(.leading, 72)
                        }
                    }

                    AboutSection(title: "About", html: biography)
                        .padding()
                }
            }
        }
        .ignoresSafeArea(edges: .top)
        .background { CoverBackground(color: coverColor) }
        .tint(coverColor ?? .primary)
        .navigationTitle(isBannerScrolledAway ? artist?.name ?? "" : "")
        .navigationBarTitleDisplayMode(.inline)
        .toolbarBackgroundVisibility(.hidden, for: .navigationBar)
        .onScrollGeometryChange(for: Bool.self) { geometry in
            geometry.contentOffset.y > geometry.containerSize.width - 80
        } action: { _, scrolledAway in
            isBannerScrolledAway = scrolledAway
        }
        .refreshable { await load(forceRefresh: true) }
        .toolbar {
            if let artist {
                CollectionToolbar(
                    isFavorite: artist.favorite,
                    toggleFavorite: { try await app.core.artists.toggleFavorite(artist: artist) },
                    sortOptions: SortOptions.artistSongs,
                    sort: $sort,
                    sortKey: Self.sortKey
                ) {
                    ArtistMenu(artist: artist) { editingArtist = artist }
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
        .artistEditSheet($editingArtist)
        .collect(app.core.artists.observe(id: artistId), id: artistId) { artist = $0 }
        .collect(app.core.playables.artistSongs(artistId: artistId), id: artistId) { songs = $0 }
        .task(id: artistId) { await load() }
        .task(id: artistId) {
            biography = (try? await app.core.mediaInfo.fetchForArtist(artistId: artistId).biography) ?? ""
        }
        .task(id: artist?.imageUrl) { coverColor = await CoverColor.of(artist?.imageUrl) }
    }

    private func load(forceRefresh: Bool = false) async {
        do {
            async let resolvedArtist = app.core.artists.resolve(id: artistId, forceRefresh: forceRefresh)
            async let fetchedSongs = app.core.playables.fetchForArtist(artistId: artistId, forceRefresh: forceRefresh)
            _ = try await (resolvedArtist, fetchedSongs)
            hasFailed = false
        } catch {
            hasFailed = true
        }
    }
}

/// The artist's photo across the full width, fading into the page, with the name on top.
private struct ArtistBanner: View {
    let artist: Artist
    let songs: [any Playable]

    @Environment(AppModel.self) private var app
    @State private var image: UIImage?

    var body: some View {
        ZStack(alignment: .bottomLeading) {
            photo
                .containerRelativeFrame(.horizontal)
                .aspectRatio(1, contentMode: .fit)
                .clipped()
                .mask {
                    LinearGradient(stops: [.init(color: .black, location: 0.55), .init(color: .clear, location: 1)], startPoint: .top, endPoint: .bottom)
                }

            HStack(alignment: .bottom) {
                Text(artist.name)
                    .font(.largeTitle.bold())
                    .lineLimit(2)
                    .shadow(color: .black.opacity(0.5), radius: 8)

                Spacer(minLength: 16)

                Button {
                    app.player.play(songs)
                } label: {
                    Image(systemName: "play.fill")
                        .font(.title2)
                        .frame(width: 52, height: 52)
                }
                .buttonStyle(.glassProminent)
                .buttonBorderShape(.circle)
                .disabled(songs.isEmpty)
                .accessibilityLabel("Play")
            }
            .padding(.horizontal)
            .padding(.bottom, 8)
        }
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
}
