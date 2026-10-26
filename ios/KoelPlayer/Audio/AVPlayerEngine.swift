import AVFoundation
@preconcurrency import Shared

/// The native side of the shared `AudioEngine` contract. The shared `PlayerController` owns the
/// queue and decides what to play; this class plays one source at a time, two while crossfading.
final class AVPlayerEngine: NSObject, AudioEngine {
    var listener: (any AudioEngineListener)?

    private(set) var active = AudioDeck()
    private var incoming: AudioDeck?
    private var outgoing: AudioDeck?
    private var fade: Task<Void, Never>?
    private var volume: Float = 1
    private var equalizer = Equalizer.shared.default
    private let activateAudioSession: @MainActor () -> Void

    /// True from the start of a crossfade until the previous source has faded out.
    var isFading: Bool { outgoing != nil }

    init(activateAudioSession: @escaping @MainActor () -> Void = AudioSession.activate) {
        self.activateAudioSession = activateAudioSession
        super.init()
        listen(to: active)
    }

    var position: Double {
        active.position
    }

    func load(url: String, onReady: @escaping () -> Void, onFailure: @escaping (String) -> Void) {
        guard let sourceUrl = URL(string: url) else {
            onFailure("Invalid URL: \(url)")
            return
        }

        callOffCrossfade()
        active.load(sourceUrl, equalizer: equalizer, onReady: onReady, onFailure: onFailure)
    }

    func crossfade(url: String, seconds: Double, gainDecibels: Double, onReady: @escaping () -> Void, onFailure: @escaping (String) -> Void) {
        guard let sourceUrl = URL(string: url) else {
            onFailure("Invalid URL: \(url)")
            return
        }

        callOffCrossfade()
        let deck = makeDeck()
        deck.fadeLevel = 0
        deck.normalizationGain = gainDecibels
        incoming = deck

        deck.load(sourceUrl, equalizer: equalizer) { [weak self, weak deck] in
            guard let self, let deck, deck === incoming else { return }
            incoming = nil
            fadeIn(deck, over: seconds)
            onReady()
        } onFailure: { [weak self, weak deck] message in
            guard let self, let deck, deck === incoming else { return }
            incoming = nil
            deck.discard()
            onFailure(message)
        }
    }

    func cancelCrossfade() {
        incoming?.discard()
        incoming = nil
    }

    func play() {
        activateAudioSession()
        active.player.play()
        outgoing?.player.play()
    }

    func pause() {
        cancelCrossfade()
        active.player.pause()
        outgoing?.player.pause()
    }

    func stop() {
        callOffCrossfade()
        active.stop()
    }

    func seek(seconds: Double) {
        callOffCrossfade()
        active.player.seek(to: CMTime(seconds: seconds, preferredTimescale: 600))
    }

    func setVolume(volume: Double) {
        self.volume = Float(volume)
        for deck in decks {
            deck.volume = self.volume
        }
    }

    func setNormalizationGain(decibels: Double) {
        active.normalizationGain = decibels
    }

    func setEqualizer(preset: EqualizerPreset) {
        equalizer = preset
        for deck in decks {
            deck.setEqualizer(preset)
        }
    }

    private var decks: [AudioDeck] {
        ([active, incoming, outgoing] as [AudioDeck?]).compactMap(\.self)
    }

    private func makeDeck() -> AudioDeck {
        let deck = AudioDeck()
        deck.volume = volume
        listen(to: deck)
        return deck
    }

    /// Makes [deck] the one the listener hears about, and fades the previous one out as it fades in. A paused
    /// player skips the fade and switches over at once.
    private func fadeIn(_ deck: AudioDeck, over seconds: Double) {
        let previous = active
        active = deck
        guard previous.isPlaying else {
            previous.discard()
            deck.fadeLevel = 1
            return
        }

        outgoing = previous
        deck.player.play()
        listener?.onPositionChanged(seconds: 0)

        fade = Task { [weak self] in
            while !Task.isCancelled {
                let progress = Float(min(deck.position / seconds, 1))
                deck.fadeLevel = sin(progress * .pi / 2)
                previous.fadeLevel = cos(progress * .pi / 2)
                if progress >= 1 { break }
                try? await Task.sleep(for: Self.fadeStep)
            }
            if !Task.isCancelled { self?.finishFade() }
        }
    }

    private func finishFade() {
        fade?.cancel()
        fade = nil
        outgoing?.discard()
        outgoing = nil
        active.fadeLevel = 1
    }

    private func callOffCrossfade() {
        cancelCrossfade()
        finishFade()
    }


    private func listen(to deck: AudioDeck) {
        deck.onPosition = { [weak self, weak deck] seconds in
            guard let self, deck === active else { return }
            listener?.onPositionChanged(seconds: seconds)
        }
        deck.onTimeControlStatus = { [weak self, weak deck] status in
            guard let self, deck === active else { return }
            if status == .paused { cancelCrossfade() }
            listener?.onPlayingChanged(playing: status != .paused)
            listener?.onBufferingChanged(buffering: status == .waitingToPlayAtSpecifiedRate)
        }
        deck.onFinished = { [weak self, weak deck] in
            guard let self, deck === active else { return }
            listener?.onFinished()
        }
        deck.onFailed = { [weak self, weak deck] message in
            guard let self, deck === active else { return }
            listener?.onFailed(message: message)
        }
    }

    private static let fadeStep = Duration.milliseconds(30)
}
