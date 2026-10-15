@preconcurrency import Shared
import UIKit

/// Home screen quick actions (long-press the app icon).
enum QuickActions {
    enum Kind: String {
        case search = "koel_action_search"
        case playFavorites = "koel_action_play_favorites"
        case playDownloaded = "koel_action_play_downloaded"
        case playRecent = "koel_action_play_recent"
    }

    /// Shortcuts arrive before the UI exists on a cold launch, so they wait here until handled.
    private static var pending: Kind?
    private static var continuation: AsyncStream<Kind>.Continuation?

    static func receive(_ item: UIApplicationShortcutItem) {
        guard let kind = Kind(rawValue: item.type) else { return }
        if let continuation {
            continuation.yield(kind)
        } else {
            pending = kind
        }
    }

    /// Runs for as long as the main UI is up.
    static func handle(app: AppModel) async {
        let (stream, continuation) = AsyncStream.makeStream(of: Kind.self)
        self.continuation = continuation
        defer { self.continuation = nil }

        if let pending {
            self.pending = nil
            continuation.yield(pending)
        }

        let shortcuts = Task { await keepShortcutsCurrent(app: app) }
        defer { shortcuts.cancel() }

        for await kind in stream {
            await perform(kind, app: app)
        }
    }

    private static func perform(_ kind: Kind, app: AppModel) async {
        switch kind {
        case .search:
            app.navigator.focusSearch()
        case .playFavorites:
            if let favorites = try? await app.core.favorites.fetch() {
                app.player.play(favorites, shuffled: true)
            }
        case .playDownloaded:
            app.player.play(app.core.downloads.playables.value, shuffled: true)
        case .playRecent:
            await resumeQueue(app: app)
        }
    }

    /// On a cold launch the saved queue is restored after data loads; give it a moment.
    private static func resumeQueue(app: AppModel) async {
        for _ in 0..<50 where app.player.state.queue.isEmpty {
            try? await Task.sleep(for: .milliseconds(100))
        }
        if !app.player.state.queue.isEmpty { app.player.controller.play() }
    }

    private static func keepShortcutsCurrent(app: AppModel) async {
        for await state in app.core.player.state {
            UIApplication.shared.shortcutItems = items(recent: state.current)
        }
    }

    static func items(recent: (any Playable)?) -> [UIApplicationShortcutItem] {
        var items = [
            UIApplicationShortcutItem(type: Kind.search.rawValue, localizedTitle: "Search", localizedSubtitle: nil, icon: .init(type: .search)),
            UIApplicationShortcutItem(type: Kind.playFavorites.rawValue, localizedTitle: "Play Favorite Songs", localizedSubtitle: nil, icon: .init(systemImageName: "star.fill")),
            UIApplicationShortcutItem(type: Kind.playDownloaded.rawValue, localizedTitle: "Play Downloaded", localizedSubtitle: nil, icon: .init(systemImageName: "arrow.down.circle.fill")),
        ]
        if let recent {
            items.append(UIApplicationShortcutItem(
                type: Kind.playRecent.rawValue,
                localizedTitle: "Play Most Recent",
                localizedSubtitle: recentSubtitle(artist: recent.subtitle, title: recent.title),
                icon: .init(systemImageName: "clock.arrow.circlepath")
            ))
        }
        return items
    }

    static func recentSubtitle(artist: String, title: String) -> String {
        artist.isEmpty ? title : "\(artist) – \(title)"
    }
}

final class AppDelegate: NSObject, UIApplicationDelegate {
    func application(
        _ application: UIApplication,
        configurationForConnecting connectingSceneSession: UISceneSession,
        options: UIScene.ConnectionOptions
    ) -> UISceneConfiguration {
        if let shortcut = options.shortcutItem { QuickActions.receive(shortcut) }
        let configuration = UISceneConfiguration(name: nil, sessionRole: connectingSceneSession.role)
        configuration.delegateClass = SceneDelegate.self
        return configuration
    }
}

final class SceneDelegate: NSObject, UIWindowSceneDelegate {
    func windowScene(
        _ windowScene: UIWindowScene,
        performActionFor shortcutItem: UIApplicationShortcutItem,
        completionHandler: @escaping (Bool) -> Void
    ) {
        QuickActions.receive(shortcutItem)
        completionHandler(true)
    }
}
