import SwiftUI

struct RootView: View {
    @Environment(AppModel.self) private var app

    var body: some View {
        Group {
            switch app.phase {
            case .launching:
                ProgressView()
                    .controlSize(.large)
                    .task { await app.launch() }
            case .noConnection:
                NoConnectionView()
            case .login:
                LoginView()
            case .loading:
                DataLoadingView()
            case .main:
                MainView()
            case .offline:
                OfflineView()
            }
        }
        .animation(.default, value: app.phase)
    }
}
