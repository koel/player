import XCTest

/// Taps from the Library into an album and back, for screen recordings of transitions.
/// Runs only with `TEST_RUNNER_KOEL_TOUR=1`, against an app that is already logged in.
final class NavigationTour: XCTestCase {
    func testOpenAlbumFromLibrary() throws {
        guard ProcessInfo.processInfo.environment["KOEL_TOUR"] == "1" else { throw XCTSkip("Set KOEL_TOUR=1 to run.") }

        let app = XCUIApplication()
        app.launch()

        let library = app.tabBars.buttons["Library"]
        XCTAssertTrue(library.waitForExistence(timeout: 20))
        library.tap()
        library.tap()

        app.buttons["Albums"].firstMatch.tap()
        let firstAlbum = app.scrollViews.buttons.element(boundBy: 0)
        XCTAssertTrue(firstAlbum.waitForExistence(timeout: 15))
        sleep(2)
        firstAlbum.tap()
        sleep(4)
        app.navigationBars.buttons.element(boundBy: 0).tap()
        sleep(1)
        app.buttons["Favorites"].firstMatch.tapIfVisible()
        sleep(3)
    }
}

extension NavigationTour {
    func testOpenNowPlaying() throws {
        guard ProcessInfo.processInfo.environment["KOEL_TOUR"] == "1" else { throw XCTSkip("Set KOEL_TOUR=1 to run.") }

        let app = XCUIApplication()
        app.launch()

        let next = app.buttons["Next"].firstMatch
        XCTAssertTrue(next.waitForExistence(timeout: 20))
        next.coordinate(withNormalizedOffset: CGVector(dx: -4, dy: 0.5)).tap()
        sleep(8)
    }
}

private extension XCUIElement {
    func tapIfVisible() {
        if exists { tap() }
    }
}
