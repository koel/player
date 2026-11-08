@preconcurrency import Shared
import SwiftUI

/// A titled, horizontally scrolling row of cards, like Apple Music's shelves.
struct CardCarousel<Cards: View>: View {
    let title: String
    var seeAll: Route?
    @ViewBuilder var cards: () -> Cards

    var body: some View {
        VStack(alignment: .leading, spacing: SectionHeader.contentGap) {
            SectionHeader(title: title, destination: seeAll)

            ScrollView(.horizontal) {
                LazyHStack(alignment: .top, spacing: 16) {
                    cards()
                }
                .scrollTargetLayout()
            }
            .contentMargins(.horizontal, 16, for: .scrollContent)
            .scrollTargetBehavior(.viewAligned(limitBehavior: .never))
            .scrollIndicators(.hidden)
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
        } preview: {
            PlayablePreview(playable: playable)
        }
    }
}

struct CarouselAlbumCard: View {
    let album: Album

    @Environment(AppModel.self) private var app
    @State private var liveAlbum: Album?

    var body: some View {
        NavigationLink(value: Route.album(id: album.id)) {
            ArtworkCard(artworkUrl: album.cover, title: album.name, subtitle: album.artistName, size: CarouselCardSize.standard)
        }
        .buttonStyle(.plain)
        .contextMenu {
            AlbumMenu(album: liveAlbum ?? album)
        } preview: {
            AlbumPreview(album: album)
        }
        .collect(app.core.albums.observe(id: album.id), id: album.id) { liveAlbum = $0 }
    }
}

struct CarouselArtistCard: View {
    let artist: Artist

    @Environment(AppModel.self) private var app
    @State private var liveArtist: Artist?

    var body: some View {
        NavigationLink(value: Route.artist(id: artist.id)) {
            ArtworkCard(artworkUrl: artist.imageUrl, title: artist.name, size: CarouselCardSize.standard, isCircular: true)
        }
        .buttonStyle(.plain)
        .contextMenu {
            ArtistMenu(artist: liveArtist ?? artist)
        } preview: {
            ArtistPreview(artist: artist)
        }
        .collect(app.core.artists.observe(id: artist.id), id: artist.id) { liveArtist = $0 }
    }
}

struct CarouselPodcastCard: View {
    let podcast: Podcast

    @Environment(AppModel.self) private var app
    @State private var podcastPendingUnsubscribe: Podcast?

    var body: some View {
        NavigationLink(value: Route.podcast(id: podcast.id)) {
            ArtworkCard(artworkUrl: podcast.imageUrl, title: podcast.title, subtitle: podcast.author, size: CarouselCardSize.standard)
        }
        .buttonStyle(.plain)
        .contextMenu {
            PodcastMenu(podcast: podcast) { podcastPendingUnsubscribe = podcast }
        } preview: {
            PodcastPreview(podcast: podcast)
        }
        .podcastUnsubscribeConfirmation($podcastPendingUnsubscribe) { podcast in
            PodcastActions(app: app).unsubscribe(podcast)
        }
    }
}

struct CarouselRadioStationCard: View {
    let station: RadioStation

    @Environment(AppModel.self) private var app
    @State private var editingStation: RadioStation?
    @State private var stationPendingDeletion: RadioStation?

    var body: some View {
        Button {
            RadioStationActions(app: app).play(station)
        } label: {
            ArtworkCard(artworkUrl: station.logo, title: station.name, size: CarouselCardSize.standard)
        }
        .buttonStyle(.plain)
        .contextMenu {
            RadioStationMenu(
                station: station,
                onEdit: { editingStation = station },
                onDelete: { stationPendingDeletion = station }
            )
        } preview: {
            RadioStationPreview(station: station)
        }
        .sheet(item: $editingStation) { RadioStationFormSheet(station: $0) }
        .radioStationDeletionConfirmation($stationPendingDeletion) { station in
            RadioStationActions(app: app).delete(station)
        }
    }
}
