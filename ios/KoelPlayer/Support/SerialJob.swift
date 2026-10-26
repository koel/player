/// Runs a job one run at a time. Requests made during a run fold into a single run after it, so
/// the last run always starts after the latest request.
final class SerialJob {
    private let requests: AsyncStream<Void>.Continuation
    private let worker: Task<Void, Never>

    init(_ job: @escaping () async -> Void) {
        let (stream, requests) = AsyncStream.makeStream(of: Void.self, bufferingPolicy: .bufferingNewest(1))
        self.requests = requests
        worker = Task {
            for await _ in stream { await job() }
        }
    }

    isolated deinit {
        requests.finish()
        worker.cancel()
    }

    func request() {
        requests.yield()
    }
}
