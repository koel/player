@preconcurrency import Shared
import SwiftUI

struct GenresView: View {
    @Environment(AppModel.self) private var app
    @State private var genres: [Genre] = []
    @State private var loadState = LoadState()

    var body: some View {
        List(genres, id: \.id) { genre in
            NavigationLink(value: Route.genre(id: genre.id, name: genre.displayName)) {
                MediaRow(title: genre.displayName, subtitle: Int(genre.songCount).pluralized("song"))
            }
            .brandListRow()
        }
        .listStyle(.plain)
        .navigationTitle("Genres")
        .brandMeshBackground()
        .refreshable { await fetch() }
        .overlay {
            ListStateOverlay(isEmpty: genres.isEmpty, loadState: loadState, retry: { Task { await fetch() } }) {
                ContentUnavailableView("No genres", systemImage: "guitars")
            }
        }
        .task {
            for await next in app.core.genres.items { genres = next }
        }
        .task { await fetch() }
    }

    private func fetch() async {
        await loadState.load { _ = try await app.core.genres.fetch() }
    }
}

extension Genre {
    var displayName: String {
        name.isEmpty ? "Unknown Genre" : name
    }
}
