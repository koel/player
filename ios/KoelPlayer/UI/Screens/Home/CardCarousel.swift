@preconcurrency import Shared
import SwiftUI

/// A titled, horizontally scrolling row of cards, like Apple Music's shelves.
struct CardCarousel<Cards: View>: View {
    let title: String
    var seeAll: Route?
    @ViewBuilder var cards: () -> Cards

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            header
                .padding(.horizontal)

            ScrollView(.horizontal) {
                LazyHStack(alignment: .top, spacing: 16) {
                    cards()
                }
                .scrollTargetLayout()
            }
            .contentMargins(.horizontal, 16, for: .scrollContent)
            .scrollTargetBehavior(.viewAligned)
            .scrollIndicators(.hidden)
        }
    }

    @ViewBuilder
    private var header: some View {
        if let seeAll {
            NavigationLink(value: seeAll) {
                HStack(spacing: 4) {
                    Text(title)
                    Image(systemName: "chevron.forward")
                        .foregroundStyle(.secondary)
                        .imageScale(.small)
                }
                .font(.title3.bold())
            }
            .buttonStyle(.plain)
            .accessibilityHint("Shows all")
        } else {
            Text(title).font(.title3.bold())
        }
    }
}

enum CarouselCardSize {
    static let standard: CGFloat = 144
}

struct CarouselSongCard: View {
    let playable: any Playable

    @Environment(AppModel.self) private var app

    var body: some View {
        Button {
            app.player.play(playable)
        } label: {
            ArtworkCard(artworkUrl: playable.artworkUrl, title: playable.title, subtitle: playable.subtitle, size: CarouselCardSize.standard)
        }
        .buttonStyle(.plain)
        .contextMenu {
            PlayableMenu(playable: playable)
        }
    }
}

struct CarouselAlbumCard: View {
    let album: Album

    var body: some View {
        NavigationLink(value: Route.album(id: album.id)) {
            ArtworkCard(artworkUrl: album.cover, title: album.name, subtitle: album.artistName, size: CarouselCardSize.standard)
        }
        .buttonStyle(.plain)
    }
}

struct CarouselArtistCard: View {
    let artist: Artist

    var body: some View {
        NavigationLink(value: Route.artist(id: artist.id)) {
            ArtworkCard(artworkUrl: artist.imageUrl, title: artist.name, size: CarouselCardSize.standard, isCircular: true)
        }
        .buttonStyle(.plain)
    }
}

struct CarouselPodcastCard: View {
    let podcast: Podcast

    var body: some View {
        NavigationLink(value: Route.podcast(id: podcast.id)) {
            ArtworkCard(artworkUrl: podcast.imageUrl, title: podcast.title, subtitle: podcast.author, size: CarouselCardSize.standard)
        }
        .buttonStyle(.plain)
    }
}

struct CarouselRadioStationCard: View {
    let station: RadioStation

    @Environment(AppModel.self) private var app

    var body: some View {
        Button {
            Task {
                do {
                    try await app.core.player.playRadio(station: station)
                } catch {
                    app.toasts.showError("Couldn't play this station")
                }
            }
        } label: {
            ArtworkCard(artworkUrl: station.logo, title: station.name, size: CarouselCardSize.standard)
        }
        .buttonStyle(.plain)
    }
}
