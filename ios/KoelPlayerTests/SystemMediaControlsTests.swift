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

    @Test func keepsTheCurrentArtworkWhenTheNextSongsArtworkArrivesLate() async throws {
        let firstImage = UIImage(systemName: "music.note")!
        let lateImage = UIImage(systemName: "mic")!
        let first = Self.song(id: "1", title: "First", cover: "https://koel.example.com/first.jpg")
        let second = Self.song(id: "2", title: "Second", cover: "https://koel.example.com/second.jpg")
        let artwork = SlowArtwork(instant: [first.albumCover!: firstImage])
        let controls = SystemMediaControls(player: core.player, loadImage: artwork.load)

        core.player.replaceQueue(playables: [first, second], shuffle: false, autoPlay: true)
        try #require(await eventually { shownArtworkImage() === firstImage })
        core.player.skipToNext()
        try #require(await eventually { artwork.isWaiting })
        core.player.skipToPrevious()
        try #require(await eventually { shownTitle() == first.title && shownArtworkImage() === firstImage })

        artwork.finish(with: lateImage)
        try await Task.sleep(for: .milliseconds(200))

        #expect(shownArtworkImage() === firstImage)
        withExtendedLifetime(controls) {}
    }

    private func shownTitle() -> String? {
        MPNowPlayingInfoCenter.default().nowPlayingInfo?[MPMediaItemPropertyTitle] as? String
    }

    private func shownArtworkImage() -> UIImage? {
        let artwork = MPNowPlayingInfoCenter.default().nowPlayingInfo?[MPMediaItemPropertyArtwork] as? MPMediaItemArtwork
        return artwork?.image(at: CGSize(width: 300, height: 300))
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

    private static func song(id: String, title: String, cover: String) -> Song {
        Song(
            id: id, title: title, lyrics: "", length: 30, albumId: "album", albumName: "Album",
            artistId: "artist", artistName: "Artist", albumArtistId: "artist", albumArtistName: "Artist",
            albumCover: cover, track: 1, disc: 1, year: nil, genre: "", favorite: false, playCount: 0,
            createdAt: "", type: "songs", loudness: nil, truePeak: nil
        )
    }

    private static let station = RadioStation(
        id: "1",
        name: "Jazz FM",
        url: "https://jazz.example.com/live",
        logo: nil,
        description: "",
        homepageUrl: nil,
        isPublic: true,
        favorite: false,
        permissions: Permissions(edit: true, delete: true)
    )
}

/// Hands over some images at once and holds the rest back until `finish` is called.
@MainActor
private final class SlowArtwork {
    private let instant: [String: UIImage]
    private var pending: CheckedContinuation<UIImage?, Never>?

    var isWaiting: Bool { pending != nil }

    init(instant: [String: UIImage]) {
        self.instant = instant
    }

    func load(_ url: URL) async -> UIImage? {
        if let image = instant[url.absoluteString] { return image }
        return await withCheckedContinuation { pending = $0 }
    }

    func finish(with image: UIImage) {
        pending?.resume(returning: image)
        pending = nil
    }
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
