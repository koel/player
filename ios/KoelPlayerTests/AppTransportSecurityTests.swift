import Foundation
@testable import KoelPlayer
import Testing

struct AppTransportSecurityTests {
    @Test func allowsPlainHttpForSelfHostedServersAndRadioStreams() throws {
        let settings = try #require(Bundle(for: AppModel.self).object(forInfoDictionaryKey: "NSAppTransportSecurity") as? [String: Any])

        #expect(settings["NSAllowsArbitraryLoads"] as? Bool == true)
        #expect(settings["NSAllowsLocalNetworking"] == nil)
    }
}
