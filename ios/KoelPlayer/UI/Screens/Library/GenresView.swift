@preconcurrency import Shared
import SwiftUI

struct GenresView: View {
    @Environment(AppModel.self) private var app
    @State private var genres: [Genre] = []
    @State private var isLoading = false
    @State private var hasFailed = false

    var body: some View {
        List(genres, id: \.id) { genre in
            NavigationLink(value: Route.genre(id: genre.id, name: genre.displayName)) {
                VStack(alignment: .leading, spacing: 2) {
                    Text(genre.displayName).lineLimit(1)
                    Text(Int(genre.songCount).pluralized("song"))
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
            }
        }
        .listStyle(.plain)
        .navigationTitle("Genres")
        .refreshable { await fetch() }
        .overlay {
            ListStateOverlay(isEmpty: genres.isEmpty, isLoading: isLoading, hasFailed: hasFailed, retry: { Task { await fetch() } }) {
                ContentUnavailableView("No Genres", systemImage: "guitars")
            }
        }
        .task {
            for await next in app.core.genres.items { genres = next }
        }
        .task { await fetch() }
    }

    private func fetch() async {
        isLoading = true
        defer { isLoading = false }
        do {
            _ = try await app.core.genres.fetch()
            hasFailed = false
        } catch {
            hasFailed = true
        }
    }
}

extension Genre {
    var displayName: String {
        name.isEmpty ? "Unknown Genre" : name
    }
}
