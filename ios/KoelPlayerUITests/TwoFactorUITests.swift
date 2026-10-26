import XCTest

/// Logging in to a `MockKoelServer` that asks for a two-factor code.
final class TwoFactorUITests: XCTestCase {
    private var app: XCUIApplication!
    private var server: MockKoelServer!

    override func setUpWithError() throws {
        continueAfterFailure = false
        server = try MockKoelServer()
        server.requiresTwoFactor = true
        try server.start()
        app = XCUIApplication()
        app.launchEnvironment["KOEL_UI_TEST_HOST"] = server.host
        app.launch()
    }

    override func tearDown() {
        server?.stop()
    }

    func testTypingTheSixDigitsSendsTheCode() {
        submitLogIn(app, to: server)
        let codeField = app.textFields["Authentication code"]
        XCTAssertTrue(codeField.waitForExistence(timeout: 15), "The two-factor screen never appeared")
        dismissSavePasswordPrompt(app)

        codeField.tap()
        codeField.typeText("123456")

        XCTAssertTrue(app.tabBars.buttons["Home"].waitForExistence(timeout: 30), "Six digits never logged in")
        XCTAssertEqual(server.twoFactorCode, "123456")
    }
}
