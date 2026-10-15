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

    private static func makeToneFile() throws -> URL {
        let url = FileManager.default.temporaryDirectory.appending(path: "tone-\(UUID().uuidString).caf")
        let format = AVAudioFormat(standardFormatWithSampleRate: 44_100, channels: 1)!
        let file = try AVAudioFile(forWriting: url, settings: format.settings)
        let frames = AVAudioFrameCount(44_100)
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
