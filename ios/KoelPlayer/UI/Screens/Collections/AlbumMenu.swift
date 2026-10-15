@preconcurrency import Shared
import SwiftUI

/// The actions for an album, used by its context menu and its screen's "…" button.
struct AlbumMenu: View {
    let album: Album
    var onEdit: (() -> Void)?

    @Environment(AppModel.self) private var app

    var body: some View {
        let queue = CollectionQueueActions.album(album, app: app)

        if app.core.session.supports(feature: .favoriteEntities) {
            Section {
                EntityFavoriteButton(isFavorite: album.favorite) {
                    try await app.core.albums.toggleFavorite(album: album)
                }
            }
        }

        Section {
            Button("Play", systemImage: "play") { queue.play() }
            Button("Shuffle", systemImage: "shuffle") { queue.play(shuffled: true) }
            Button("Play Next", systemImage: "text.line.first.and.arrowtriangle.forward") { queue.playNext() }
            Button("Play Last", systemImage: "text.line.last.and.arrowtriangle.forward") { queue.playLast() }
        }

        Section {
            if album.hasBrowsableArtist {
                Button("Go to Artist", systemImage: "music.microphone") {
                    app.navigator.push(.artist(id: album.artistId))
                }
            }
            if album.canEdit, let onEdit {
                Button("Edit…", systemImage: "pencil", action: onEdit)
            }
        }
    }
}

/// Favorite or Undo Favorite for albums, artists and the like; failures roll back in the store.
struct EntityFavoriteButton: View {
    let isFavorite: Bool
    let toggle: () async throws -> Void

    @Environment(AppModel.self) private var app

    var body: some View {
        Button(isFavorite ? "Undo Favorite" : "Favorite", systemImage: isFavorite ? "star.slash" : "star") {
            Task {
                do {
                    try await toggle()
                } catch {
                    app.toasts.showError()
                }
            }
        }
    }
}

extension Album {
    var hasBrowsableArtist: Bool {
        artistName != "Unknown Artist" && artistName != "Various Artists"
    }
}

struct AlbumEditSheet: View {
    let album: Album

    @Environment(AppModel.self) private var app
    @Environment(\.dismiss) private var dismiss
    @State private var name: String
    @State private var year: String
    @State private var isSaving = false

    init(album: Album) {
        self.album = album
        _name = State(initialValue: album.name)
        _year = State(initialValue: album.year.map { "\($0.intValue)" } ?? "")
    }

    private var trimmedName: String {
        name.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    var body: some View {
        NavigationStack {
            Form {
                TextField("Album Name", text: $name)
                TextField("Year (optional)", text: $year)
                    .keyboardType(.numberPad)
                    .onChange(of: year) { _, newValue in year = YearInput.sanitized(newValue) }
            }
            .navigationTitle("Edit Album")
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
        .presentationDetents([.medium])
    }

    private func save() {
        isSaving = true
        Task {
            defer { isSaving = false }
            do {
                let savedYear = YearInput.value(year).map { KotlinInt(int: Int32($0)) }
                _ = try await app.core.albums.update(album: album, name: trimmedName, year: savedYear)
                dismiss()
                app.toasts.show("Album Updated")
            } catch {
                app.toasts.showError("Could not update album")
            }
        }
    }
}

extension View {
    func albumEditSheet(_ album: Binding<Album?>) -> some View {
        sheet(isPresented: Binding(get: { album.wrappedValue != nil }, set: { if !$0 { album.wrappedValue = nil } })) {
            if let editing = album.wrappedValue {
                AlbumEditSheet(album: editing)
            }
        }
    }
}
