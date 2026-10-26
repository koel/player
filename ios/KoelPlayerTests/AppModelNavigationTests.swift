@testable import KoelPlayer
import Testing

@MainActor
struct AppModelNavigationTests {
    private let app = AppModel.shared

    @Test func openingAScreenClosesNowPlaying() {
        defer { app.navigator.reset() }
        app.isNowPlayingPresented = true

        app.open(.album(id: "a1"))

        #expect(!app.isNowPlayingPresented)
        #expect(app.navigator.paths[app.navigator.selectedTab]?.last == .album(id: "a1"))
    }

    @Test func openingSearchClosesNowPlaying() {
        defer { app.navigator.reset() }
        app.isNowPlayingPresented = true

        app.openSearch()

        #expect(!app.isNowPlayingPresented)
        #expect(app.navigator.selectedTab == .search)
    }
}
