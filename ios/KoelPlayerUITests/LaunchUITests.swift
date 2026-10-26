import XCTest

final class LaunchUITests: XCTestCase {
    private var server: MockKoelServer!

    override func setUpWithError() throws {
        continueAfterFailure = false
        server = try MockKoelServer()
        server.checksLoginSlowly = true
        try server.start()
    }

    override func tearDown() {
        server?.stop()
    }

    func testTheLogoShowsWhileTheLoginIsChecked() {
        let app = launch(host: server.host)

        XCTAssertTrue(app.images["launch-logo"].waitForExistence(timeout: 5), "No logo while checking the login")
        XCTAssertTrue(app.tabBars.buttons["Home"].waitForExistence(timeout: 30), "The main UI never appeared")
    }

    func testAnUnreachableServerOffersARetryInsteadOfTheLogin() {
        let host = server.host
        server.stop()

        let app = launch(host: host)

        XCTAssertTrue(app.buttons["Retry"].waitForExistence(timeout: 30), "No Retry for an unreachable server")
        XCTAssertFalse(app.buttons["Log In"].exists)
        XCTAssertFalse(app.staticTexts["You are offline."].exists)
    }

    func testAServerErrorAtLaunchCanBeRetriedOnceTheServerIsBack() {
        server.failsWithServerError = true

        let app = launch(host: server.host)

        XCTAssertTrue(app.buttons["Retry"].waitForExistence(timeout: 30), "No Retry after a server error")
        XCTAssertTrue(app.buttons["Log Out"].exists)
        XCTAssertFalse(app.staticTexts["You are offline."].exists)

        server.failsWithServerError = false
        app.buttons["Retry"].tap()

        XCTAssertTrue(app.tabBars.buttons["Home"].waitForExistence(timeout: 30), "Retry never reached the main UI")
    }

    func testARejectedSessionAsksToLogIn() {
        server.rejectsSession = true

        let app = launch(host: server.host)

        XCTAssertTrue(app.buttons["Log In"].waitForExistence(timeout: 30), "The login form never appeared")
    }

    func testLoggingInAfterARejectedSessionStartsFromHome() {
        server.checksLoginSlowly = false
        let app = XCUIApplication()
        launchLoggedIn(app, to: server)
        openLibraryList(app, named: "Albums")
        XCTAssertTrue(app.navigationBars["Albums"].firstMatch.waitForExistence(timeout: 10))
        app.terminate()

        server.rejectsSession = true
        app.launchEnvironment = [:]
        app.launch()
        XCTAssertTrue(app.buttons["Log In"].waitForExistence(timeout: 30), "The login form never appeared")
        server.rejectsSession = false
        submitLogIn(app, to: server)
        dismissSavePasswordPrompt(app)

        XCTAssertTrue(app.tabBars.buttons["Home"].waitForExistence(timeout: 30), "The main UI never appeared")
        XCTAssertTrue(app.tabBars.buttons["Home"].isSelected, "Logging in again didn't start from Home")
        select(tab: "Library", in: app)
        XCTAssertFalse(app.navigationBars["Albums"].firstMatch.waitForExistence(timeout: 2), "The rejected session's screens came back")
    }

    private func launch(host: String) -> XCUIApplication {
        let app = XCUIApplication()
        app.launchEnvironment["KOEL_UI_TEST_HOST"] = host
        app.launchEnvironment["KOEL_UI_TEST_TOKEN"] = MockKoelServer.token
        app.launch()
        return app
    }
}
