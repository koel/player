@testable import KoelPlayer
import Testing

@MainActor
struct AppModelPhaseTests {
    @Test func reconnectsOnItsOwnWithoutAConnectionOrWithoutTheScreen() {
        #expect(AppModel.reconnectsOnceOnline(from: .noConnection, isScreenShown: true))
        #expect(AppModel.reconnectsOnceOnline(from: .noConnection, isScreenShown: false))
        #expect(AppModel.reconnectsOnceOnline(from: .offline, isScreenShown: false))
    }

    @Test func leavesReconnectingFromDownloadsToThePhoneUser() {
        #expect(!AppModel.reconnectsOnceOnline(from: .offline, isScreenShown: true))
        #expect(!AppModel.reconnectsOnceOnline(from: .main, isScreenShown: false))
        #expect(!AppModel.reconnectsOnceOnline(from: .login, isScreenShown: false))
    }

    @Test func onlyTheOfflinePhasesWorkWithoutTheServer() {
        #expect(AppModel.Phase.offline.isWithoutServer)
        #expect(AppModel.Phase.noConnection.isWithoutServer)
        #expect(!AppModel.Phase.main.isWithoutServer)
        #expect(!AppModel.Phase.loading.isWithoutServer)
        #expect(!AppModel.Phase.login.isWithoutServer)
    }

    @Test func tellsTheCoreWhenItGoesOffline() {
        let app = AppModel.shared

        app.goOffline()
        #expect(app.core.isOffline)

        app.reconnect()
        #expect(!app.core.isOffline)
    }
}
