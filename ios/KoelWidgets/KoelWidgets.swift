import SwiftUI
import WidgetKit

@main
struct KoelWidgets: WidgetBundle {
    var body: some Widget {
        NowPlayingWidget()
        RecentlyPlayedWidget()
        PlayPauseControl()
    }
}

nonisolated struct SnapshotEntry: TimelineEntry {
    let date: Date
    let snapshot: WidgetSnapshot
}

/// The app reloads the widgets whenever what they show changes, so one entry is enough.
nonisolated struct SnapshotProvider: TimelineProvider {
    func placeholder(in context: Context) -> SnapshotEntry {
        SnapshotEntry(date: .now, snapshot: .placeholder)
    }

    func getSnapshot(in context: Context, completion: @escaping (SnapshotEntry) -> Void) {
        let snapshot = SharedContainer.readSnapshot()
        completion(SnapshotEntry(date: .now, snapshot: context.isPreview && snapshot.nowPlaying == nil ? .placeholder : snapshot))
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<SnapshotEntry>) -> Void) {
        completion(Timeline(entries: [SnapshotEntry(date: .now, snapshot: SharedContainer.readSnapshot())], policy: .never))
    }
}

extension WidgetSnapshot {
    nonisolated static let placeholder = WidgetSnapshot(
        nowPlaying: NowPlaying(title: "Song Title", subtitle: "Artist", isPlaying: true, isRadio: false),
        recentlyPlayed: (1...12).map { RecentItem(id: "\($0)", title: "Song Title", subtitle: "Artist") }
    )
}

/// A cover saved by the app, or Koel's default cover.
struct WidgetArtwork: View {
    let file: String?
    var cornerRadius: CGFloat = 8

    var body: some View {
        Self.image(for: file)
            .resizable()
            .scaledToFill()
            .aspectRatio(1, contentMode: .fit)
            .clipShape(.rect(cornerRadius: cornerRadius))
    }

    static func image(for file: String?) -> Image {
        if let file, let url = SharedContainer.artworkUrl(named: file), let uiImage = UIImage(contentsOfFile: url.path()) {
            Image(uiImage: uiImage)
        } else {
            Image("default-image")
        }
    }
}

/// The cover, blurred and darkened across the whole widget, like the Now Playing screen.
struct WidgetCoverBackground: View {
    let file: String?

    var body: some View {
        GeometryReader { proxy in
            WidgetArtwork.image(for: file)
                .resizable()
                .scaledToFill()
                .frame(width: proxy.size.width * 1.6, height: proxy.size.height * 1.6)
                .blur(radius: 30)
                .frame(width: proxy.size.width, height: proxy.size.height)
        }
        .clipped()
        .overlay(.black.opacity(0.45))
    }
}
