@testable import KoelPlayer
import Testing

@MainActor
struct SingleFlightTests {
    @Test func aCallerArrivingMidRunJoinsItInsteadOfStartingAnother() async {
        let flight = SingleFlight()
        var runs = 0
        let job = {
            runs += 1
            try? await Task.sleep(for: .milliseconds(100))
        }

        let first = Task { await flight.run(job) }
        let second = Task { await flight.run(job) }
        await first.value
        await second.value

        #expect(runs == 1)
    }

    @Test func runsAgainOnceThePreviousRunHasFinished() async {
        let flight = SingleFlight()
        var runs = 0

        await flight.run { runs += 1 }
        await flight.run { runs += 1 }

        #expect(runs == 2)
    }
}
