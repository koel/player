import MediaPlayer
@preconcurrency import Shared
import UIKit

/// Lock screen, Control Center, Dynamic Island and headphone controls.
final class SystemMediaControls {
    private let player: PlayerController
    private var stateTask: Task<Void, Never>?
    private var positionTask: Task<Void, Never>?
    private var artworkTask: Task<Void, Never>?
    private var artworkUrl: String?
    private var reportedPosition: (seconds: Double, at: Date, rate: Double) = (0, .now, 0)

    private var center: MPNowPlayingInfoCenter { .default() }

    init(player: PlayerController) {
        self.player = player
        registerCommands()

        stateTask = Task { [weak self] in
            for await state in player.state { self?.render(state) }
        }
        positionTask = Task { [weak self] in
            for await position in player.position { self?.syncElapsedTimeIfJumped(position.doubleValue) }
        }
    }

    isolated deinit {
        stateTask?.cancel()
        positionTask?.cancel()
        artworkTask?.cancel()
    }

    private func registerCommands() {
        let commands = MPRemoteCommandCenter.shared()

        commands.playCommand.addTarget { [player] _ in player.play(); return .success }
        commands.pauseCommand.addTarget { [player] _ in player.pause(); return .success }
        commands.togglePlayPauseCommand.addTarget { [player] _ in player.togglePlayPause(); return .success }
        commands.nextTrackCommand.addTarget { [player] _ in player.skipToNext(); return .success }
        commands.previousTrackCommand.addTarget { [player] _ in player.skipToPrevious(); return .success }
        commands.changePlaybackPositionCommand.addTarget { [player] event in
            guard let event = event as? MPChangePlaybackPositionCommandEvent else { return .commandFailed }
            player.seek(seconds: event.positionTime)
            return .success
        }
    }

    private func render(_ state: PlaybackState) {
        let commands = MPRemoteCommandCenter.shared()
        let isRadio = state.isRadioMode
        commands.nextTrackCommand.isEnabled = !isRadio
        commands.previousTrackCommand.isEnabled = !isRadio
        commands.changePlaybackPositionCommand.isEnabled = !isRadio

        guard let info = nowPlayingInfo(for: state) else {
            center.nowPlayingInfo = nil
            center.playbackState = .stopped
            return
        }

        let rate = state.isPlaying && !state.isBuffering ? 1.0 : 0.0
        var nowPlaying = info.metadata
        nowPlaying[MPNowPlayingInfoPropertyPlaybackRate] = rate
        nowPlaying[MPNowPlayingInfoPropertyIsLiveStream] = isRadio
        if !isRadio {
            let position = player.position.value.doubleValue
            nowPlaying[MPNowPlayingInfoPropertyElapsedPlaybackTime] = position
            reportedPosition = (position, .now, rate)
        }
        if let artwork = center.nowPlayingInfo?[MPMediaItemPropertyArtwork], info.artworkUrl == artworkUrl {
            nowPlaying[MPMediaItemPropertyArtwork] = artwork
        }

        center.nowPlayingInfo = nowPlaying
        center.playbackState = state.isPlaying ? .playing : .paused
        loadArtwork(info.artworkUrl)
    }

    private func nowPlayingInfo(for state: PlaybackState) -> (metadata: [String: Any], artworkUrl: String?)? {
        if let station = state.radioStation {
            return ([
                MPMediaItemPropertyTitle: state.radioStreamTitle ?? station.name,
                MPMediaItemPropertyArtist: state.radioStreamTitle == nil ? "Radio" : station.name,
            ], station.logo)
        }

        guard let playable = state.current else { return nil }
        return ([
            MPMediaItemPropertyTitle: playable.title,
            MPMediaItemPropertyArtist: playable.subtitle,
            MPMediaItemPropertyAlbumTitle: playable.collectionName,
            MPMediaItemPropertyPlaybackDuration: playable.length,
            MPNowPlayingInfoPropertyMediaType: MPNowPlayingInfoMediaType.audio.rawValue,
        ], playable.artworkUrl)
    }

    /// MediaPlayer asks for the image on its own queue, so the closure must not be main-actor isolated.
    nonisolated private static func artwork(_ image: UIImage) -> MPMediaItemArtwork {
        MPMediaItemArtwork(boundsSize: image.size) { _ in image }
    }

    /// The system extrapolates elapsed time from the rate, so only a seek needs reporting.
    private func syncElapsedTimeIfJumped(_ position: Double) {
        guard var info = center.nowPlayingInfo, !player.state.value.isRadioMode else { return }

        let expected = reportedPosition.seconds + Date.now.timeIntervalSince(reportedPosition.at) * reportedPosition.rate
        guard abs(expected - position) > 1.5 else { return }

        info[MPNowPlayingInfoPropertyElapsedPlaybackTime] = position
        center.nowPlayingInfo = info
        reportedPosition = (position, .now, reportedPosition.rate)
    }

    private func loadArtwork(_ url: String?) {
        guard url != artworkUrl else { return }
        artworkUrl = url
        artworkTask?.cancel()

        artworkTask = Task { [weak self] in
            let image = if let remote = url.flatMap(URL.init(string:)) {
                await ImagePipeline.shared.image(for: remote, pointSize: 300)
            } else {
                UIImage(named: "default-image")
            }
            guard let self, !Task.isCancelled, let image, var info = center.nowPlayingInfo else { return }
            info[MPMediaItemPropertyArtwork] = Self.artwork(image)
            center.nowPlayingInfo = info
        }
    }
}
