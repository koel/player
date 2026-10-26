import XCTest

/// A real Koel server to test against, given through the environment.
struct E2EServer {
    let host: String
    let email: String
    let password: String
    let searchTerm: String

    static func fromEnvironment() throws -> E2EServer {
        let environment = ProcessInfo.processInfo.environment
        guard let host = environment["KOEL_E2E_HOST"],
              let email = environment["KOEL_E2E_EMAIL"],
              let password = environment["KOEL_E2E_PASSWORD"]
        else { throw XCTSkip("Set KOEL_E2E_HOST, KOEL_E2E_EMAIL and KOEL_E2E_PASSWORD to run against a server.") }
        return E2EServer(host: host, email: email, password: password, searchTerm: environment["KOEL_E2E_SEARCH"] ?? "love")
    }
}

extension XCTestCase {
    func logInIfNeeded(_ app: XCUIApplication, to server: E2EServer) {
        let homeTab = app.tabBars.buttons["Home"]
        if !homeTab.waitForExistence(timeout: 10) {
            let host = app.textFields["Host"]
            XCTAssertTrue(host.waitForExistence(timeout: 15), "The login screen never appeared")
            replaceText(in: host, with: server.host)
            replaceText(in: app.textFields["Email"], with: server.email)
            app.secureTextFields["Password"].tap()
            app.secureTextFields["Password"].typeText(server.password)
            app.buttons["Log In"].tap()
        }
        XCTAssertTrue(homeTab.waitForExistence(timeout: 30), "The main UI never appeared")
    }

    /// Starts the app already logged in to the mock server, skipping the login form.
    func launchLoggedIn(_ app: XCUIApplication, to server: MockKoelServer) {
        app.launchEnvironment["KOEL_UI_TEST_HOST"] = server.host
        app.launchEnvironment["KOEL_UI_TEST_TOKEN"] = MockKoelServer.token
        app.launch()
        XCTAssertTrue(app.tabBars.buttons["Home"].waitForExistence(timeout: 30), "The main UI never appeared")
    }

    /// Starts from the login screen, logging out of whatever server the app last used, and taps Log In.
    func submitLogIn(_ app: XCUIApplication, to server: MockKoelServer) {
        let homeTab = app.tabBars.buttons["Home"]
        let host = app.textFields["Host"]
        if homeTab.waitForExistence(timeout: 10) {
            select(tab: "Home", in: app)
            app.buttons["Profile"].firstMatch.tap()
            app.buttons["Log out"].firstMatch.tap()
            app.alerts.buttons["Confirm"].firstMatch.tap()
        }
        XCTAssertTrue(host.waitForExistence(timeout: 15), "The login screen never appeared")
        replaceText(in: host, with: server.host)
        replaceText(in: app.textFields["Email"], with: MockKoelServer.email)
        app.secureTextFields["Password"].tap()
        app.secureTextFields["Password"].typeText(MockKoelServer.password)
        app.buttons["Log In"].tap()
    }

    /// iOS offers to save the password after logging in, and the prompt swallows the next tap.
    func dismissSavePasswordPrompt(_ app: XCUIApplication) {
        let notNow = app.buttons["Not Now"]
        if notNow.waitForExistence(timeout: 3) { notNow.tap() }
    }

    func replaceText(in field: XCUIElement, with text: String) {
        field.coordinate(withNormalizedOffset: CGVector(dx: 0.98, dy: 0.5)).tap()
        if let current = field.value as? String, !current.isEmpty, current != field.placeholderValue {
            field.typeText(String(repeating: XCUIKeyboardKey.delete.rawValue, count: current.count))
        }
        field.typeText(text)
    }

    func attachScreenshot(of app: XCUIApplication, named name: String) {
        let attachment = XCTAttachment(screenshot: app.screenshot())
        attachment.name = name
        attachment.lifetime = .keepAlways
        add(attachment)
    }

    /// Taps made while the main UI is still settling in after logging in can get lost, so this
    /// taps until the tab is really selected.
    func select(tab name: String, in app: XCUIApplication) {
        let tab = app.tabBars.buttons[name]
        for _ in 0..<5 where !(tab.exists && tab.isSelected) {
            if tab.exists { tab.tap() } else { app.tabBars.buttons.firstMatch.tap() }
            _ = tab.waitForExistence(timeout: 1)
        }
        XCTAssertTrue(tab.exists && tab.isSelected, "Couldn't switch to the \(name) tab")
    }

    /// Tabs remember where they were; tapping the selected tab again backs out to its root.
    func selectRoot(ofTab name: String, in app: XCUIApplication) {
        select(tab: name, in: app)
        app.tabBars.buttons[name].tap()
    }

    /// The Library tab remembers where it was, so this backs out to its root before picking a list.
    func openLibraryList(_ app: XCUIApplication, named name: String) {
        select(tab: "Library", in: app)
        let destination = app.collectionViews.buttons[name].firstMatch
        for _ in 0..<3 where !destination.waitForExistence(timeout: 3) {
            app.navigationBars.buttons.element(boundBy: 0).tap()
        }
        XCTAssertTrue(destination.waitForExistence(timeout: 10), "\(name) never showed in the Library")
        destination.tap()
    }
}
