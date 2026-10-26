@preconcurrency import Shared
import SwiftUI

/// Every song matching a search, behind the Songs section's heading.
struct SearchSongsView: View {
    let keywords: String

    @Environment(AppModel.self) private var app
    @State private var playables: [any Playable] = []
    @State private var loadState = LoadState()

    var body: some View {
        List {
            Group {
                if !playables.isEmpty {
                    PlayShuffleButtons(playables: playables)
                }

                PlayableListContent(playables: playables)
            }
            .brandListRow()
        }
        .listStyle(.plain)
        .overlay { placeholder }
        .navigationTitle(keywords)
        .brandMeshBackground()
        .navigationBarTitleDisplayMode(.inline)
        .task { await load() }
    }

    private var placeholder: some View {
        ListStateOverlay(isEmpty: playables.isEmpty, loadState: loadState, retry: { Task { await load() } }) {
            ContentUnavailableView.search(text: keywords)
        }
    }

    private func load() async {
        await loadState.load { playables = try await app.core.search.searchPlayables(keywords: keywords) }
    }
}
