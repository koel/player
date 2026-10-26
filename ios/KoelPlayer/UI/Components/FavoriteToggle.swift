import SwiftUI

struct FavoriteToggle {
    let isFavorite: Bool
    let toggle: () async throws -> Void

    /// Failures roll back in the store, so a toast is all that's left to show.
    @MainActor
    func perform(app: AppModel) {
        Task {
            do {
                try await toggle()
            } catch {
                app.toasts.showError()
            }
        }
    }
}

/// Favorite or Undo Favorite in the menus of albums, artists, podcasts and stations.
struct EntityFavoriteButton: View {
    let favorite: FavoriteToggle

    @Environment(AppModel.self) private var app

    var body: some View {
        Button(
            favorite.isFavorite ? "Undo Favorite" : "Favorite",
            systemImage: favorite.isFavorite ? "heart.slash" : "heart"
        ) {
            favorite.perform(app: app)
        }
    }
}

extension EntityFavoriteButton {
    init(isFavorite: Bool, toggle: @escaping () async throws -> Void) {
        self.init(favorite: FavoriteToggle(isFavorite: isFavorite, toggle: toggle))
    }
}
