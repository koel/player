@testable import KoelPlayer
import Testing

@MainActor
struct ToastsTests {
    @Test func showsCaptionAndMessageWithTheDefaultCheckmark() {
        let toasts = Toasts()

        toasts.show("Queued", message: "To be played next.")

        #expect(toasts.current?.caption == "Queued")
        #expect(toasts.current?.message == "To be played next.")
        #expect(toasts.current?.systemImage == "checkmark.circle.fill")
    }

    @Test func errorsKeepAnErrorIcon() {
        let toasts = Toasts()

        toasts.showError(message: "Could not play station.")

        #expect(toasts.current?.caption == "Error")
        #expect(toasts.current?.message == "Could not play station.")
        #expect(toasts.current?.systemImage == "exclamationmark.triangle")
    }

    @Test func staysUpForTwoSecondsByDefault() {
        #expect(Toasts.defaultDuration == .seconds(2))
    }

    @Test func goesAwayAfterItsDuration() async throws {
        let toasts = Toasts(duration: .milliseconds(50))

        toasts.show("Added", message: "Item added to playlist.")
        try await Task.sleep(for: .milliseconds(300))

        #expect(toasts.current == nil)
    }

    @Test func tappingDismissesIt() {
        let toasts = Toasts()
        toasts.show("Removed", message: "Removed from queue.")

        toasts.dismiss()

        #expect(toasts.current == nil)
    }
}
