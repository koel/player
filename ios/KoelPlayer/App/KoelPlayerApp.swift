import SwiftUI

@main
struct KoelPlayerApp: App {
    @UIApplicationDelegateAdaptor private var appDelegate: AppDelegate
    @State private var app = AppModel()

    var body: some Scene {
        WindowGroup {
            RootView()
                .environment(app)
                .preferredColorScheme(.dark)
        }
    }
}
