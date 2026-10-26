@preconcurrency import Shared
import SwiftUI

/// The fields of the New Station and Edit Station sheets.
struct RadioStationDraft {
    var name = ""
    var url = ""
    var description = ""
    var isPublic = false

    init() {}

    init(station: RadioStation) {
        name = station.name
        url = station.url
        description = station.description_ ?? ""
        isPublic = station.isPublic
    }

    var trimmedName: String { name.trimmingCharacters(in: .whitespacesAndNewlines) }
    var trimmedURL: String { url.trimmingCharacters(in: .whitespacesAndNewlines) }
    var trimmedDescription: String { description.trimmingCharacters(in: .whitespacesAndNewlines) }
    var isValid: Bool { !trimmedName.isEmpty && trimmedURL.isWebURL }
}

/// Radio station actions with the feedback Flutter showed, shared by rows and menus.
struct RadioStationActions {
    let app: AppModel

    var supportsFavorites: Bool {
        app.core.session.supports(feature: .favoriteEntities)
    }

    func isCurrent(_ station: RadioStation) -> Bool {
        app.player.state.radioStation?.id == station.id
    }

    func isLive(_ station: RadioStation) -> Bool {
        isCurrent(station) && (app.player.state.isPlaying || app.player.state.isBuffering)
    }

    func play(_ station: RadioStation) {
        Task {
            do {
                try await app.player.controller.playRadio(station: station)
            } catch {
                app.toasts.showError(message: "Could not play station.")
            }
        }
    }

    func stop() {
        app.player.controller.stopRadio()
    }

    func delete(_ station: RadioStation) {
        Task {
            do {
                try await app.core.radioStations.remove(station: station)
                app.toasts.show("Station deleted", systemImage: "trash")
            } catch {
                app.toasts.showError(message: "Could not delete station.")
            }
        }
    }
}

extension View {
    func radioStationDeletionConfirmation(_ station: Binding<RadioStation?>, onDelete: @escaping (RadioStation) -> Void) -> some View {
        destructiveConfirmation(
            "Delete station?",
            item: station,
            actionLabel: "Delete",
            message: { "Delete \"\($0.name)\"? This cannot be undone." },
            action: onDelete
        )
    }
}

struct RadioStationFormSheet: View {
    let station: RadioStation?

    @Environment(AppModel.self) private var app
    @State private var draft: RadioStationDraft
    @FocusState private var isNameFocused: Bool

    init(station: RadioStation? = nil) {
        self.station = station
        _draft = State(initialValue: station.map(RadioStationDraft.init) ?? RadioStationDraft())
    }

    var body: some View {
        let isEditing = station != nil

        FormSheet(
            title: isEditing ? "Edit Station" : "New Station",
            submitLabel: isEditing ? "Save" : "Add",
            canSubmit: draft.isValid,
            failureMessage: { _ in isEditing ? "Could not update station." : "Could not add station." },
            submit: save
        ) {
            Section {
                TextField("Station Name", text: $draft.name)
                    .focused($isNameFocused)
                TextField("Stream URL", text: $draft.url)
                    .keyboardType(.URL)
                    .textContentType(.URL)
                    .textInputAutocapitalization(.never)
                    .autocorrectionDisabled()
                TextField("Description (optional)", text: $draft.description, axis: .vertical)
                    .lineLimit(2...4)
            }
            Section {
                Toggle("Accessible to all users", isOn: $draft.isPublic)
            }
        }
        .onAppear { isNameFocused = !isEditing }
    }

    private func save() async throws {
        let stations = app.core.radioStations
        if let station {
            try await stations.update(
                station: station,
                name: draft.trimmedName,
                url: draft.trimmedURL,
                description: draft.trimmedDescription,
                isPublic: draft.isPublic
            )
            if RadioStationActions(app: app).isCurrent(station), let updated = stations.byId(id: station.id) {
                app.player.controller.refreshRadioStation(station: updated)
            }
            app.toasts.show("Station updated")
        } else {
            _ = try await stations.create(
                name: draft.trimmedName,
                url: draft.trimmedURL,
                description: draft.trimmedDescription,
                isPublic: draft.isPublic
            )
            app.toasts.show("Station added")
        }
    }
}

extension RadioStation: @retroactive Identifiable {}
