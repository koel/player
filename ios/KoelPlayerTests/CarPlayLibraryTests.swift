@testable import KoelPlayer
import Testing

@MainActor
struct CarPlayLibraryTests {
    @Test func offersTheFullLibraryOnceLoaded() {
        #expect(CarPlayLibrary.root(for: .main, replacing: .message("Loading…")) == .library)
    }

    @Test func offersDownloadsWithoutAConnection() {
        #expect(CarPlayLibrary.root(for: .noConnection, replacing: nil) == .downloads)
        #expect(CarPlayLibrary.root(for: .offline, replacing: nil) == .downloads)
    }

    @Test func asksToLogInOnThePhoneWhenLoggedOut() {
        #expect(CarPlayLibrary.root(for: .login, replacing: nil) == .message("Log in on your iPhone to start listening."))
    }

    @Test func waitsWhileLaunchingOrLoading() {
        #expect(CarPlayLibrary.root(for: .launching, replacing: nil) == .message("Loading…"))
        #expect(CarPlayLibrary.root(for: .loading, replacing: .message("Log in on your iPhone to start listening.")) == .message("Loading…"))
    }

    @Test func keepsDownloadsOnScreenWhileReconnecting() {
        #expect(CarPlayLibrary.root(for: .launching, replacing: .downloads) == .downloads)
        #expect(CarPlayLibrary.root(for: .loading, replacing: .downloads) == .downloads)
        #expect(CarPlayLibrary.root(for: .main, replacing: .downloads) == .library)
    }
}
