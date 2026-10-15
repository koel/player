import SwiftUI

extension EnvironmentValues {
    /// The current song's cover color, or Koel pink when nothing with a usable cover is playing.
    @Entry var brandColor: Color = .highlight
}

/// Follows what's playing and publishes its cover color as the app's brand color.
struct NowPlayingBrandColor: ViewModifier {
    @Environment(AppModel.self) private var app
    @State private var coverColor: Color?

    func body(content: Content) -> some View {
        let state = app.player.state
        let artworkUrl = state.radioStation?.logo ?? state.current?.artworkUrl

        content
            .environment(\.brandColor, coverColor ?? .highlight)
            .animation(.easeInOut(duration: 0.5), value: coverColor)
            .task(id: artworkUrl) { coverColor = await CoverColor.of(artworkUrl) }
    }
}
