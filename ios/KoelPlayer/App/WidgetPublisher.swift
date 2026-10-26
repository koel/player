import CryptoKit
@preconcurrency import Shared
import UIKit
import WidgetKit

/// Keeps the widgets and the Control Center button in step with the player, and lets their
/// buttons control it.
final class WidgetPublisher: PlaybackIntentTarget {
    private let player: PlayerController
    private let recentlyPlayed: RecentlyPlayedStore
    private var tasks: [Task<Void, Never>] = []
    private var published = WidgetSnapshot.empty
    private lazy var publishing = SerialJob { [weak self] in await self?.publish() }

    private static let recentItemCount = 12
    private static let artworkPointSize: CGFloat = 120

    init(player: PlayerController, recentlyPlayed: RecentlyPlayedStore) {
        self.player = player
        self.recentlyPlayed = recentlyPlayed
        PlaybackIntents.target = self

        tasks.append(Task { [weak self] in
            for await _ in player.state { self?.publishing.request() }
        })
        tasks.append(Task { [weak self] in
            for await _ in recentlyPlayed.items { self?.publishing.request() }
        })
    }

    isolated deinit {
        tasks.forEach { $0.cancel() }
    }

    func togglePlayPause() async {
        await restoreQueueIfNeeded()
        player.togglePlayPause()
    }

    func skipToNext() async {
        await restoreQueueIfNeeded()
        player.skipToNext()
    }

    func setPlaying(_ isPlaying: Bool) async {
        await restoreQueueIfNeeded()
        isPlaying ? player.play() : player.pause()
    }

    /// A widget button can start the app in the background, before its screen has loaded the
    /// library and brought back the saved queue.
    private func restoreQueueIfNeeded() async {
        if player.state.value.queue.isEmpty { await AppModel.shared.launchWithoutScreen() }
    }

    private func publish() async {
        let state = player.state.value
        let recent = Array(recentlyPlayed.items.value.prefix(Self.recentItemCount))

        var snapshot = WidgetSnapshot(nowPlaying: nowPlaying(state))
        snapshot.recentlyPlayed = recent.map {
            WidgetSnapshot.RecentItem(id: $0.id, title: $0.title, subtitle: $0.subtitle, artworkFile: Self.artworkFile(for: $0.artworkUrl))
        }
        guard snapshot != published else { return }

        let artworkUrls = [state.radioStation?.logo ?? state.current?.artworkUrl] + recent.map(\.artworkUrl)
        await saveArtwork(artworkUrls.compactMap { $0 })
        SharedContainer.write(snapshot)

        if snapshot.nowPlaying != published.nowPlaying {
            WidgetCenter.shared.reloadTimelines(ofKind: WidgetKind.nowPlaying)
            ControlCenter.shared.reloadControls(ofKind: WidgetKind.playPauseControl)
        }
        if snapshot.recentlyPlayed != published.recentlyPlayed {
            WidgetCenter.shared.reloadTimelines(ofKind: WidgetKind.recentlyPlayed)
        }
        published = snapshot
    }

    private func nowPlaying(_ state: PlaybackState) -> WidgetSnapshot.NowPlaying? {
        if let station = state.radioStation {
            return .init(
                title: state.radioStreamTitle ?? station.name,
                subtitle: state.radioStreamTitle == nil ? "Radio" : station.name,
                isPlaying: state.isPlaying,
                isRadio: true,
                artworkFile: Self.artworkFile(for: station.logo)
            )
        }
        guard let current = state.current else { return nil }
        return .init(
            title: current.title,
            subtitle: current.subtitle,
            isPlaying: state.isPlaying,
            isRadio: false,
            artworkFile: Self.artworkFile(for: current.artworkUrl)
        )
    }

    /// Writes the covers the snapshot refers to, and clears out the ones it no longer does.
    private func saveArtwork(_ urls: [String]) async {
        guard let directory = SharedContainer.artworkDirectory else { return }
        try? FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)

        var keptFiles: Set<String> = []
        for url in urls {
            guard let file = Self.artworkFile(for: url), let remote = URL(string: url) else { continue }
            keptFiles.insert(file)
            let destination = directory.appending(path: file)
            guard !FileManager.default.fileExists(atPath: destination.path()) else { continue }
            if let image = await ImagePipeline.shared.image(for: remote, pointSize: Self.artworkPointSize) {
                try? image.jpegData(compressionQuality: 0.8)?.write(to: destination, options: .atomic)
            }
        }

        let existing = (try? FileManager.default.contentsOfDirectory(atPath: directory.path())) ?? []
        for file in existing where !keptFiles.contains(file) {
            try? FileManager.default.removeItem(at: directory.appending(path: file))
        }
    }

    static func artworkFile(for url: String?) -> String? {
        guard let url, !url.isEmpty else { return nil }
        let digest = SHA256.hash(data: Data(url.utf8)).map { String(format: "%02x", $0) }.joined()
        return "\(digest.prefix(24)).jpg"
    }
}
