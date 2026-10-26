import SwiftUI

struct NoConnectionView: View {
    @Environment(AppModel.self) private var app

    var body: some View {
        ContentUnavailableView {
            Label("You are offline.", systemImage: "wifi.slash")
        } description: {
            Text("Please connect to the internet and try again.")
        } actions: {
            Button("View downloaded songs", action: app.goOffline)
                .buttonStyle(.glass)
        }
        .background { BrandMeshBackground() }
    }
}
