@preconcurrency import Shared
import SwiftUI

/// Favorite, sort and "…" buttons for the album and artist screens.
struct CollectionToolbar<MenuContent: View>: ToolbarContent {
    let isFavorite: Bool
    let toggleFavorite: () async throws -> Void
    let sortOptions: [SortOption]
    @Binding var sort: SortSetting
    let sortKey: String
    var showsFavorite = true
    @ViewBuilder let menu: () -> MenuContent

    @Environment(AppModel.self) private var app

    var body: some ToolbarContent {
        if showsFavorite, app.core.session.supports(feature: .favoriteEntities) {
            ToolbarItem(placement: .primaryAction) {
                Button(isFavorite ? "Undo Favorite" : "Favorite", systemImage: isFavorite ? "star.fill" : "star") {
                    Task {
                        do {
                            try await toggleFavorite()
                        } catch {
                            app.toasts.showError()
                        }
                    }
                }
            }
        }
        ToolbarItem(placement: .primaryAction) {
            SortMenu(options: sortOptions, field: sort.field, order: sort.order) { field, order in
                sort = SortSetting(field: field, order: order)
                sort.remember(for: sortKey)
            }
        }
        ToolbarItem(placement: .primaryAction) {
            Menu("More", systemImage: "ellipsis", content: menu)
        }
    }
}

enum CollectionSummary {
    /// "2019 · 12 songs · 48 min", skipping whatever is unknown.
    static func detail(year: Int32? = nil, songs: [any Playable]) -> String? {
        detail(year: year, songCount: songs.count, totalLength: songs.reduce(0) { $0 + $1.length })
    }

    static func detail(year: Int32?, songCount: Int, totalLength: Double) -> String? {
        let yearLabel = year.map { "\($0)" }
        guard songCount > 0 else { return yearLabel }
        return [yearLabel, songCount.pluralized("song"), totalLength.totalLength]
            .compactMap { $0 }
            .joined(separator: " · ")
    }
}
