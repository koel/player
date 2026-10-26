import AVFoundation
@preconcurrency import Shared

/// One AVPlayer with its equalizer. The engine plays from one deck, and from two while crossfading.
final class AudioDeck {
    let player = AVPlayer()

    var onPosition: (Double) -> Void = { _ in }
    var onTimeControlStatus: (AVPlayer.TimeControlStatus) -> Void = { _ in }
    var onFinished: () -> Void = {}
    var onFailed: (String) -> Void = { _ in }

    /// The user's volume.
    var volume: Float = 1 {
        didSet { applyVolume() }
    }

    /// Where the deck is in a crossfade, from silent (0) to full (1).
    var fadeLevel: Float = 1 {
        didSet { applyVolume() }
    }

    var position: Double {
        player.currentTime().seconds.finiteOrZero
    }

    var isPlaying: Bool {
        player.timeControlStatus != .paused
    }

    private var timeObserver: Any?
    private var timeControlObservation: NSKeyValueObservation?
    private var itemStatusObservation: NSKeyValueObservation?
    private var itemNotifications: [NSObjectProtocol] = []
    private var pendingLoad: (onReady: () -> Void, onFailure: (String) -> Void)?
    private var equalizerProcessor: EqualizerProcessor?
    private var equalizer = Equalizer.shared.default

    /// Turns this deck's source up or down, in dB, on top of the equalizer.
    var normalizationGain: Double = 0 {
        didSet { equalizerProcessor?.setPreset(effectiveEqualizer) }
    }

    /// The user's equalizer with this deck's loudness gain added to the preamp.
    var effectiveEqualizer: EqualizerPreset {
        equalizer.louderBy(decibels: normalizationGain)
    }

    init() {
        player.automaticallyWaitsToMinimizeStalling = true
        observePlayer()
    }

    func load(_ url: URL, equalizer: EqualizerPreset, onReady: @escaping () -> Void, onFailure: @escaping (String) -> Void) {
        let item = AVPlayerItem(url: url)
        observe(item)
        pendingLoad = (onReady, onFailure)
        player.replaceCurrentItem(with: item)
        self.equalizer = equalizer
        attachEqualizer(to: item)
    }

    func stop() {
        player.pause()
        forgetCurrentItem()
        player.replaceCurrentItem(with: nil)
    }

    /// For a deck that is done with: it plays nothing more and reports nothing more.
    func discard() {
        stop()
        timeObserver.map(player.removeTimeObserver)
        timeObserver = nil
        timeControlObservation?.invalidate()
    }

    func setEqualizer(_ preset: EqualizerPreset) {
        equalizer = preset
        equalizerProcessor?.setPreset(effectiveEqualizer)
    }

    private func applyVolume() {
        player.volume = volume * fadeLevel
    }

    /// Streams without a separate audio track, such as HLS radio, play without the equalizer.
    private func attachEqualizer(to item: AVPlayerItem) {
        let processor = EqualizerProcessor(preset: effectiveEqualizer)
        equalizerProcessor = processor

        Task { [weak self, weak item] in
            guard let track = try? await item?.asset.loadTracks(withMediaType: .audio).first,
                  let item, item === self?.player.currentItem,
                  let mix = EqualizerTap.audioMix(for: track, processor: processor)
            else { return }
            item.audioMix = mix
        }
    }

    private func observePlayer() {
        timeObserver = player.addPeriodicTimeObserver(
            forInterval: CMTime(seconds: 0.5, preferredTimescale: 600),
            queue: .main
        ) { [weak self] time in
            MainActor.assumeIsolated {
                self?.onPosition(time.seconds.finiteOrZero)
            }
        }

        timeControlObservation = player.observe(\.timeControlStatus, options: [.initial, .new]) { [weak self] player, _ in
            let status = player.timeControlStatus
            Task { @MainActor in self?.onTimeControlStatus(status) }
        }
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
                MainActor.assumeIsolated { self?.onFinished() }
            },
            center.addObserver(forName: AVPlayerItem.failedToPlayToEndTimeNotification, object: item, queue: .main) { [weak self] notification in
                let message = (notification.userInfo?[AVPlayerItemFailedToPlayToEndTimeErrorKey] as? Error)?.localizedDescription
                MainActor.assumeIsolated {
                    self?.onFailed(message ?? "Playback stopped unexpectedly.")
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
                onFailed(message)
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

extension Double {
    var finiteOrZero: Double { isFinite ? self : 0 }
}
