import Foundation
import Observation
import UIKit
@preconcurrency import Shared

@Observable
final class AppModel {
    /// One for the phone and CarPlay screens alike.
    static let shared = AppModel()

    enum Phase: Equatable {
        case launching
        case noConnection
        case login
        case loading
        case main
        /// Only downloaded songs, after the user chose to keep listening without a connection.
        case offline

        var isWithoutServer: Bool { self == .offline || self == .noConnection }
    }

    private(set) var phase = Phase.launching {
        didSet { core.isOffline = phase.isWithoutServer }
    }

    let core: KoelCore
    let player: PlayerModel
    let navigator = Navigator()
    let toasts = Toasts()
    let connectivity = Connectivity()
    let downloadedIds: Live<Set<String>>
    let downloadingIds: Live<Set<String>>
    var sheet: AppSheet?
    var isNowPlayingPresented = false
    @ObservationIgnored private let mediaControls: SystemMediaControls
    @ObservationIgnored private let widgets: WidgetPublisher
    @ObservationIgnored private let launches = SingleFlight()

    init() {
        AudioSession.configure()

        let documents = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
        core = KoelCoreFactoryKt.createKoelCore(
            keyValueStore: NativeKeyValueStore(),
            documentsPath: documents.path(percentEncoded: false),
            audioEngine: AVPlayerEngine()
        )
        player = PlayerModel(controller: core.player)
        mediaControls = SystemMediaControls(player: core.player)
        widgets = WidgetPublisher(player: core.player, recentlyPlayed: core.recentlyPlayed)
        downloadedIds = Live(core.downloads.downloadedIds)
        downloadingIds = Live(core.downloads.downloading)
        Task { [downloads = core.downloads] in
            for await _ in downloads.downloadedIds { DownloadsBackupExclusion.apply(in: documents) }
        }
        Task { await reconnectWhenOnline() }
    }

    var isOffline: Bool { phase == .offline }

    func isDownloaded(_ playable: any Playable) -> Bool {
        downloadedIds.value.contains(playable.id)
    }

    func isDownloading(_ playable: any Playable) -> Bool {
        downloadingIds.value.contains(playable.id)
    }

    func launch() async {
        await launches.run { [self] in await checkSession() }
    }

    private func checkSession() async {
        core.migrateFlutterData()
        #if DEBUG
        await startUITestSessionIfAsked()
        #endif

        guard await connectivity.currentStatus() else {
            phase = .noConnection
            return
        }

        do {
            if try await core.auth.fetchCurrentUser() == nil {
                showLogin()
            } else {
                phase = .loading
            }
        } catch {
            phase = await connectivity.currentStatus() ? .loading : .noConnection
        }
    }

    /// Loads the library, checking the login again first when the server failed to confirm it at launch.
    func loadLibrary() async throws {
        if core.auth.currentUser.value == nil, try await core.auth.fetchCurrentUser() == nil {
            showLogin()
            return
        }
        try await core.loadData()
        phase = .main
    }

    /// CarPlay can start the app while the phone stays locked, with no screen to run the usual
    /// launch and library load.
    func launchWithoutScreen() async {
        if phase == .launching { await launch() }
        guard phase == .loading else { return }

        do {
            try await loadLibrary()
        } catch {
            if phase == .loading && !isScreenShown { phase = .offline }
        }
    }

    func didLogIn() {
        phase = .loading
    }

    func goOffline() {
        phase = .offline
    }

    /// Back online after browsing downloads offline: start over to load the library.
    func reconnect() {
        phase = .launching
    }

    private func reconnectWhenOnline() async {
        for await isOnline in Observations({ self.connectivity.isOnline }) where isOnline {
            await reconnectIfStranded()
        }
    }

    func reconnectIfStranded() async {
        guard connectivity.isOnline, Self.reconnectsOnceOnline(from: phase, isScreenShown: isScreenShown) else { return }
        if isScreenShown {
            reconnect()
        } else {
            phase = .launching
            await launchWithoutScreen()
        }
    }

    /// The phone screen shows its own "Connection restored" prompt while offline.
    static func reconnectsOnceOnline(from phase: Phase, isScreenShown: Bool) -> Bool {
        phase == .noConnection || (phase == .offline && !isScreenShown)
    }

    var isScreenShown: Bool {
        UIApplication.shared.connectedScenes.contains { scene in
            scene.session.role == .windowApplication
                && [.foregroundActive, .foregroundInactive].contains(scene.activationState)
        }
    }

    #if DEBUG
    /// UI tests hand over their mock server's host, and its token to start logged in.
    private func startUITestSessionIfAsked() async {
        guard let host = UITestLaunch.host else { return }
        try? await core.logout()
        navigator.reset()
        guard let token = UITestLaunch.token else { return }
        core.auth.startSession(host: host, apiToken: token, audioToken: token)
    }
    #endif

    func logOut() async {
        try? await core.logout()
        showLogin()
    }

    /// Whoever logs in next starts from Home rather than the previous session's screens.
    private func showLogin() {
        navigator.reset()
        sheet = nil
        isNowPlayingPresented = false
        phase = .login
    }

    /// Now Playing covers the tabs, so it closes for the pushed screen to show.
    func open(_ route: Route) {
        isNowPlayingPresented = false
        navigator.push(route)
    }

    func openSearch() {
        isNowPlayingPresented = false
        navigator.focusSearch()
    }
}

#if DEBUG
/// What UI tests pass at launch to skip the login form.
enum UITestLaunch {
    static var host: String? { ProcessInfo.processInfo.environment["KOEL_UI_TEST_HOST"] }
    static var token: String? { ProcessInfo.processInfo.environment["KOEL_UI_TEST_TOKEN"] }
    static var isRunning: Bool { host != nil }
}
#endif
