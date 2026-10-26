@preconcurrency import Shared
import SwiftUI

/// The actions for one song or episode, used by context menus and "…" buttons alike.
struct PlayableMenu: View {
    let playable: any Playable

    @Environment(AppModel.self) private var app

    var body: some View {
        let isCurrent = app.player.isCurrent(playable)

        ControlGroup {
            Button(
                playable.favorite ? "Undo Favorite" : "Favorite",
                systemImage: playable.favorite ? "heart.slash" : "heart"
            ) {
                PlayableActions(app: app).toggleFavorite(playable)
            }
            .disabled(app.isOffline)

            Button("Details", systemImage: "text.quote") {
                app.sheet = .details(playable)
            }

            if app.isDownloaded(playable) {
                Button("Remove Download", systemImage: "arrow.down.circle.dotted", role: .destructive) {
                    app.core.downloads.remove(playable: playable)
                }
            } else {
                Button("Download", systemImage: "arrow.down.circle") {
                    PlayableActions(app: app).download(playable)
                }
                .disabled(app.isOffline || app.isDownloading(playable))
            }
        }

        Section {
            if !isCurrent {
                Button("Play Next", systemImage: "text.line.first.and.arrowtriangle.forward") {
                    PlayableActions(app: app).playNext(playable)
                }
                Button("Play Last", systemImage: "text.line.last.and.arrowtriangle.forward") {
                    PlayableActions(app: app).playLast(playable)
                }
            }
            if app.player.isQueued(playable) {
                Button("Remove from Queue", systemImage: "minus.circle") {
                    PlayableActions(app: app).removeFromQueue(playable)
                }
            }
        }

        Section {
            if let song = playable as? Song {
                Button("Go to Album", systemImage: "square.stack") {
                    app.open(.album(id: song.albumId))
                }
                .disabled(app.isOffline)
                Button("Go to Artist", systemImage: "music.microphone") {
                    app.open(.artist(id: song.artistId))
                }
                .disabled(app.isOffline)
            }
            if let episode = playable as? Episode {
                Button("Go to Podcast", systemImage: "mic") {
                    app.open(.podcast(id: episode.podcastId))
                }
                .disabled(app.isOffline)
            }
            Button("Add to a Playlist…", systemImage: "text.badge.plus") {
                app.sheet = .addToPlaylist([playable])
            }
            .disabled(app.isOffline)
        }
    }
}

/// Playable actions with the user feedback Flutter showed, shared by menus, swipes and buttons.
struct PlayableActions {
    let app: AppModel

    func playNext(_ playable: any Playable) {
        app.player.playNext(playable)
        showQueuedNext()
    }

    func playNext(_ playables: [any Playable]) {
        guard !playables.isEmpty else { return }
        app.player.playNext(playables)
        showQueuedNext()
    }

    func playLast(_ playable: any Playable) {
        app.player.playLast(playable)
        showQueuedLast()
    }

    /// Queues a whole album, artist or playlist at the end, as the Flutter swipe gesture did.
    func playLast(_ playables: [any Playable]) {
        guard !playables.isEmpty else { return }
        app.player.playLast(playables)
        showQueuedLast()
    }

    func removeFromQueue(_ playable: any Playable) {
        app.player.removeFromQueue(playable)
        app.toasts.show("Removed", message: "Removed from queue.", systemImage: "text.badge.minus")
    }

    private func showQueuedNext() {
        app.toasts.show("Queued", message: "To be played next.", systemImage: "arrow.right.circle.fill")
    }

    private func showQueuedLast() {
        app.toasts.show("Queued", message: "Queued to bottom.", systemImage: "arrow.down.right.circle.fill")
    }

    func toggleFavorite(_ playable: any Playable) {
        Task {
            do {
                try await app.core.favorites.toggle(playable: playable)
            } catch {
                app.toasts.showError()
            }
        }
    }

    func download(_ playable: any Playable) {
        Task {
            do {
                try await app.core.downloads.download(playable: playable)
            } catch {
                app.toasts.showError("Download failed")
            }
        }
    }
}
