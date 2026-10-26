import AVFoundation
@testable import KoelPlayer
@preconcurrency import Shared
import Testing

/// One AVPlayer at a time: they share the app's audio session.
@MainActor
@Suite(.serialized)
struct AVPlayerEngineTests {
    @Test func reportsReadyForAPlayableFile() async throws {
        let engine = AVPlayerEngine()
        let url = try Self.makeToneFile()

        let outcome = await withCheckedContinuation { continuation in
            engine.load(url: url.absoluteString, onReady: { continuation.resume(returning: "ready") }, onFailure: { continuation.resume(returning: "failed: \($0)") })
        }

        #expect(outcome == "ready")
    }

    @Test func reportsFailureForAMissingFile() async {
        let engine = AVPlayerEngine()

        let outcome = await withCheckedContinuation { continuation in
            engine.load(url: "file:///nonexistent/song.mp3", onReady: { continuation.resume(returning: "ready") }, onFailure: { _ in continuation.resume(returning: "failed") })
        }

        #expect(outcome == "failed")
    }

    @Test func tellsTheListenerWhenPlaybackStarts() async throws {
        let engine = AVPlayerEngine()
        let listener = RecordingListener()
        engine.listener = listener
        let url = try Self.makeToneFile()

        await withCheckedContinuation { continuation in
            engine.load(url: url.absoluteString, onReady: { continuation.resume() }, onFailure: { _ in continuation.resume() })
        }
        engine.play()

        for _ in 0..<50 where !listener.playingStates.contains(true) {
            try await Task.sleep(for: .milliseconds(50))
        }
        #expect(listener.playingStates.contains(true))
        engine.stop()
    }

    @Test func takesOverTheAudioSessionOnlyWhenPlaybackStarts() async throws {
        var activations = 0
        let engine = AVPlayerEngine { activations += 1 }
        let url = try Self.makeToneFile()

        await withCheckedContinuation { continuation in
            engine.load(url: url.absoluteString, onReady: { continuation.resume() }, onFailure: { _ in continuation.resume() })
        }
        #expect(activations == 0)

        engine.play()
        #expect(activations == 1)
        engine.stop()
    }

    @Test func crossfadesIntoTheNextSourceThenLetsThePreviousOneGo() async throws {
        let engine = AVPlayerEngine()
        let listener = RecordingListener()
        engine.listener = listener
        let first = try Self.makeToneFile(seconds: 3)
        let second = try Self.makeToneFile(seconds: 3)

        await withCheckedContinuation { continuation in
            engine.load(url: first.absoluteString, onReady: { continuation.resume() }, onFailure: { _ in continuation.resume() })
        }
        engine.play()
        for _ in 0..<400 where !listener.playingStates.contains(true) {
            try await Task.sleep(for: .milliseconds(50))
        }
        try #require(listener.playingStates.contains(true))

        let outcome = await withCheckedContinuation { continuation in
            engine.crossfade(url: second.absoluteString, seconds: 0.5, gainDecibels: 0, onReady: { continuation.resume(returning: "ready") }, onFailure: { continuation.resume(returning: "failed: \($0)") })
        }
        #expect(outcome == "ready")
        #expect(engine.isFading)

        for _ in 0..<60 where engine.isFading {
            try await Task.sleep(for: .milliseconds(50))
        }
        #expect(!engine.isFading)
        #expect(engine.position > 0)
        engine.stop()
    }

    @Test func aSeekWhileTheNextSourceLoadsCallsOffTheCrossfade() async throws {
        let engine = try await Self.playingEngine()
        var outcomes: [String] = []

        engine.crossfade(url: try Self.makeToneFile(seconds: 3).absoluteString, seconds: 0.5, gainDecibels: 0, onReady: { outcomes.append("ready") }, onFailure: { outcomes.append("failed: \($0)") })
        engine.seek(seconds: 1)
        try await Task.sleep(for: .seconds(1))

        #expect(outcomes.isEmpty)
        #expect(!engine.isFading)
        engine.stop()
    }

