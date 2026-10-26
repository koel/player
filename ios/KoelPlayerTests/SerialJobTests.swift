@testable import KoelPlayer
import Testing

@MainActor
struct SerialJobTests {
    @Test func requestsDuringARunFoldIntoOneRunAfterIt() async {
        var runs = 0
        var running = 0
        var overlapped = false
        let (finished, finish) = AsyncStream<Void>.makeStream()
        let job = SerialJob {
            running += 1
            overlapped = overlapped || running > 1
            try? await Task.sleep(for: .milliseconds(50))
            runs += 1
            running -= 1
            finish.yield()
        }

        job.request()
        while running == 0 { await Task.yield() }
        job.request()
        job.request()
        var iterator = finished.makeAsyncIterator()
        await iterator.next()
        await iterator.next()
        try? await Task.sleep(for: .milliseconds(150))

        #expect(runs == 2)
        #expect(!overlapped)
    }
}
