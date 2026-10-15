@preconcurrency import Shared
import SwiftUI

struct PlayableRow: View {
    enum Style {
        /// Artwork, title, artist (or podcast).
        case standard
        /// Track number instead of artwork, album name as the subtitle. For album screens.
        case album
        /// Artwork, album name as the subtitle. For artist screens.
        case artist
        /// No artwork; the episode's date as the subtitle.
        case podcast
    }

    /// Swiping a row out of a list it belongs to, such as Undo Favorite on Favorites.
    struct Removal {
        let title: String
        let systemImage: String
        let action: () -> Void
    }

    let playable: any Playable
    var style = Style.standard
    var removal: Removal?

    @Environment(AppModel.self) private var app

    var body: some View {
        Button {
            app.player.play(playable)
        } label: {
            HStack(spacing: 12) {
                leading

                VStack(alignment: .leading, spacing: 2) {
                    Text(playable.title)
                        .lineLimit(1)
                        .foregroundStyle(app.player.isCurrent(playable) ? Color.highlight : .primary)
                    Text(subtitle)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                        .lineLimit(1)
                }

                Spacer(minLength: 0)

                DownloadIndicator(playable: playable)

                Menu {
                    PlayableMenu(playable: playable)
                } label: {
                    Image(systemName: "ellipsis")
                        .frame(width: 32, height: 32)
                        .contentShape(.rect)
                }
                .foregroundStyle(.secondary)
                .accessibilityLabel("More")
            }
            .contentShape(.rect)
        }
        .buttonStyle(.plain)
        .contextMenu {
            PlayableMenu(playable: playable)
        } preview: {
            PlayablePreview(playable: playable)
        }
        .swipeActions(edge: .leading) {
            Button("Play Next", systemImage: "text.line.first.and.arrowtriangle.forward") {
                PlayableActions(app: app).playNext(playable)
            }
            .tint(.orange)
        }
        .swipeActions(edge: .trailing) {
            if let removal {
                Button(removal.title, systemImage: removal.systemImage, role: .destructive, action: removal.action)
            }
            Button("Play Last", systemImage: "text.line.last.and.arrowtriangle.forward") {
                PlayableActions(app: app).playLast(playable)
            }
            .tint(.purple)
        }
    }

    @ViewBuilder
    private var leading: some View {
        switch style {
        case .standard, .artist:
            Artwork(url: playable.artworkUrl, size: 44, cornerRadius: 6)
                .overlay {
                    if app.player.isCurrent(playable) {
                        NowPlayingIndicator(isPlaying: app.player.isPlaying(playable))
                            .frame(width: 44, height: 44)
                            .background(.black.opacity(0.45), in: .rect(cornerRadius: 6))
                    }
                }
        case .album:
            Group {
                if app.player.isCurrent(playable) {
                    NowPlayingIndicator(isPlaying: app.player.isPlaying(playable))
                } else {
                    Text((playable as? Song).map { $0.track == 0 ? "" : "\($0.track)" } ?? "")
                        .font(.subheadline.monospacedDigit())
                        .foregroundStyle(.secondary)
                }
            }
            .frame(width: 24)
        case .podcast:
            EmptyView()
        }
    }

    private var subtitle: String {
        switch style {
        case .album, .artist:
            (playable as? Song)?.albumName ?? playable.subtitle
        case .podcast:
            playable.createdAt.iso8601Date?.episodeDateLabel ?? ""
        case .standard:
            playable.subtitle
        }
    }
}

/// Animated bars on the item that is playing, like Apple Music.
struct NowPlayingIndicator: View {
    let isPlaying: Bool

    var body: some View {
        Image(systemName: "waveform")
            .symbolEffect(.variableColor.iterative, isActive: isPlaying)
            .foregroundStyle(Color.highlight)
            .accessibilityLabel(isPlaying ? "Now playing" : "Paused")
    }
}

struct DownloadIndicator: View {
    let playable: any Playable

    @Environment(AppModel.self) private var app

    var body: some View {
        if app.isDownloading(playable) {
            ProgressView().controlSize(.mini)
        } else if app.isDownloaded(playable) {
            Image(systemName: "arrow.down.circle.fill")
                .font(.caption)
                .foregroundStyle(.secondary)
                .accessibilityLabel("Downloaded")
        }
    }
}

private struct PlayablePreview: View {
    let playable: any Playable

    var body: some View {
        VStack(spacing: 12) {
            Artwork(url: playable.artworkUrl, size: 220, cornerRadius: 12)
            VStack(spacing: 4) {
                Text(playable.title).font(.headline)
                Text("\(playable.subtitle) • \(playable.collectionName)")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
            .multilineTextAlignment(.center)
            .lineLimit(2)
        }
        .padding(20)
        .frame(width: 280)
    }
}
