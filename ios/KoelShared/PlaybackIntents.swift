import AppIntents

/// The app's player, as the widget buttons see it. Audio playback intents run in the app's
/// process, where the app sets this; in the widget's own process it stays empty.
@MainActor
protocol PlaybackIntentTarget: AnyObject {
    func togglePlayPause() async
    func setPlaying(_ isPlaying: Bool) async
    func skipToNext() async
}

@MainActor
enum PlaybackIntents {
    static var target: (any PlaybackIntentTarget)?

    static func togglePlayPause() async { await target?.togglePlayPause() }
    static func skipToNext() async { await target?.skipToNext() }
    static func setPlaying(_ isPlaying: Bool) async { await target?.setPlaying(isPlaying) }
}

nonisolated struct TogglePlaybackIntent: AudioPlaybackIntent {
    static let title: LocalizedStringResource = "Play or Pause"

    func perform() async throws -> some IntentResult {
        await PlaybackIntents.togglePlayPause()
        return .result()
    }
}

nonisolated struct SkipToNextIntent: AudioPlaybackIntent {
    static let title: LocalizedStringResource = "Next"

    func perform() async throws -> some IntentResult {
        await PlaybackIntents.skipToNext()
        return .result()
    }
}

struct SetPlaybackIntent: SetValueIntent, AudioPlaybackIntent {
    static let title: LocalizedStringResource = "Play or Pause"

    @Parameter(title: "Playing")
    var value: Bool

    func perform() async throws -> some IntentResult {
        let isPlaying = value
        await PlaybackIntents.setPlaying(isPlaying)
        return .result()
    }
}
