import AppIntents
import SwiftUI
import WidgetKit

struct NowPlayingWidget: Widget {
    var body: some WidgetConfiguration {
        StaticConfiguration(kind: WidgetKind.nowPlaying, provider: SnapshotProvider()) { entry in
            NowPlayingWidgetView(nowPlaying: entry.snapshot.nowPlaying)
                .environment(\.colorScheme, .dark)
                .widgetURL(WidgetLink.nowPlaying.url)
                .containerBackground(for: .widget) {
                    WidgetCoverBackground(file: entry.snapshot.nowPlaying?.artworkFile)
                }
        }
        .configurationDisplayName("Now Playing")
        .description("What's playing, with play and skip controls.")
        .supportedFamilies([.systemSmall, .systemMedium])
    }
}

private struct NowPlayingWidgetView: View {
    let nowPlaying: WidgetSnapshot.NowPlaying?

    @Environment(\.widgetFamily) private var family

    var body: some View {
        if let nowPlaying {
            switch family {
            case .systemSmall: small(nowPlaying)
            default: medium(nowPlaying)
            }
        } else {
            nothingPlaying
        }
    }

    private func small(_ nowPlaying: WidgetSnapshot.NowPlaying) -> some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack(alignment: .top) {
                WidgetArtwork(file: nowPlaying.artworkFile)
                    .frame(width: 64, height: 64)
                Spacer(minLength: 0)
                PlayPauseButton(isPlaying: nowPlaying.isPlaying)
            }
            Spacer(minLength: 0)
            titles(nowPlaying)
        }
    }

    private func medium(_ nowPlaying: WidgetSnapshot.NowPlaying) -> some View {
        HStack(spacing: 14) {
            WidgetArtwork(file: nowPlaying.artworkFile, cornerRadius: 10)
            VStack(alignment: .leading, spacing: 0) {
                titles(nowPlaying)
                Spacer(minLength: 0)
                HStack(spacing: 20) {
                    PlayPauseButton(isPlaying: nowPlaying.isPlaying)
                    if !nowPlaying.isRadio {
                        Button(intent: SkipToNextIntent()) {
                            Image(systemName: "forward.fill")
                                .font(.title3)
                                .frame(width: 40, height: 40)
                        }
                        .buttonStyle(.plain)
                        .accessibilityLabel("Next")
                    }
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
    }

    private func titles(_ nowPlaying: WidgetSnapshot.NowPlaying) -> some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(nowPlaying.title)
                .font(.subheadline.weight(.semibold))
                .lineLimit(2)
            Text(nowPlaying.subtitle)
                .font(.caption)
                .foregroundStyle(.secondary)
                .lineLimit(1)
        }
    }

    private var nothingPlaying: some View {
        VStack(alignment: .leading, spacing: 8) {
            WidgetArtwork(file: nil)
                .frame(width: 48, height: 48)
            Spacer(minLength: 0)
            Text("Not Playing")
                .font(.subheadline.weight(.semibold))
            Text("Open Koel to start listening.")
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

private struct PlayPauseButton: View {
    let isPlaying: Bool

    var body: some View {
        Button(intent: TogglePlaybackIntent()) {
            Image(systemName: isPlaying ? "pause.fill" : "play.fill")
                .font(.title3)
                .frame(width: 40, height: 40)
                .background(.white.opacity(0.2), in: .circle)
        }
        .buttonStyle(.plain)
        .accessibilityLabel(isPlaying ? "Pause" : "Play")
    }
}
