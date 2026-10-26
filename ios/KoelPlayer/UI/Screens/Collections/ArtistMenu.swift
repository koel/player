@preconcurrency import Shared
import SwiftUI

/// The actions for an artist, used by its context menu and its screen's "…" button.
struct ArtistMenu: View {
    let artist: Artist
    var onEdit: (() -> Void)?

    @Environment(AppModel.self) private var app

    var body: some View {
        let queue = CollectionQueueActions.artist(artist, app: app)

        ControlGroup {
            if app.core.session.supports(feature: .favoriteEntities) {
                EntityFavoriteButton(isFavorite: artist.favorite) {
                    try await app.core.artists.toggleFavorite(artist: artist)
                }
            }
            Button("Info", systemImage: "info.circle") { app.sheet = .artistInfo(artist) }
                .disabled(app.isOffline)
        }

        Section {
            Button("Play", systemImage: "play") { queue.play() }
            Button("Shuffle", systemImage: "shuffle") { queue.play(shuffled: true) }
            Button("Play Next", systemImage: "text.line.first.and.arrowtriangle.forward") { queue.playNext() }
            Button("Play Last", systemImage: "text.line.last.and.arrowtriangle.forward") { queue.playLast() }
        }

        if artist.canEdit, let onEdit {
            Section {
                Button("Edit…", systemImage: "pencil", action: onEdit)
            }
        }
    }
}

/// The artist's biography, opened from the Info button in its menu.
struct ArtistInfoSheet: View {
    let artist: Artist

    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            ArtistBiography(artistId: artist.id)
                .navigationTitle(artist.name)
                .navigationBarTitleDisplayMode(.inline)
                .toolbar {
                    ToolbarItem(placement: .confirmationAction) {
                        Button("Done", systemImage: "checkmark") { dismiss() }
                    }
                }
        }
        .presentationDetents([.medium, .large])
        .presentationBackground(Color(uiColor: .systemBackground))
    }
}

struct ArtistEditSheet: View {
    let artist: Artist

    @Environment(AppModel.self) private var app
    @State private var name: String

    init(artist: Artist) {
        self.artist = artist
        _name = State(initialValue: artist.name)
    }

    private var trimmedName: String {
        name.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    var body: some View {
        FormSheet(
            title: "Edit Artist",
            submitLabel: "Save",
            canSubmit: !trimmedName.isEmpty,
            failureMessage: { _ in "Could not update artist." },
            submit: save
        ) {
            TextField("Artist Name", text: $name)
        }
    }

    private func save() async throws {
        _ = try await app.core.artists.update(artist: artist, name: trimmedName)
        app.toasts.show("Artist updated")
    }
}

extension View {
    func artistEditSheet(_ artist: Binding<Artist?>) -> some View {
        sheet(isPresented: artist.isPresent) {
            if let editing = artist.wrappedValue {
                ArtistEditSheet(artist: editing)
            }
        }
    }
}
