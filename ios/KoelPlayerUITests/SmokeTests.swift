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
        let server = try Server.fromEnvironment()

        let homeTab = app.tabBars.buttons["Home"]
        if !homeTab.waitForExistence(timeout: 10) {
            logIn(to: server)
        }
        XCTAssertTrue(homeTab.waitForExistence(timeout: 30), "The main UI never appeared")
        attachScreenshot("Home")

        let searchTab = app.tabBars.buttons["Search"]
        if !searchTab.exists { app.tabBars.buttons.firstMatch.tap() }
        searchTab.tap()
        let searchField = app.searchFields.firstMatch
        XCTAssertTrue(searchField.waitForExistence(timeout: 5))
        searchField.tap()
        searchField.typeText(server.searchTerm + "\n")

        let firstSong = app.buttons.matching(NSPredicate(format: "label CONTAINS[c] %@", server.searchTerm)).firstMatch
        XCTAssertTrue(firstSong.waitForExistence(timeout: 15), "No search results for \(server.searchTerm)")
        attachScreenshot("Search")
        firstSong.tap()

        let pause = app.buttons["Pause"].firstMatch
        XCTAssertTrue(pause.waitForExistence(timeout: 20), "Playback never started")
        attachScreenshot("Playing")
        pause.tap()

        homeTab.tap()
        app.buttons["Profile"].firstMatch.tap()
        app.buttons["Log Out"].firstMatch.tap()
        app.alerts.buttons["Log Out"].firstMatch.tap()
        XCTAssertTrue(app.textFields["Host"].waitForExistence(timeout: 15), "Logging out didn't return to the login screen")
    }

    private func logIn(to server: Server) {
        let host = app.textFields["Host"]
        XCTAssertTrue(host.waitForExistence(timeout: 15), "The login screen never appeared")

        replaceText(in: host, with: server.host)
        replaceText(in: app.textFields["Email"], with: server.email)
        app.secureTextFields["Password"].tap()
        app.secureTextFields["Password"].typeText(server.password)
        attachScreenshot("Login")
        app.buttons["Log In"].tap()
    }

    private func replaceText(in field: XCUIElement, with text: String) {
        field.tap()
        if let current = field.value as? String, !current.isEmpty, current != field.placeholderValue {
            field.typeText(String(repeating: XCUIKeyboardKey.delete.rawValue, count: current.count))
        }
        field.typeText(text)
    }

    private func attachScreenshot(_ name: String) {
        let attachment = XCTAttachment(screenshot: app.screenshot())
        attachment.name = name
        attachment.lifetime = .keepAlways
        add(attachment)
    }

    private struct Server {
        let host: String
        let email: String
        let password: String
        let searchTerm: String

        static func fromEnvironment() throws -> Server {
            let environment = ProcessInfo.processInfo.environment
            guard let host = environment["KOEL_E2E_HOST"],
                  let email = environment["KOEL_E2E_EMAIL"],
                  let password = environment["KOEL_E2E_PASSWORD"]
            else { throw XCTSkip("Set KOEL_E2E_HOST, KOEL_E2E_EMAIL and KOEL_E2E_PASSWORD to run against a server.") }
            return Server(host: host, email: email, password: password, searchTerm: environment["KOEL_E2E_SEARCH"] ?? "love")
        }
    }
}
