@preconcurrency import Shared
import SwiftUI

struct FavoritesView: View {
    @Environment(AppModel.self) private var app
    @State private var favorites: [any Playable] = []
    @State private var sort: SortSetting?
    @State private var query = ""
    @State private var isLoading = false
    @State private var hasFailed = false

    private static let sortKey = "favorites.sort"

    private var supportsCustomOrder: Bool {
        app.core.session.supports(feature: .customFavoritesOrder)
    }

    private var currentSort: SortSetting {
        sort ?? SortSetting.remembered(
            for: Self.sortKey,
            default: SortSetting(
                field: supportsCustomOrder ? PlayableSortField.shared.POSITION : PlayableSortField.shared.TITLE,
                order: .asc
            )
        )
    }

    private var displayedSongs: [any Playable] {
        SortingKt.filtered(SortingKt.sorted(favorites, field: currentSort.field, order: currentSort.order), keywords: query)
    }

    var body: some View {
        List {
            if !favorites.isEmpty {
                PlayShuffleButtons(playables: displayedSongs)
                    .listRowInsets(EdgeInsets())
                    .listRowSeparator(.hidden)
            }

            PlayableListContent(
                playables: displayedSongs,
                isSortedByTitle: currentSort.field == PlayableSortField.shared.TITLE,
                removal: unfavoriteAction
            )
        }
        .listStyle(.plain)
        .navigationTitle("Favorites")
        .filterable(text: $query, prompt: "Filter Favorites")
        .refreshable { await fetch(forceRefresh: true) }
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                SortMenu(
                    options: SortOptions.favorites(supportsCustomOrder: supportsCustomOrder),
                    field: currentSort.field,
                    order: currentSort.order
                ) { field, order in
                    let setting = SortSetting(field: field, order: order)
                    setting.remember(for: Self.sortKey)
                    sort = setting
                }
            }
        }
        .overlay {
            ListStateOverlay(isEmpty: favorites.isEmpty, isLoading: isLoading, hasFailed: hasFailed, retry: { Task { await fetch() } }) {
                ContentUnavailableView(
                    "No Favorites",
                    systemImage: "star",
                    description: Text("Tap Favorite in a song’s menu to add it here.")
                )
            }
        }
        .task {
            for await next in app.core.favorites.items { favorites = next }
        }
        .task { await fetch() }
    }

    private func unfavoriteAction(_ playable: any Playable) -> PlayableRow.Removal {
        PlayableRow.Removal(title: "Undo Favorite", systemImage: "star.slash") {
            Task {
                do {
                    try await app.core.favorites.unlike(playable: playable)
                } catch {
                    app.toasts.showError()
                }
            }
        }
    }

    private func fetch(forceRefresh: Bool = false) async {
        isLoading = true
        defer { isLoading = false }
        do {
            _ = try await app.core.favorites.fetch(forceRefresh: forceRefresh)
            hasFailed = false
        } catch {
            hasFailed = true
        }
    }
}
