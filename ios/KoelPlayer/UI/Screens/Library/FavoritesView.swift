@preconcurrency import Shared
import SwiftUI

struct FavoritesView: View {
    @Environment(AppModel.self) private var app
    @State private var favorites: [any Playable] = []
    @State private var sort: SortSetting?
    @State private var query = ""
    @State private var loadState = LoadState()

    private static let sortKey = "favorites.sort"

    private var supportsCustomOrder: Bool {
        app.core.session.supports(feature: .customFavoritesOrder)
    }

    private var sortOptions: [SortOption] {
        SortOptions.favorites(supportsCustomOrder: supportsCustomOrder)
    }

    private var currentSort: SortSetting {
        sort ?? SortSetting.remembered(
            for: Self.sortKey,
            among: sortOptions,
            default: SortSetting(field: sortOptions[0].field, order: .asc)
        )
    }

    private var displayedSongs: [any Playable] {
        SortingKt.filtered(SortingKt.sorted(favorites, field: currentSort.field, order: currentSort.order), keywords: query)
    }

    var body: some View {
        let displayedSongs = displayedSongs

        List {
            Group {
                if favorites.isEmpty, loadState.isPending {
                    LoadingRows()
                }

                if !favorites.isEmpty {
                    PlayShuffleButtons(playables: displayedSongs)
                }

                PlayableListContent(
                    playables: displayedSongs,
                    isSortedByTitle: currentSort.field == PlayableSortField.shared.TITLE,
                    removal: unfavoriteAction
                )
            }
            .brandListRow()
        }
        .listStyle(.plain)
        .navigationTitle("Favorites")
        .brandMeshBackground()
        .filterable(text: $query, matchesNothing: !favorites.isEmpty && displayedSongs.isEmpty, isShown: !favorites.isEmpty || loadState.isPending)
        .refreshable { await fetch(forceRefresh: true) }
        .toolbar {
            SortToolbarItem(options: sortOptions, sort: currentSort, rememberKey: Self.sortKey) { sort = $0 }
        }
        .overlay {
            ListStateOverlay(isEmpty: favorites.isEmpty, loadState: loadState, showsSpinner: false, retry: { Task { await fetch() } }) {
                ContentUnavailableView(
                    "No favorites",
                    systemImage: "heart",
                    description: Text("Tap the \(Image(systemName: "heart")) icon in a song’s menu to mark it as favorite.")
                )
            }
        }
        .task {
            for await next in app.core.favorites.items { favorites = next }
        }
        .task { await fetch() }
    }

    private func unfavoriteAction(_ playable: any Playable) -> PlayableRow.Removal {
        PlayableRow.Removal(title: "Undo Favorite", systemImage: "heart.slash") {
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
        await loadState.load { _ = try await app.core.favorites.fetch(forceRefresh: forceRefresh) }
    }
}
