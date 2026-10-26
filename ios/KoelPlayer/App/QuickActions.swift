@preconcurrency import Shared
import UIKit

/// Home screen quick actions (long-press the app icon) and taps on the widgets.
enum QuickActions {
    enum Kind: String {
        case search = "koel_action_search"
        case playFavorites = "koel_action_play_favorites"
        case playDownloaded = "koel_action_play_downloaded"
        case playRecent = "koel_action_play_recent"
    }

    enum Action: Equatable {
        case shortcut(Kind)
        case widget(WidgetLink)

        var worksOffline: Bool {
            self == .shortcut(.playDownloaded) || self == .widget(.nowPlaying)
        }
    }

    enum Readiness {
        case now
        case afterLaunch
        case never
    }

    /// Actions arrive before the UI exists on a cold launch, so the latest one waits here until handled.
    private static var pending: Action?
    private static var wake: AsyncStream<Void>.Continuation?

    static func receive(_ item: UIApplicationShortcutItem) {
        guard let kind = Kind(rawValue: item.type) else { return }
        receive(.shortcut(kind))
    }

    static func receive(_ url: URL) {
        guard let link = WidgetLink(url: url) else { return }
        receive(.widget(link))
    }

    private static func receive(_ action: Action) {
        pending = action
        wake?.yield()
    }

    static func readiness(of action: Action, in phase: AppModel.Phase) -> Readiness {
        switch phase {
        case .launching, .loading: .afterLaunch
        case .main: .now
        case .login: .never
        case .noConnection, .offline: action.worksOffline ? .now : .never
        }
    }

    /// Runs for as long as the UI is up. An action the current phase can't handle is dropped, not kept for later.
    static func handle(app: AppModel) async {
        let (wakes, wake) = AsyncStream.makeStream(of: Void.self)
        self.wake = wake
        defer { self.wake = nil }

        let phaseChanges = Task {
            for await _ in Observations({ app.phase }) { wake.yield() }
        }
        defer { phaseChanges.cancel() }

        let shortcuts = Task { await keepShortcutsCurrent(app: app) }
        defer { shortcuts.cancel() }

        for await _ in wakes {
            guard let action = pending else { continue }
            let readiness = readiness(of: action, in: app.phase)
            guard readiness != .afterLaunch else { continue }

            pending = nil
            if readiness == .now { await run(action, app: app) }
        }
    }

    private static func run(_ action: Action, app: AppModel) async {
        if app.phase == .noConnection { app.goOffline() }
        switch action {
        case .shortcut(let kind): await perform(kind, app: app)
        case .widget(let link): await open(link, app: app)
        }
    }

    private static func open(_ link: WidgetLink, app: AppModel) async {
        switch link {
        case .nowPlaying:
            await waitForRestoredQueue(app: app)
            if app.player.hasSomethingToShow { app.isNowPlayingPresented = true }
        case .playRecent(let id):
            let recent = app.core.recentlyPlayed.items.value.isEmpty
                ? (try? await app.core.recentlyPlayed.fetch()) ?? []
                : app.core.recentlyPlayed.items.value
            if let playable = recent.first(where: { $0.id == id }) {
                app.player.play(playable)
            }
        }
    }

    private static func perform(_ kind: Kind, app: AppModel) async {
        switch kind {
        case .search:
            app.openSearch()
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

    private static func resumeQueue(app: AppModel) async {
        await waitForRestoredQueue(app: app)
        if !app.player.state.queue.isEmpty { app.player.controller.play() }
    }

    /// On a cold launch the saved queue is restored after data loads; give it a moment.
    private static func waitForRestoredQueue(app: AppModel) async {
        for _ in 0..<50 where app.player.state.queue.isEmpty {
            try? await Task.sleep(for: .milliseconds(100))
        }
    }

    private static func keepShortcutsCurrent(app: AppModel) async {
        for await state in app.core.player.state {
            UIApplication.shared.shortcutItems = items(recent: state.current)
        }
    }

    static func items(recent: (any Playable)?) -> [UIApplicationShortcutItem] {
        var items = [
            UIApplicationShortcutItem(type: Kind.search.rawValue, localizedTitle: "Search", localizedSubtitle: nil, icon: .init(type: .search)),
            UIApplicationShortcutItem(type: Kind.playFavorites.rawValue, localizedTitle: "Play Favorite Songs", localizedSubtitle: nil, icon: .init(systemImageName: "heart.fill")),
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
    /// A widget button can launch the app in the background with no scene; its intent needs the
    /// player set up to act on.
    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]? = nil) -> Bool {
        #if DEBUG
        if UITestLaunch.isRunning { UIView.setAnimationsEnabled(false) }
        #endif
        _ = AppModel.shared
        return true
    }

    func application(
        _ application: UIApplication,
        configurationForConnecting connectingSceneSession: UISceneSession,
        options: UIScene.ConnectionOptions
    ) -> UISceneConfiguration {
        if let shortcut = options.shortcutItem { QuickActions.receive(shortcut) }
        let configuration = UISceneConfiguration(name: nil, sessionRole: connectingSceneSession.role)
        configuration.delegateClass = connectingSceneSession.role == .carTemplateApplication ? CarPlaySceneDelegate.self : SceneDelegate.self
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
