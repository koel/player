import AVFoundation
import Shared

/// The native side of the shared `AudioEngine` contract. The shared `PlayerController` owns the
/// queue and decides what to play; this class only plays one source at a time.
final class AVPlayerEngine: NSObject, AudioEngine {
    var listener: (any AudioEngineListener)?

    private let player = AVPlayer()
    private var timeObserver: Any?
    private var playerTask: Task<Void, Never>?
    private var itemTasks: [Task<Void, Never>] = []

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
        observe(item, onReady: onReady, onFailure: onFailure)
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

        playerTask = Task { [weak self, player] in
            for await status in player.publisher(for: \.timeControlStatus).values {
                self?.listener?.onPlayingChanged(playing: status != .paused)
                self?.listener?.onBufferingChanged(buffering: status == .waitingToPlayAtSpecifiedRate)
            }
        }
    }

    private func observe(_ item: AVPlayerItem, onReady: @escaping () -> Void, onFailure: @escaping (String) -> Void) {
        forgetCurrentItem()

        itemTasks.append(Task { [weak self] in
            var hasLoaded = false
            for await status in item.publisher(for: \.status).values {
                switch status {
                case .readyToPlay where !hasLoaded:
                    hasLoaded = true
                    onReady()
                case .failed:
                    let message = item.error?.localizedDescription ?? "The source could not be played."
                    if hasLoaded {
                        self?.listener?.onFailed(message: message)
                    } else {
                        hasLoaded = true
                        onFailure(message)
                    }
                default:
                    break
                }
            }
        })

        itemTasks.append(Task { [weak self] in
            for await _ in NotificationCenter.default.notifications(named: AVPlayerItem.didPlayToEndTimeNotification, object: item) {
                self?.listener?.onFinished()
            }
        })

        itemTasks.append(Task { [weak self] in
            for await notification in NotificationCenter.default.notifications(named: AVPlayerItem.failedToPlayToEndTimeNotification, object: item) {
                let error = notification.userInfo?[AVPlayerItemFailedToPlayToEndTimeErrorKey] as? Error
                self?.listener?.onFailed(message: error?.localizedDescription ?? "Playback stopped unexpectedly.")
            }
        })
    }

    private func forgetCurrentItem() {
        itemTasks.forEach { $0.cancel() }
        itemTasks.removeAll()
    }
}

private extension Double {
    var finiteOrZero: Double { isFinite ? self : 0 }
}
