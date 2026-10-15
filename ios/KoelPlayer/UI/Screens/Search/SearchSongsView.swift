@preconcurrency import Shared
import SwiftUI

/// Every song matching a search, behind the Songs section's "See All".
struct SearchSongsView: View {
    let keywords: String

    @Environment(AppModel.self) private var app
    @State private var playables: [any Playable]?
    @State private var hasFailed = false

    var body: some View {
        List {
            if let playables, !playables.isEmpty {
                PlayShuffleButtons(playables: playables)
                    .listRowInsets(EdgeInsets(top: 8, leading: 0, bottom: 8, trailing: 0))
                    .listRowSeparator(.hidden)

                ForEach(playables, id: \.id) { playable in
                    PlayableRow(playable: playable)
                }
            }
        }
        .listStyle(.plain)
        .overlay { placeholder }
        .navigationTitle(keywords)
        .navigationBarTitleDisplayMode(.inline)
        .task { await load() }
    }

    @ViewBuilder
    private var placeholder: some View {
        if hasFailed {
            ContentUnavailableView {
                Label("Couldn't Load Songs", systemImage: "exclamationmark.triangle")
            } actions: {
                Button("Try Again") { Task { await load() } }
                    .buttonStyle(.glass)
            }
        } else if let playables {
            if playables.isEmpty { ContentUnavailableView.search(text: keywords) }
        } else {
            ProgressView()
        }
    }

    private func load() async {
        hasFailed = false
        do {
            playables = try await app.core.search.searchPlayables(keywords: keywords)
        } catch {
            hasFailed = !Task.isCancelled
        }
    }
}
