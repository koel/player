import SwiftUI
import WidgetKit

struct RecentlyPlayedWidget: Widget {
    var body: some WidgetConfiguration {
        StaticConfiguration(kind: WidgetKind.recentlyPlayed, provider: SnapshotProvider()) { entry in
            RecentlyPlayedWidgetView(items: entry.snapshot.recentlyPlayed)
                .environment(\.colorScheme, .dark)
                .containerBackground(for: .widget) {
                    WidgetCoverBackground(file: entry.snapshot.recentlyPlayed.first?.artworkFile)
                }
        }
        .configurationDisplayName("Recently Played")
        .description("Jump back into what you played last.")
        .supportedFamilies([.systemMedium, .systemLarge])
    }
}

private struct RecentlyPlayedWidgetView: View {
    let items: [WidgetSnapshot.RecentItem]

    @Environment(\.widgetFamily) private var family

    private var columnCount: Int { 4 }
    private var rowCount: Int { family == .systemLarge ? 3 : 1 }

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Recently Played")
                .font(.subheadline.weight(.semibold))

            if items.isEmpty {
                Text("Songs you play show up here.")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else {
                Grid(horizontalSpacing: 10, verticalSpacing: 10) {
                    ForEach(0..<rowCount, id: \.self) { row in
                        GridRow {
                            ForEach(0..<columnCount, id: \.self) { column in
                                cell(at: row * columnCount + column)
                            }
                        }
                    }
                }
                Spacer(minLength: 0)
            }
        }
    }

    @ViewBuilder
    private func cell(at index: Int) -> some View {
        if index < items.count {
            let item = items[index]
            Link(destination: WidgetLink.playRecent(id: item.id).url) {
                VStack(alignment: .leading, spacing: 3) {
                    WidgetArtwork(file: item.artworkFile, cornerRadius: 6)
                    Text(item.title)
                        .font(.caption2.weight(.medium))
                        .lineLimit(1)
                    if family == .systemLarge {
                        Text(item.subtitle)
                            .font(.caption2)
                            .foregroundStyle(.secondary)
                            .lineLimit(1)
                    }
                }
            }
        } else {
            Color.clear
        }
    }
}
