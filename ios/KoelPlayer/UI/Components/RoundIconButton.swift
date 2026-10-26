@preconcurrency import Shared
import SwiftUI

/// A neutral glass circle holding one symbol, for the secondary actions around a Play button.
struct RoundIconButton: View {
    let title: String
    let systemImage: String
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Image(systemName: systemImage)
                .contentTransition(.symbolEffect(.replace))
                .frame(width: 24, height: 24)
        }
        .accessibilityLabel(title)
        .buttonStyle(.glass)
        .buttonBorderShape(.circle)
        .tint(.primary)
    }
}

/// The wide main Play button between round icon buttons, in the cover color when there is one.
struct PlayButton: View {
    let playables: [any Playable]
    let tint: Color?

    @Environment(AppModel.self) private var app

    var body: some View {
        let button = Button {
            app.player.play(playables)
        } label: {
            HStack(spacing: 8) {
                Image(systemName: "play.fill")
                Text("Play")
            }
            .padding(.horizontal, 36)
        }
        .disabled(playables.isEmpty)

        if let tint {
            button.buttonStyle(.glassProminent).tint(tint).foregroundStyle(.white)
        } else {
            button.buttonStyle(.glass).tint(.primary)
        }
    }
}
