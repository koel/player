@preconcurrency import Shared
import SwiftUI

/// The compact card shown above a long-press menu: cover on the left, title and subtitle beside it.
struct ContextMenuPreview<Cover: View>: View {
    let title: String
    var subtitle: String?
    @ViewBuilder let cover: (_ size: CGFloat) -> Cover

    var body: some View {
        HStack(spacing: 14) {
            cover(88)
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.headline)
                    .lineLimit(3)
                if let subtitle, !subtitle.isEmpty {
                    Text(subtitle)
                        .foregroundStyle(.secondary)
                        .lineLimit(2)
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .padding(14)
        .frame(width: 340)
    }
}

extension ContextMenuPreview where Cover == Artwork {
    init(title: String, subtitle: String? = nil, artworkUrl: String?, isCircle: Bool = false) {
        self.init(title: title, subtitle: subtitle) { size in
            Artwork(url: artworkUrl, size: size, cornerRadius: 8, isCircle: isCircle)
        }
    }
}

struct AlbumPreview: View {
    let album: Album

    var body: some View {
        ContextMenuPreview(title: album.name, subtitle: album.artistName, artworkUrl: album.cover)
    }
}

struct ArtistPreview: View {
    let artist: Artist

    var body: some View {
        ContextMenuPreview(title: artist.name, artworkUrl: artist.imageUrl, isCircle: true)
    }
}

struct PlaylistPreview: View {
    let playlist: Playlist

    var body: some View {
        ContextMenuPreview(title: playlist.name, subtitle: playlist.kindLabel) { size in
            PlaylistArtwork(playlist: playlist, size: size)
        }
    }
}

struct PodcastPreview: View {
    let podcast: Podcast

    var body: some View {
        ContextMenuPreview(title: podcast.title, subtitle: podcast.author, artworkUrl: podcast.imageUrl)
    }
}

struct RadioStationPreview: View {
    let station: RadioStation

    var body: some View {
        ContextMenuPreview(title: station.name, subtitle: station.description_) { size in
            RadioStationLogo(station: station, size: size, cornerRadius: 8)
        }
    }
}
