@preconcurrency import Shared
import SwiftUI

/// Playlist actions with the feedback Flutter showed, shared by the list, the detail screen and menus.
struct PlaylistActions {
    let app: AppModel

    /// Queues every song of `playlists` at the end, as the Flutter swipe gesture did.
    func queue(_ playlists: [Playlist]) {
        Task {
            var songs: [any Playable] = []
            for playlist in playlists {
                songs += (try? await app.core.playables.fetchForPlaylist(playlistId: playlist.id)) ?? []
            }

            if songs.isEmpty {
                app.toasts.show("No songs found.", systemImage: "nosign")
            } else {
                PlayableActions(app: app).playLast(songs)
            }
        }
    }

    func delete(_ playlist: Playlist) {
        Task {
            do {
                try await app.core.playlists.remove(playlist: playlist)
                app.toasts.show("Playlist deleted", systemImage: "trash")
            } catch {
                app.toasts.showError(message: "Could not delete playlist.")
            }
        }
    }

    func move(_ playlist: Playlist, toFolderId folderId: String?) {
        Task {
            do {
                try await app.core.playlists.update(
                    playlist: playlist,
                    name: playlist.name,
                    description: playlist.description_,
                    folderId: folderId
                )
                app.toasts.show("Playlist updated")
            } catch {
                app.toasts.showError(message: "Could not update playlist.")
            }
        }
    }

    func add(_ playables: [any Playable], to playlist: Playlist) {
        // Kotlin playables are immutable, so handing the array to the shared core is safe.
        nonisolated(unsafe) let playables = playables
        Task {
            do {
                try await app.core.playlists.addToPlaylist(playables: playables, playlist: playlist)
                app.toasts.show("Added", message: "Item added to playlist.", systemImage: "text.badge.plus")
            } catch {
                app.toasts.showError(message: "Could not add to playlist.")
            }
        }
    }

    func remove(_ playable: any Playable, from playlist: Playlist) {
        Task {
            do {
                try await app.core.playlists.removeFromPlaylist(playables: [playable], playlist: playlist)
                app.toasts.show("Removed from Playlist", systemImage: "minus.circle")
            } catch {
                app.toasts.showError(message: "Could not remove from playlist.")
            }
        }
    }
}

extension View {
    func playlistDeletionConfirmation(_ playlist: Binding<Playlist?>, onDelete: @escaping (Playlist) -> Void) -> some View {
        destructiveConfirmation(
            "Delete playlist?",
            item: playlist,
            actionLabel: "Delete",
            message: { "Delete \"\($0.name)\"? This cannot be undone." },
            action: onDelete
        )
    }
}
