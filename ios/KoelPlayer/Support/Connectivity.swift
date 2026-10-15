import Network
import Observation

@Observable
final class Connectivity {
    private(set) var isOnline = true

    @ObservationIgnored private let monitor = NWPathMonitor()

    init() {
        monitor.pathUpdateHandler = { [weak self] path in
            let online = path.status == .satisfied
            Task { @MainActor in self?.isOnline = online }
        }
        monitor.start(queue: DispatchQueue(label: "dev.koel.connectivity"))
    }

    /// The first path update arrives asynchronously; launch logic waits for it.
    func currentStatus() async -> Bool {
        await withCheckedContinuation { continuation in
            let probe = NWPathMonitor()
            probe.pathUpdateHandler = { path in
                probe.cancel()
                continuation.resume(returning: path.status == .satisfied)
            }
            probe.start(queue: DispatchQueue(label: "dev.koel.connectivity.probe"))
        }
    }

    isolated deinit {
        monitor.cancel()
    }
}
