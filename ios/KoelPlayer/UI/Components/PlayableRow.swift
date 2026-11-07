@preconcurrency import Shared
import SwiftUI

struct PlayableRow: View {
    /// The space above and below a row's content, as compact as Apple Music's song rows.
    static let verticalInset: CGFloat = 8
    /// Where a divider under a row starts: past the artwork, in line with the title.
    static let dividerInset: CGFloat = 72

    enum Style {
        /// Artwork, title, artist (or podcast).
        case standard
        /// Track number instead of artwork, album name as the subtitle. For album screens.
        case album
        /// Artwork, album name as the subtitle. For artist screens.
        case artist
        /// No artwork; the episode's date as the subtitle.
        case podcast
        /// Like standard, without Play Next/Last or the Download and More buttons, as in Apple Music's queue.
        case queue
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
                MediaRow(title: playable.title, subtitle: subtitle) {
                    PlayableRowLeading(playable: playable, style: style)
                }

                Spacer(minLength: 0)

                if style != .queue {
                    DownloadButton(playable: playable)
                        .font(.caption)

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
            if style != .queue {
                Button("Play Next", systemImage: "text.line.first.and.arrowtriangle.forward") {
                    PlayableActions(app: app).playNext(playable)
                }
                .tint(.orange)
            }
        }
        .swipeActions(edge: .trailing) {
            if let removal {
                RemovalSwipeButton(title: removal.title, systemImage: removal.systemImage, action: removal.action)
            }
            if style != .queue {
                PlayLastSwipeButton {
                    PlayableActions(app: app).playLast(playable)
                }
            }
        }
        .listRowInsets(EdgeInsets(top: Self.verticalInset, leading: 16, bottom: Self.verticalInset, trailing: 16))
    }

    private var subtitle: String {
        switch style {
        case .album, .artist:
            (playable as? Song)?.albumName ?? playable.subtitle
        case .podcast:
            playable.createdAt.iso8601Date?.episodeDateLabel ?? ""
        case .standard, .queue:
            playable.subtitle
        }
    }
}

/// Its own view, so a change in what's playing redraws only the rows on screen rather than every row in a long list.
private struct PlayableRowLeading: View {
    let playable: any Playable
    let style: PlayableRow.Style

    @Environment(AppModel.self) private var app

    var body: some View {
        switch style {
        case .standard, .artist, .queue:
            Artwork(url: playable.artworkUrl, size: 44, cornerRadius: 6)
                .nowPlayingOverlay(isCurrent: app.player.isCurrent(playable), isPlaying: app.player.isPlaying(playable), size: 44)
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
}

/// Animated bars on the item that is playing, like Apple Music.
struct NowPlayingIndicator: View {
    let isPlaying: Bool

    @Environment(\.brandColor) private var brandColor

    var body: some View {
        Image(systemName: "waveform")
            .symbolEffect(.variableColor.iterative, isActive: isPlaying)
            .foregroundStyle(brandColor)
            .accessibilityLabel(isPlaying ? "Now playing" : "Paused")
    }
}

/// Shows whether the playable is downloaded, and downloads it with a tap when it is not.
struct DownloadButton: View {
    let playable: any Playable

    @Environment(AppModel.self) private var app

    var body: some View {
        if app.isDownloading(playable) {
            ProgressView().controlSize(.mini)
        } else if app.isDownloaded(playable) {
            Image(systemName: "checkmark.circle.fill")
                .foregroundStyle(.downloaded)
                .accessibilityLabel("Downloaded")
        } else if !app.isOffline {
            Button {
                PlayableActions(app: app).download(playable)
            } label: {
                Image(systemName: "arrow.down.circle")
                    .frame(width: 24, height: 32)
                    .contentShape(.rect)
            }
            .buttonStyle(.plain)
            .foregroundStyle(.secondary)
            .accessibilityLabel("Download")
        }
    }
}

struct PlayablePreview: View {
    let playable: any Playable

    var body: some View {
        ContextMenuPreview(title: playable.title, subtitle: "\(playable.subtitle) • \(playable.collectionName)", artworkUrl: playable.artworkUrl)
    }
}

/// A heading over songs outside a `List`, with placeholder rows while they load.
struct PlayableSection: View {
    let title: String
    var destination: Route?
    let playables: [any Playable]
    var style = PlayableRow.Style.standard
    var isLoading = false
    var placeholderCount = 5

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            SectionHeader(title: title, destination: destination)
                .padding(.bottom, SectionHeader.contentGap - PlayableRow.verticalInset)

            if isLoading {
                LoadingRowStack(count: placeholderCount)
            }

            PlayableRowStack(playables: playables, style: style)
        }
    }
}

/// Placeholder song rows outside a `List`, spaced like `PlayableRowStack`.
struct LoadingRowStack: View {
    let count: Int

    var body: some View {
        LazyVStack(spacing: 0) {
            LoadingRows(count: count)
                .padding(.horizontal)
                .padding(.vertical, PlayableRow.verticalInset)
        }
    }
}

/// Songs or episodes outside a `List`, spaced and divided the same as a list's rows.
struct PlayableRowStack: View {
    let playables: [any Playable]
    var style = PlayableRow.Style.standard

    var body: some View {
        LazyVStack(spacing: 0) {
            ForEach(playables, id: \.id) { playable in
                PlayableRow(playable: playable, style: style)
                    .padding(.horizontal)
                    .padding(.vertical, PlayableRow.verticalInset)
                Hairline().padding(.leading, PlayableRow.dividerInset)
            }
        }
    }
}
