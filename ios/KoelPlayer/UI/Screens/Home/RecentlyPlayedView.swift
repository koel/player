@preconcurrency import Shared
import SwiftUI

struct RecentlyPlayedView: View {
    @Environment(AppModel.self) private var app

    var body: some View {
        RecentlyPlayedList(store: app.core.recentlyPlayed)
    }
}

private struct RecentlyPlayedList: View {
    let store: RecentlyPlayedStore

    @State private var playables: Live<[any Playable]>
    @State private var filter = ""
    @State private var loadState = LoadState()

    init(store: RecentlyPlayedStore) {
        self.store = store
        _playables = State(initialValue: Live(store.items))
    }

    /// The store stays loaded across visits, so only an unloaded store has anything to wait for.
    private var isPending: Bool {
        loadState.isLoading || (!store.loaded.value.boolValue && !loadState.hasFailed)
    }

    var body: some View {
        let displayed = SortingKt.filtered(playables.value, keywords: filter)

        List {
            Group {
                if playables.value.isEmpty, isPending {
                    LoadingRows()
                }

                if !displayed.isEmpty {
                    PlayShuffleButtons(playables: displayed)
                }

                PlayableListContent(playables: displayed)
            }
            .brandListRow()
        }
        .listStyle(.plain)
        .overlay {
            ListStateOverlay(
                isEmpty: playables.value.isEmpty,
                isLoading: isPending,
                hasFailed: loadState.hasFailed,
                showsSpinner: false,
                retry: { Task { await fetch() } }
            ) {
                ContentUnavailableView(
                    "No recently played songs",
                    systemImage: "clock",
                    description: Text("You have not played any songs yet.")
                )
            }
        }
        .filterable(text: $filter, matchesNothing: !playables.value.isEmpty && displayed.isEmpty, isShown: !playables.value.isEmpty || isPending)
        .navigationTitle("Recently Played")
        .brandMeshBackground()
        .task {
            if !store.loaded.value.boolValue { await fetch() }
        }
    }

    private func fetch() async {
        await loadState.load { _ = try await store.fetch() }
    }
}
