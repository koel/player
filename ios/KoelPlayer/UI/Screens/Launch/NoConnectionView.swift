import SwiftUI

struct NoConnectionView: View {
    @Environment(AppModel.self) private var app

    var body: some View {
        ContentUnavailableView {
            Label("You Are Offline", systemImage: "wifi.slash")
        } description: {
            Text("Please connect to the internet and try again.")
        } actions: {
            Button("View Downloaded Songs", action: app.goOffline)
                .buttonStyle(.glassProminent)
        }
        .onChange(of: app.connectivity.isOnline) { _, isOnline in
            if isOnline { app.reconnect() }
        }
    }
}
