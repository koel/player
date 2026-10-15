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
    @State private var isLoading = false
    @State private var hasFailed = false

    init(store: RecentlyPlayedStore) {
        self.store = store
        _playables = State(initialValue: Live(store.items))
    }

    var body: some View {
        let displayed = SortingKt.filtered(playables.value, keywords: filter)

        List {
            if !displayed.isEmpty {
                PlayShuffleButtons(playables: displayed)
                    .listRowInsets(EdgeInsets(top: 8, leading: 0, bottom: 8, trailing: 0))
                    .listRowSeparator(.hidden)
            }

            ForEach(displayed, id: \.id) { playable in
                PlayableRow(playable: playable)
            }
        }
        .listStyle(.plain)
        .overlay {
            if playables.value.isEmpty {
                emptyState
            } else if displayed.isEmpty {
                ContentUnavailableView.search(text: filter)
            }
        }
        .searchable(text: $filter, prompt: "Filter")
        .navigationTitle("Recently Played")
        .task {
            if !store.loaded.value.boolValue { await fetch() }
        }
    }

    @ViewBuilder
    private var emptyState: some View {
        if isLoading {
            ProgressView()
        } else if hasFailed {
            ContentUnavailableView {
                Label("Couldn't Load Recently Played", systemImage: "exclamationmark.triangle")
            } actions: {
                Button("Try Again") { Task { await fetch() } }
                    .buttonStyle(.glass)
            }
        } else {
            ContentUnavailableView(
                "No Recently Played Songs",
                systemImage: "clock",
                description: Text("You have not played any songs yet.")
            )
        }
    }

    private func fetch() async {
        guard !isLoading else { return }
        isLoading = true
        defer { isLoading = false }

        do {
            _ = try await store.fetch()
            hasFailed = false
        } catch {
            hasFailed = true
        }
    }
}
