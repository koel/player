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

extension Album {
    var hasBrowsableArtist: Bool {
        artistName != "Unknown Artist" && artistName != "Various Artists"
    }
}

struct AlbumEditSheet: View {
    let album: Album

    @Environment(AppModel.self) private var app
    @State private var name: String
    @State private var year: String

    init(album: Album) {
        self.album = album
        _name = State(initialValue: album.name)
        _year = State(initialValue: album.year.map { "\($0.intValue)" } ?? "")
    }

    private var trimmedName: String {
        name.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    var body: some View {
        FormSheet(
            title: "Edit Album",
            submitLabel: "Save",
            canSubmit: !trimmedName.isEmpty,
            failureMessage: { _ in "Could not update album." },
            submit: save
        ) {
            TextField("Album Name", text: $name)
            TextField("Year (optional)", text: $year)
                .keyboardType(.numberPad)
                .onChange(of: year) { _, newValue in year = YearInput.sanitized(newValue) }
        }
    }

    private func save() async throws {
        let savedYear = YearInput.value(year).map { KotlinInt(int: Int32($0)) }
        _ = try await app.core.albums.update(album: album, name: trimmedName, year: savedYear)
        app.toasts.show("Album updated")
    }
}

extension View {
    func albumEditSheet(_ album: Binding<Album?>) -> some View {
        sheet(isPresented: album.isPresent) {
            if let editing = album.wrappedValue {
                AlbumEditSheet(album: editing)
            }
        }
    }
}
