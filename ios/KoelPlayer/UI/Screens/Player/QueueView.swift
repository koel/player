@preconcurrency import Shared
import SwiftUI

struct QueueView: View {
    @Environment(AppModel.self) private var app

    var body: some View {
        let state = app.player.state
        let queue = state.queue

        NavigationStack {
            List {
                ForEach(Array(queue.enumerated()), id: \.element.id) { index, playable in
                    Button {
                        app.player.play(playable)
                    } label: {
                        HStack(spacing: 12) {
                            Artwork(url: playable.artworkUrl, size: 40, cornerRadius: 6)
                                .overlay {
                                    if index == state.currentIndex {
                                        NowPlayingIndicator(isPlaying: state.isPlaying)
                                            .frame(width: 40, height: 40)
                                            .background(.black.opacity(0.45), in: .rect(cornerRadius: 6))
                                    }
                                }
                            VStack(alignment: .leading, spacing: 2) {
                                Text(playable.title).lineLimit(1)
                                Text(playable.subtitle)
                                    .font(.subheadline)
                                    .foregroundStyle(.secondary)
                                    .lineLimit(1)
                            }
                        }
                    }
                    .buttonStyle(.plain)
                    .contextMenu { PlayableMenu(playable: playable) }
                }
                .onMove { source, destination in
                    guard let from = source.first else { return }
                    app.player.controller.move(from: Int32(from), to: Int32(destination))
                }
                .onDelete { offsets in
                    offsets.sorted(by: >).forEach { app.player.controller.removeAt(index: Int32($0)) }
                }
            }
            .listStyle(.plain)
            .environment(\.editMode, .constant(.active))
            .overlay {
                if queue.isEmpty {
                    ContentUnavailableView("No Songs Queued", systemImage: "list.bullet")
                }
            }
            .navigationTitle("Playing Next")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                if !queue.isEmpty {
                    ToolbarItem(placement: .primaryAction) {
                        Button("Clear", role: .destructive) { app.player.controller.clearQueue() }
                    }
                }
            }
        }
    }
}
