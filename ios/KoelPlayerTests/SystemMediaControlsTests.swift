import Foundation
import MediaPlayer
@testable import KoelPlayer
@preconcurrency import Shared
import Testing

@MainActor
@Suite(.serialized)
struct SystemMediaControlsTests {
    private let core = KoelCoreFactoryKt.createKoelCore(
        keyValueStore: NativeKeyValueStore(
            defaults: UserDefaults(suiteName: "SystemMediaControlsTests-\(UUID().uuidString)")!,
            keychainService: "SystemMediaControlsTests-\(UUID().uuidString)"
        ),
        documentsPath: FileManager.default.temporaryDirectory.appending(path: UUID().uuidString).path(percentEncoded: false),
        audioEngine: InstantAudioEngine()
    )

    init() {
        MPNowPlayingInfoCenter.default().nowPlayingInfo = nil
    }

    @Test func showsTheDefaultArtworkForAStationWithoutALogo() async throws {
        let controls = SystemMediaControls(player: core.player)

        try await core.player.playRadio(station: Self.station)

        #expect(await lockScreenArtworkAppears())
        withExtendedLifetime(controls) {}
    }

    @Test func showsTheArtworkAgainAfterLoggingOutAndBackIn() async throws {
        let controls = SystemMediaControls(player: core.player)
        try await core.player.playRadio(station: Self.station)
        try #require(await lockScreenArtworkAppears())

        core.player.cleanUpUponLogout()
        try #require(await nowPlayingInfoClears())
        try await core.player.playRadio(station: Self.station)

        #expect(await lockScreenArtworkAppears())
        withExtendedLifetime(controls) {}
    }

    private func lockScreenArtworkAppears() async -> Bool {
        await eventually { MPNowPlayingInfoCenter.default().nowPlayingInfo?[MPMediaItemPropertyArtwork] != nil }
    }

    private func nowPlayingInfoClears() async -> Bool {
        await eventually { MPNowPlayingInfoCenter.default().nowPlayingInfo == nil }
    }

    private func eventually(_ condition: () -> Bool) async -> Bool {
        for _ in 0..<40 where !condition() {
            try? await Task.sleep(for: .milliseconds(50))
        }
        return condition()
    }

    private static let station = RadioStation(
        id: "1",
        name: "Jazz FM",
        url: "https://jazz.example.com/live",
        logo: nil,
        description: "",
        isPublic: true,
        favorite: false,
        permissions: Permissions(edit: true, delete: true)
    )
}

private final class InstantAudioEngine: NSObject, AudioEngine {
    var listener: (any AudioEngineListener)?
    var position: Double { 0 }

    func load(url: String, onReady: @escaping () -> Void, onFailure: @escaping (String) -> Void) { onReady() }
    func crossfade(url: String, seconds: Double, gainDecibels: Double, onReady: @escaping () -> Void, onFailure: @escaping (String) -> Void) { onReady() }
    func cancelCrossfade() {}
    func play() {}
    func pause() {}
    func stop() {}
    func seek(seconds: Double) {}
    func setVolume(volume: Double) {}
    func setNormalizationGain(decibels: Double) {}
    func setEqualizer(preset: EqualizerPreset) {}
}
