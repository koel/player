@preconcurrency import Shared
import SwiftUI

/// Downloads only, for listening without a connection, with the mini player and a connectivity banner.
struct OfflineView: View {
    @Environment(AppModel.self) private var app
    @Namespace private var nowPlayingTransition

    var body: some View {
        @Bindable var app = app

        NavigationStack {
            DownloadsView()
        }
        .safeAreaInset(edge: .bottom) {
            VStack(spacing: 12) {
                if app.player.hasSomethingToShow {
                    MiniPlayer()
                        .frame(height: 56)
                        .glassEffect(.regular.interactive(), in: .capsule)
                        .matchedTransitionSource(id: "now-playing", in: nowPlayingTransition)
                }
                ConnectivityBanner()
            }
            .padding(.horizontal)
            .padding(.bottom, 8)
        }
        .fullScreenCover(isPresented: $app.isNowPlayingPresented) {
            NowPlayingView()
                .navigationTransition(.zoom(sourceID: "now-playing", in: nowPlayingTransition))
        }
        .appSheets(isFrontmost: !app.isNowPlayingPresented)
        .modifier(ToastOverlay(toasts: app.toasts, isShown: !app.isNowPlayingPresented))
    }
}

private struct ConnectivityBanner: View {
    @Environment(AppModel.self) private var app

    var body: some View {
        if app.connectivity.isOnline {
            Button("Connection restored! Tap to refresh.", systemImage: "wifi") {
                app.reconnect()
            }
            .buttonStyle(.glass)
        } else {
            Label("No internet connection", systemImage: "wifi.slash")
                .font(.subheadline)
                .foregroundStyle(.secondary)
        }
    }
}
