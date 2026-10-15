import AVFoundation
@preconcurrency import Shared

/// The native side of the shared `AudioEngine` contract. The shared `PlayerController` owns the
/// queue and decides what to play; this class only plays one source at a time.
final class AVPlayerEngine: NSObject, AudioEngine {
    var listener: (any AudioEngineListener)?

    private let player = AVPlayer()
    private var timeObserver: Any?
    private var timeControlObservation: NSKeyValueObservation?
    private var itemStatusObservation: NSKeyValueObservation?
    private var itemNotifications: [NSObjectProtocol] = []
    private var pendingLoad: (onReady: () -> Void, onFailure: (String) -> Void)?

    override init() {
        super.init()
        player.automaticallyWaitsToMinimizeStalling = true
        observePlayer()
    }

    var position: Double {
        player.currentTime().seconds.finiteOrZero
    }

    func load(url: String, onReady: @escaping () -> Void, onFailure: @escaping (String) -> Void) {
        guard let sourceUrl = URL(string: url) else {
            onFailure("Invalid URL: \(url)")
            return
        }

        AudioSession.activate()
        let item = AVPlayerItem(url: sourceUrl)
        observe(item)
        pendingLoad = (onReady, onFailure)
        player.replaceCurrentItem(with: item)
    }

    func play() {
        AudioSession.activate()
        player.play()
    }

    func pause() {
        player.pause()
    }

    func stop() {
        player.pause()
        forgetCurrentItem()
        player.replaceCurrentItem(with: nil)
    }

    func seek(seconds: Double) {
        player.seek(to: CMTime(seconds: seconds, preferredTimescale: 600))
    }

    func setVolume(volume: Double) {
        player.volume = Float(volume)
    }

    private func observePlayer() {
        timeObserver = player.addPeriodicTimeObserver(
            forInterval: CMTime(seconds: 0.5, preferredTimescale: 600),
            queue: .main
        ) { [weak self] time in
            MainActor.assumeIsolated {
                self?.listener?.onPositionChanged(seconds: time.seconds.finiteOrZero)
            }
        }

        timeControlObservation = player.observe(\.timeControlStatus, options: [.initial, .new]) { [weak self] player, _ in
            let status = player.timeControlStatus
            Task { @MainActor in self?.timeControlStatusChanged(status) }
        }
    }

    private func timeControlStatusChanged(_ status: AVPlayer.TimeControlStatus) {
        listener?.onPlayingChanged(playing: status != .paused)
        listener?.onBufferingChanged(buffering: status == .waitingToPlayAtSpecifiedRate)
    }

    private func observe(_ item: AVPlayerItem) {
        forgetCurrentItem()

        itemStatusObservation = item.observe(\.status, options: [.initial, .new]) { [weak self] item, _ in
            let status = item.status
            let message = item.error?.localizedDescription ?? "The source could not be played."
            Task { @MainActor in self?.itemStatusChanged(status, message: message) }
        }

        let center = NotificationCenter.default
        itemNotifications = [
            center.addObserver(forName: AVPlayerItem.didPlayToEndTimeNotification, object: item, queue: .main) { [weak self] _ in
                MainActor.assumeIsolated { self?.listener?.onFinished() }
            },
            center.addObserver(forName: AVPlayerItem.failedToPlayToEndTimeNotification, object: item, queue: .main) { [weak self] notification in
                let message = (notification.userInfo?[AVPlayerItemFailedToPlayToEndTimeErrorKey] as? Error)?.localizedDescription
                MainActor.assumeIsolated {
                    self?.listener?.onFailed(message: message ?? "Playback stopped unexpectedly.")
                }
            },
        ]
    }

    /// The load callbacks fire once; a failure after that is a mid-stream failure.
    private func itemStatusChanged(_ status: AVPlayerItem.Status, message: String) {
        switch status {
        case .readyToPlay:
            pendingLoad?.onReady()
            pendingLoad = nil
        case .failed:
            if let pendingLoad {
                pendingLoad.onFailure(message)
                self.pendingLoad = nil
            } else {
                listener?.onFailed(message: message)
            }
        default:
            break
        }
    }

    private func forgetCurrentItem() {
        itemStatusObservation?.invalidate()
        itemStatusObservation = nil
        itemNotifications.forEach(NotificationCenter.default.removeObserver)
        itemNotifications.removeAll()
        pendingLoad = nil
    }
}

private extension Double {
    var finiteOrZero: Double { isFinite ? self : 0 }
}
