import Observation
import SwiftUI

enum AppTab: String, Codable, Hashable {
    case home
    case search
    case library
}

/// Every screen that can be pushed onto a tab's stack. Codable so stacks survive relaunches.
enum Route: Codable, Hashable {
    case songs
    case albums
    case artists
    case genres
    case playlists
    case favorites
    case downloads
    case recentlyPlayed
    case podcasts
    case radioStations
    case album(id: String)
    case artist(id: String)
    case playlist(id: String)
    case podcast(id: String)
    case genre(id: String, name: String)
    case searchSongs(keywords: String)
}

/// Owns the selected tab and each tab's navigation stack, and persists them like Flutter's RouteState.
@Observable
final class Navigator {
    var selectedTab: AppTab = .home {
        didSet { persist() }
    }

    var paths: [AppTab: [Route]] = [:] {
        didSet { persist() }
    }

    /// Set by the Search quick action; the search screen focuses its field and clears it.
    var wantsSearchFocus = false

    @ObservationIgnored private let defaults: UserDefaults
    private static let storageKey = "navigationState"

    init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
        restore()
    }

    func path(for tab: AppTab) -> Binding<[Route]> {
        Binding(
            get: { self.paths[tab] ?? [] },
            set: { self.paths[tab] = $0 }
        )
    }

    /// Pushes onto the visible tab, which is what "Go to Album" and friends expect.
    func push(_ route: Route) {
        paths[selectedTab, default: []].append(route)
    }

    /// Tapping the selected tab again pops it to its root, as in Flutter and every Apple app.
    func select(_ tab: AppTab) {
        if tab == selectedTab {
            paths[tab] = []
        } else {
            selectedTab = tab
        }
    }

    func focusSearch() {
        selectedTab = .search
        wantsSearchFocus = true
    }

    func reset() {
        selectedTab = .home
        paths = [:]
    }

    private struct Snapshot: Codable {
        let selectedTab: AppTab
        let paths: [AppTab: [Route]]
    }

    private func persist() {
        let snapshot = Snapshot(selectedTab: selectedTab, paths: paths)
        defaults.set(try? JSONEncoder().encode(snapshot), forKey: Self.storageKey)
    }

    private func restore() {
        guard let data = defaults.data(forKey: Self.storageKey),
              let snapshot = try? JSONDecoder().decode(Snapshot.self, from: data)
        else { return }
        selectedTab = snapshot.selectedTab
        paths = snapshot.paths
    }
}
