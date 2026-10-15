import Foundation
import Observation
import Shared

@Observable
final class AppModel {
    enum Phase: Equatable {
        case launching
        case noConnection
        case login
        case loading
        case main
        /// Only downloaded songs, after the user chose to keep listening without a connection.
        case offline
    }

    private(set) var phase = Phase.launching

    let core: KoelCore
    let connectivity = Connectivity()
    let mediaControls: SystemMediaControls

    init() {
        AudioSession.configure()

        let documents = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
        core = KoelCoreFactoryKt.createKoelCore(
            keyValueStore: NativeKeyValueStore(),
            documentsPath: documents.path(percentEncoded: false),
            audioEngine: AVPlayerEngine()
        )
        mediaControls = SystemMediaControls(player: core.player)
    }

    var isOffline: Bool { phase == .offline }

    func launch() async {
        core.migrateFlutterData()

        guard await connectivity.currentStatus() else {
            phase = .noConnection
            return
        }

        do {
            phase = try await core.auth.fetchCurrentUser() == nil ? .login : .loading
        } catch {
            phase = .login
        }
    }

    func didLogIn() {
        phase = .loading
    }

    func didLoadData() {
        phase = .main
    }

    func goOffline() {
        phase = .offline
    }

    /// Back online after browsing downloads offline: start over to load the library.
    func reconnect() {
        phase = .launching
        Task { await launch() }
    }

    func logOut() async {
        try? await core.logout()
        phase = .login
    }
}
