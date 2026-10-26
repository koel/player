import AVFoundation
import MediaPlayer
@preconcurrency import Shared
import UIKit

/// Lock screen, Control Center, Dynamic Island and headphone controls.
final class SystemMediaControls {
    private let player: PlayerController
    private let loadImage: (URL) async -> UIImage?
    private var stateTask: Task<Void, Never>?
    private var positionTask: Task<Void, Never>?
    private var artworkTask: Task<Void, Never>?
    private var interruptionTask: Task<Void, Never>?
    private var isPlaying = false
    private var wasPlayingBeforeInterruption = false
    private var shownArtwork: (url: String?, artwork: MPMediaItemArtwork)?
    private var loadingArtworkUrl: String?
    private var reportedPosition: (seconds: Double, at: Date, rate: Double) = (0, .now, 0)

    private var center: MPNowPlayingInfoCenter { .default() }

    init(
        player: PlayerController,
        loadImage: @escaping (URL) async -> UIImage? = SystemMediaControls.lockScreenImage
    ) {
        self.player = player
        self.loadImage = loadImage
        registerCommands()

        stateTask = Task { [weak self] in
            for await state in player.state { self?.render(state) }
        }
        positionTask = Task { [weak self] in
            for await position in player.position { self?.syncElapsedTimeIfJumped(position.doubleValue) }
        }
        interruptionTask = Task { [weak self] in
            for await notification in NotificationCenter.default.notifications(named: AVAudioSession.interruptionNotification) {
                self?.handleInterruption(notification)
            }
        }
    }

    private static func lockScreenImage(_ url: URL) async -> UIImage? {
        await ImagePipeline.shared.image(for: url, pointSize: 300)
    }

    isolated deinit {
        stateTask?.cancel()
        positionTask?.cancel()
        artworkTask?.cancel()
        interruptionTask?.cancel()
    }

    private func registerCommands() {
        let commands = MPRemoteCommandCenter.shared()

        commands.playCommand.addTarget { [player] _ in player.play(); return .success }
        commands.pauseCommand.addTarget { [player] _ in player.pause(); return .success }
        commands.togglePlayPauseCommand.addTarget { [player] _ in player.togglePlayPause(); return .success }
        commands.stopCommand.addTarget { [player] _ in player.stop(); return .success }
        commands.nextTrackCommand.addTarget { [player] _ in player.skipToNext(); return .success }
        commands.previousTrackCommand.addTarget { [player] _ in player.skipToPrevious(); return .success }
        commands.changePlaybackPositionCommand.addTarget { [player] event in
            guard let event = event as? MPChangePlaybackPositionCommandEvent else { return .commandFailed }
            player.seek(seconds: event.positionTime)
            return .success
        }
    }

    /// Picks playback back up after a call or Siri, when the system says it should.
    private func handleInterruption(_ notification: Notification) {
        guard let rawType = notification.userInfo?[AVAudioSessionInterruptionTypeKey] as? UInt,
              let type = AVAudioSession.InterruptionType(rawValue: rawType) else { return }

        switch type {
        case .began:
            wasPlayingBeforeInterruption = isPlaying
        case .ended:
            if Self.shouldResume(after: notification, wasPlaying: wasPlayingBeforeInterruption) { player.play() }
            wasPlayingBeforeInterruption = false
        @unknown default:
            break
        }
    }

    static func shouldResume(after notification: Notification, wasPlaying: Bool) -> Bool {
        let rawOptions = notification.userInfo?[AVAudioSessionInterruptionOptionKey] as? UInt ?? 0
        return wasPlaying && AVAudioSession.InterruptionOptions(rawValue: rawOptions).contains(.shouldResume)
    }

    private func render(_ state: PlaybackState) {
        isPlaying = state.isPlaying
        let commands = MPRemoteCommandCenter.shared()
        let isRadio = state.isRadioMode
        commands.nextTrackCommand.isEnabled = !isRadio
        commands.previousTrackCommand.isEnabled = !isRadio
        commands.changePlaybackPositionCommand.isEnabled = !isRadio

        guard let info = nowPlayingInfo(for: state) else {
            forgetArtwork()
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
        let artwork = shownArtwork.flatMap { $0.url == info.artworkUrl ? $0.artwork : nil }
        nowPlaying[MPMediaItemPropertyArtwork] = artwork

        center.nowPlayingInfo = nowPlaying
        center.playbackState = state.isPlaying ? .playing : .paused
        if artwork == nil {
            loadArtwork(info.artworkUrl)
        } else {
            cancelArtworkLoad()
        }
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
        guard let remote = url.flatMap(URL.init(string:)) else {
            forgetArtwork()
            show(Self.defaultArtwork, for: url)
            return
        }
        guard url != loadingArtworkUrl else { return }
        loadingArtworkUrl = url
        artworkTask?.cancel()

        artworkTask = Task { [weak self, loadImage] in
            let image = await loadImage(remote)
            guard let self, !Task.isCancelled else { return }
            loadingArtworkUrl = nil
            show(image ?? Self.defaultArtwork, for: url)
        }
    }

    private func show(_ image: UIImage?, for url: String?) {
        guard let image, var info = center.nowPlayingInfo else { return }
        let artwork = Self.artwork(image)
        shownArtwork = (url, artwork)
        info[MPMediaItemPropertyArtwork] = artwork
        center.nowPlayingInfo = info
    }

    private func forgetArtwork() {
        cancelArtworkLoad()
        shownArtwork = nil
    }

    private func cancelArtworkLoad() {
        artworkTask?.cancel()
        loadingArtworkUrl = nil
    }

    private static var defaultArtwork: UIImage? { UIImage(named: "default-image") }
}
