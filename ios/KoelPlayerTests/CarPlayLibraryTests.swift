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

    @Test func loadsPagesUntilTheListIsFull() async throws {
        var loaded = 0

        try await CarPlayLibrary.loadPages(upTo: 100, loadedCount: { loaded }, hasMore: { true }) { loaded += 30 }

        #expect(loaded == 120)
    }

    @Test func stopsLoadingPagesWhenTheListEnds() async throws {
        var loaded = 0

        try await CarPlayLibrary.loadPages(upTo: 100, loadedCount: { loaded }, hasMore: { loaded < 45 }) { loaded += 30 }

        #expect(loaded == 60)
    }

    @Test func stopsLoadingPagesThatAddNothing() async throws {
        var requests = 0

        try await CarPlayLibrary.loadPages(upTo: 100, loadedCount: { 10 }, hasMore: { true }) { requests += 1 }

        #expect(requests == 1)
    }
}
