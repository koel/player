import XCTest

/// Drives the real app against a real Koel server. Runs only when the server is given:
/// `TEST_RUNNER_KOEL_E2E_HOST=… TEST_RUNNER_KOEL_E2E_EMAIL=… TEST_RUNNER_KOEL_E2E_PASSWORD=… xcodebuild test …`
final class SmokeTests: XCTestCase {
    private var app: XCUIApplication!

    override func setUpWithError() throws {
        continueAfterFailure = false
        app = XCUIApplication()
        app.launch()
    }

    func testLogInSearchPlayAndLogOut() throws {
        let server = try E2EServer.fromEnvironment()

        logInIfNeeded(app, to: server)
        attachScreenshot(of: app, named: "Home")

        let searchField = app.searchFields.firstMatch
        for _ in 0..<5 where !searchField.waitForExistence(timeout: 2) {
            app.tabBars.buttons["Search"].tap()
        }
        XCTAssertTrue(searchField.exists, "Couldn't switch to the Search tab")
        searchField.tap()
        searchField.typeText(server.searchTerm + "\n")

        let firstSong = app.buttons.matching(NSPredicate(format: "label CONTAINS[c] %@", server.searchTerm)).firstMatch
        XCTAssertTrue(firstSong.waitForExistence(timeout: 15), "No search results for \(server.searchTerm)")
        attachScreenshot(of: app, named: "Search")
        firstSong.tap()

        let pause = app.buttons["Pause"].firstMatch
        XCTAssertTrue(pause.waitForExistence(timeout: 20), "Playback never started")
        attachScreenshot(of: app, named: "Playing")
        pause.tap()

        select(tab: "Home", in: app)
        app.buttons["Profile"].firstMatch.tap()
        app.buttons["Log out"].firstMatch.tap()
        app.alerts.buttons["Confirm"].firstMatch.tap()
        XCTAssertTrue(app.textFields["Host"].waitForExistence(timeout: 15), "Logging out didn't return to the login screen")
    }
}
