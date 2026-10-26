import SwiftUI

struct RootView: View {
    @Environment(AppModel.self) private var app

    var body: some View {
        Group {
            switch app.phase {
            case .launching:
                LaunchLogo()
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
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background { BrandMeshBackground() }
        .animation(.default, value: app.phase)
        .modifier(NowPlayingBrandColor())
        .onOpenURL { QuickActions.receive($0) }
        .task { await QuickActions.handle(app: app) }
    }
}
