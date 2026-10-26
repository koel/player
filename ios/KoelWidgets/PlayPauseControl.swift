import AppIntents
import SwiftUI
import WidgetKit

/// A Control Center and Lock Screen button that plays or pauses.
struct PlayPauseControl: ControlWidget {
    var body: some ControlWidgetConfiguration {
        StaticControlConfiguration(kind: WidgetKind.playPauseControl, provider: PlaybackValueProvider()) { isPlaying in
            ControlWidgetToggle("Koel", isOn: isPlaying, action: SetPlaybackIntent()) { isOn in
                Label(isOn ? "Playing" : "Paused", systemImage: isOn ? "pause.fill" : "play.fill")
            }
        }
        .displayName("Play or Pause")
        .description("Plays or pauses Koel.")
    }
}

nonisolated struct PlaybackValueProvider: ControlValueProvider {
    var previewValue: Bool { false }

    func currentValue() async throws -> Bool {
        SharedContainer.readSnapshot().nowPlaying?.isPlaying ?? false
    }
}