    @Test func aPauseWhileTheNextSourceLoadsCallsOffTheCrossfade() async throws {
        let engine = try await Self.playingEngine()
        var outcomes: [String] = []

        engine.crossfade(url: try Self.makeToneFile(seconds: 3).absoluteString, seconds: 0.5, gainDecibels: 0, onReady: { outcomes.append("ready") }, onFailure: { outcomes.append("failed: \($0)") })
        engine.pause()
        try await Task.sleep(for: .seconds(1))

        #expect(outcomes.isEmpty)
        #expect(!engine.isFading)
        engine.stop()
    }

    @Test func aSystemPauseWhileTheNextSourceLoadsCallsOffTheCrossfade() async throws {
        let engine = try await Self.playingEngine()
        var outcomes: [String] = []

        engine.crossfade(url: try Self.makeToneFile(seconds: 3).absoluteString, seconds: 0.5, gainDecibels: 0, onReady: { outcomes.append("ready") }, onFailure: { outcomes.append("failed: \($0)") })
        engine.active.player.pause()
        try await Task.sleep(for: .seconds(1))

        #expect(outcomes.isEmpty)
        #expect(!engine.isFading)
        engine.stop()
    }

    @Test func aCancelledCrossfadeNeverReportsAndKeepsTheCurrentSource() async throws {
        let engine = try await Self.playingEngine()
        var outcomes: [String] = []

        engine.crossfade(url: try Self.makeToneFile(seconds: 3).absoluteString, seconds: 0.5, gainDecibels: 0, onReady: { outcomes.append("ready") }, onFailure: { outcomes.append("failed: \($0)") })
        engine.cancelCrossfade()
        try await Task.sleep(for: .seconds(1))

        #expect(outcomes.isEmpty)
        #expect(!engine.isFading)
        #expect(engine.position > 0)
        engine.stop()
    }

    @Test func aDecksLoudnessGainAddsToTheEqualizerPreamp() {
        let deck = AudioDeck()
        deck.setEqualizer(Equalizer.shared.default.withPreamp(decibels: -2))

        deck.normalizationGain = 3

        #expect(deck.effectiveEqualizer.preamp == 1)
        #expect(deck.effectiveEqualizer.gains == Equalizer.shared.default.gains)
    }

    private static func playingEngine() async throws -> AVPlayerEngine {
        let engine = AVPlayerEngine()
        let listener = RecordingListener()
        engine.listener = listener
        let url = try makeToneFile(seconds: 3)

        await withCheckedContinuation { continuation in
            engine.load(url: url.absoluteString, onReady: { continuation.resume() }, onFailure: { _ in continuation.resume() })
        }
        engine.play()
        for _ in 0..<400 where !listener.playingStates.contains(true) {
            try await Task.sleep(for: .milliseconds(50))
        }
        try #require(listener.playingStates.contains(true))
        return engine
    }

    private static func makeToneFile(seconds: Int = 1) throws -> URL {
        let url = FileManager.default.temporaryDirectory.appending(path: "tone-\(UUID().uuidString).caf")
        let format = AVAudioFormat(standardFormatWithSampleRate: 44_100, channels: 1)!
        let file = try AVAudioFile(forWriting: url, settings: format.settings)
        let frames = AVAudioFrameCount(44_100 * seconds)
        let buffer = AVAudioPCMBuffer(pcmFormat: format, frameCapacity: frames)!
        buffer.frameLength = frames
        for frame in 0..<Int(frames) {
            buffer.floatChannelData![0][frame] = sin(Float(frame) * 2 * .pi * 440 / 44_100) * 0.1
        }
        try file.write(from: buffer)
        return url
    }
}

private final class RecordingListener: NSObject, AudioEngineListener {
    var playingStates: [Bool] = []

    func onPositionChanged(seconds: Double) {}
    func onPlayingChanged(playing: Bool) { playingStates.append(playing) }
    func onBufferingChanged(buffering: Bool) {}
    func onFinished() {}
    func onFailed(message: String) {}
}
