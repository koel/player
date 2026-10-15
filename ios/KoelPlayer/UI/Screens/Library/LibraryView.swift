@preconcurrency import Shared
import SwiftUI

struct LibraryView: View {
    @Environment(AppModel.self) private var app
    @State private var recentlyAdded: [any Playable] = []
    @State private var mostPlayed: [any Playable] = []

    private var destinations: [LibraryDestination] {
        LibraryDestination.visible(
            supportsPodcasts: app.core.session.supports(feature: .podcasts),
            supportsRadioStations: app.core.session.supports(feature: .radioStations)
        )
    }

    var body: some View {
        List {
            Section {
                ForEach(destinations) { destination in
                    NavigationLink(value: destination.route) {
                        Label(destination.title, systemImage: destination.systemImage)
                            .font(.title3)
                    }
                }
            }

            songSection("Recently Added", songs: recentlyAdded)
            songSection("Most Played", songs: mostPlayed)
        }
        .listStyle(.plain)
        .navigationTitle("Library")
        .task {
            for await songs in app.core.overview.recentlyAddedSongs { recentlyAdded = songs }
        }
        .task {
            for await songs in app.core.overview.mostPlayedSongs { mostPlayed = songs }
        }
        .task {
            guard recentlyAdded.isEmpty, mostPlayed.isEmpty else { return }
            try? await app.core.overview.refresh()
        }
    }

    @ViewBuilder
    private func songSection(_ title: String, songs: [any Playable]) -> some View {
        if !songs.isEmpty {
            Section {
                ForEach(songs, id: \.id) { PlayableRow(playable: $0) }
            } header: {
                Text(title)
                    .font(.title2.bold())
                    .foregroundStyle(.primary)
            }
        }
    }
}
