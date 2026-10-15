import Foundation
@testable import KoelPlayer
import Testing

struct NavigatorTests {
    private let defaults = UserDefaults(suiteName: "NavigatorTests-\(UUID().uuidString)")!

    @Test func restoresTabsAndStacksAfterRelaunch() {
        let navigator = Navigator(defaults: defaults)
        navigator.select(.library)
        navigator.push(.albums)
        navigator.push(.album(id: "a1"))
        navigator.select(.home)
        navigator.push(.genre(id: "g1", name: "Rock"))

        let relaunched = Navigator(defaults: defaults)

        #expect(relaunched.selectedTab == .home)
        #expect(relaunched.paths[.library] == [.albums, .album(id: "a1")])
        #expect(relaunched.paths[.home] == [.genre(id: "g1", name: "Rock")])
    }

    @Test func tappingTheSelectedTabPopsToRoot() {
        let navigator = Navigator(defaults: defaults)
        navigator.select(.library)
        navigator.push(.artists)

        navigator.select(.library)

        #expect(navigator.paths[.library] == [])
        #expect(navigator.selectedTab == .library)
    }

    @Test func focusingSearchSwitchesToTheSearchTab() {
        let navigator = Navigator(defaults: defaults)

        navigator.focusSearch()

        #expect(navigator.selectedTab == .search)
        #expect(navigator.wantsSearchFocus)
    }
}
