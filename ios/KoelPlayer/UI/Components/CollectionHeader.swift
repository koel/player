@preconcurrency import Shared
import SwiftUI

/// The top of album, artist, playlist, genre and podcast screens: artwork, titles, Play and Shuffle.
struct CollectionHeader<Accessory: View>: View {
    let artworkUrl: String?
    let title: String
    var subtitle: String?
    var detail: String?
    var isCircular = false
    let playables: [any Playable]
    @ViewBuilder var accessory: () -> Accessory

    @Environment(AppModel.self) private var app

    var body: some View {
        VStack(spacing: 16) {
            Artwork(url: artworkUrl, size: 240, cornerRadius: 12, isCircle: isCircular)
                .shadow(color: .black.opacity(0.4), radius: 20, y: 10)

            VStack(spacing: 4) {
                Text(title)
                    .font(.title2.bold())
                    .multilineTextAlignment(.center)
                if let subtitle {
                    Text(subtitle)
                        .font(.title3)
                        .foregroundStyle(Color.accentColor)
                        .multilineTextAlignment(.center)
                }
                if let detail {
                    Text(detail)
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                }
            }

            accessory()

            PlayShuffleButtons(playables: playables)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 8)
    }
}

extension CollectionHeader where Accessory == EmptyView {
    init(artworkUrl: String?, title: String, subtitle: String? = nil, detail: String? = nil, isCircular: Bool = false, playables: [any Playable]) {
        self.init(artworkUrl: artworkUrl, title: title, subtitle: subtitle, detail: detail, isCircular: isCircular, playables: playables) {
            EmptyView()
        }
    }
}

struct PlayShuffleButtons: View {
    let playables: [any Playable]

    @Environment(AppModel.self) private var app

    var body: some View {
        HStack(spacing: 12) {
            Button {
                app.player.play(playables)
            } label: {
                Label("Play", systemImage: "play.fill").frame(maxWidth: .infinity)
            }
            Button {
                app.player.play(playables, shuffled: true)
            } label: {
                Label("Shuffle", systemImage: "shuffle").frame(maxWidth: .infinity)
            }
        }
        .buttonStyle(.glass)
        .controlSize(.large)
        .disabled(playables.isEmpty)
        .padding(.horizontal)
    }
}

/// Square artwork with two lines below, for album/artist/podcast grids and carousels.
struct ArtworkCard: View {
    let artworkUrl: String?
    let title: String
    var subtitle: String?
    var size: CGFloat = 160
    var isCircular = false

    var body: some View {
        VStack(alignment: isCircular ? .center : .leading, spacing: 6) {
            Artwork(url: artworkUrl, size: size, cornerRadius: 10, isCircle: isCircular)
            VStack(alignment: isCircular ? .center : .leading, spacing: 1) {
                Text(title)
                    .font(.subheadline)
                    .lineLimit(1)
                if let subtitle {
                    Text(subtitle)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .lineLimit(1)
                }
            }
            .frame(width: size, alignment: isCircular ? .center : .leading)
        }
        .contentShape(.rect)
    }
}

/// A toolbar menu that picks a sort field and flips the order when the same field is picked again.
struct SortMenu: View {
    let options: [(field: String, label: String)]
    let field: String
    let order: Shared.SortOrder
    let onChange: (_ field: String, _ order: Shared.SortOrder) -> Void

    var body: some View {
        Menu {
            ForEach(options, id: \.field) { option in
                Button {
                    onChange(option.field, option.field == field ? order.toggled() : .asc)
                } label: {
                    if option.field == field {
                        Label(option.label, systemImage: order == .asc ? "chevron.up" : "chevron.down")
                    } else {
                        Text(option.label)
                    }
                }
            }
        } label: {
            Label("Sort", systemImage: "arrow.up.arrow.down")
        }
    }
}
