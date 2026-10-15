@preconcurrency import Shared
import SwiftUI

/// The actions for an artist, used by its context menu and its screen's "…" button.
struct ArtistMenu: View {
    let artist: Artist
    var onEdit: (() -> Void)?

    @Environment(AppModel.self) private var app

    var body: some View {
        let queue = CollectionQueueActions.artist(artist, app: app)

        if app.core.session.supports(feature: .favoriteEntities) {
            Section {
                EntityFavoriteButton(isFavorite: artist.favorite) {
                    try await app.core.artists.toggleFavorite(artist: artist)
                }
            }
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

struct ArtistEditSheet: View {
    let artist: Artist

    @Environment(AppModel.self) private var app
    @Environment(\.dismiss) private var dismiss
    @State private var name: String
    @State private var isSaving = false

    init(artist: Artist) {
        self.artist = artist
        _name = State(initialValue: artist.name)
    }

    private var trimmedName: String {
        name.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    var body: some View {
        NavigationStack {
            Form {
                TextField("Artist Name", text: $name)
            }
            .navigationTitle("Edit Artist")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button(role: .cancel) { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button(role: .confirm, action: save)
                        .disabled(trimmedName.isEmpty || isSaving)
                }
            }
        }
        .presentationDetents([.height(200), .medium])
    }

    private func save() {
        isSaving = true
        Task {
            defer { isSaving = false }
            do {
                _ = try await app.core.artists.update(artist: artist, name: trimmedName)
                dismiss()
                app.toasts.show("Artist Updated")
            } catch {
                app.toasts.showError("Could not update artist")
            }
        }
    }
}

extension View {
    func artistEditSheet(_ artist: Binding<Artist?>) -> some View {
        sheet(isPresented: Binding(get: { artist.wrappedValue != nil }, set: { if !$0 { artist.wrappedValue = nil } })) {
            if let editing = artist.wrappedValue {
                ArtistEditSheet(artist: editing)
            }
        }
    }
}
