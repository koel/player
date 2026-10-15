@preconcurrency import Shared

/// Play, shuffle and queue a whole album or artist from a menu, fetching its songs first.
struct CollectionQueueActions {
    let app: AppModel
    let fetchSongs: () async throws -> [any Playable]

    static func album(_ album: Album, app: AppModel) -> Self {
        Self(app: app) { try await app.core.playables.fetchForAlbum(albumId: album.id) }
    }

    static func artist(_ artist: Artist, app: AppModel) -> Self {
        Self(app: app) { try await app.core.playables.fetchForArtist(artistId: artist.id) }
    }

    func play(shuffled: Bool = false) {
        withSongs { songs in app.player.play(songs, shuffled: shuffled) }
    }

    /// Each song goes right after the current one, so going backwards keeps the original order.
    func playNext() {
        withSongs { songs in
            songs.reversed().forEach(app.player.playNext)
            app.toasts.show("Playing Next", systemImage: "text.line.first.and.arrowtriangle.forward")
        }
    }

    func playLast() {
        withSongs { songs in PlayableActions(app: app).playLast(songs) }
    }

    private func withSongs(_ action: @escaping ([any Playable]) -> Void) {
        Task {
            do {
                let songs = try await fetchSongs()
                guard !songs.isEmpty else { return }
                action(songs)
            } catch {
                app.toasts.showError()
            }
        }
    }
}
