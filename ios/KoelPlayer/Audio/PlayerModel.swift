import Observation
@preconcurrency import Shared

/// SwiftUI's view of the shared `PlayerController`.
@Observable
final class PlayerModel {
    let controller: PlayerController
    private let podcasts: PodcastStore
    private let liveState: Live<PlaybackState>
    private let livePosition: Live<KotlinDouble>

    init(controller: PlayerController, podcasts: PodcastStore) {
        self.controller = controller
        self.podcasts = podcasts
        liveState = Live(controller.state)
        livePosition = Live(controller.position)
    }

    var state: PlaybackState { liveState.value }

    var position: Double { livePosition.value.doubleValue }

    var current: (any Playable)? { state.current }

    var hasSomethingToShow: Bool { current != nil || state.isRadioMode }

    func isCurrent(_ playable: any Playable) -> Bool {
        current?.id == playable.id
    }

    func isPlaying(_ playable: any Playable) -> Bool {
        isCurrent(playable) && state.isPlaying && !state.hasFailed
    }

    /// Episodes resume where the user left off, possibly on another device.
    func play(_ playable: any Playable) {
        guard let episode = playable as? Episode, controller.rememberedPosition(playableId: episode.id) == nil else {
            controller.play(playable: playable)
            return
        }

        Task {
            let progress = (try? await podcasts.episodeProgress(episode: episode))?.doubleValue ?? 0
            controller.rememberPosition(playableId: episode.id, seconds: progress)
            controller.play(playable: episode)
        }
    }

    func play(_ playables: [any Playable], shuffled: Bool = false) {
        guard !playables.isEmpty else { return }
        controller.replaceQueue(playables: playables, shuffle: shuffled, autoPlay: true)
    }

    func togglePlayPause() { controller.togglePlayPause() }
    func skipToNext() { controller.skipToNext() }
    func skipToPrevious() { controller.skipToPrevious() }
    func seek(to seconds: Double) { controller.seek(seconds: seconds) }
    func playNext(_ playable: any Playable) { controller.playNext(playable: playable) }
    func playLast(_ playable: any Playable) { controller.queueToBottom(playable: playable) }
    func removeFromQueue(_ playable: any Playable) { controller.removeFromQueue(playable: playable) }
    func isQueued(_ playable: any Playable) -> Bool { controller.isQueued(playable: playable) }

    @discardableResult
    func rotateRepeatMode() -> RepeatMode { controller.rotateRepeatMode() }
}
