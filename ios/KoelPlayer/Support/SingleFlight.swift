/// Runs one job at a time: a caller that arrives while it runs waits for that same run.
final class SingleFlight {
    private var running: Task<Void, Never>?

    func run(_ job: @escaping () async -> Void) async {
        if running == nil {
            running = Task {
                await job()
                running = nil
            }
        }
        await running?.value
    }
}
