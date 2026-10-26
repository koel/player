@preconcurrency import Shared
import SwiftUI

struct RadioStationsView: View {
    private enum Sheet: Identifiable {
        case newStation
        case edit(RadioStation)

        var id: String {
            switch self {
            case .newStation: "new-station"
            case .edit(let station): "edit:\(station.id)"
            }
        }
    }

    @Environment(AppModel.self) private var app
    @State private var stations: [RadioStation] = []
    @State private var loadState = LoadState()
    @State private var sheet: Sheet?
    @State private var stationPendingDeletion: RadioStation?
    @State private var canAddStations = false

    var body: some View {
        let sortedStations = stations.sorted { $0.name.localizedStandardCompare($1.name) == .orderedAscending }

        List(sortedStations, id: \.id) { station in
            RadioStationRow(station: station)
                .contextMenu {
                    RadioStationMenu(
                        station: station,
                        onEdit: { sheet = .edit(station) },
                        onDelete: { stationPendingDeletion = station }
                    )
                } preview: {
                    RadioStationPreview(station: station)
                }
                .swipeActions(edge: .trailing) {
                    if station.canDelete {
                        ConfirmedRemovalSwipeButton(title: "Delete", systemImage: "trash") { stationPendingDeletion = station }
                    }
                }
                .brandListRow()
        }
        .listStyle(.plain)
        .overlay {
            ListStateOverlay(isEmpty: stations.isEmpty, loadState: loadState, retry: { Task { await load() } }) {
                ContentUnavailableView {
                    Label("No radio stations", systemImage: "antenna.radiowaves.left.and.right")
                } description: {
                    Text("No radio stations available.")
                } actions: {
                    if canAddStations {
                        Button("Add a Station") { sheet = .newStation }
                            .buttonStyle(.glass)
                    }
                }
            }
        }
        .navigationTitle("Radio")
        .brandMeshBackground()
        .toolbar {
            if canAddStations {
                ToolbarItem(placement: .primaryAction) {
                    Button("New Station", systemImage: "plus") { sheet = .newStation }
                }
            }
        }
        .refreshable { await load() }
        .task {
            for await value in app.core.radioStations.stations { stations = value }
        }
        .task {
            for await user in app.core.auth.currentUser { canAddStations = user?.canManageRadioStations ?? false }
        }
        .task { await load() }
        .sheet(item: $sheet) { sheet in
            switch sheet {
            case .newStation: RadioStationFormSheet()
            case .edit(let station): RadioStationFormSheet(station: station)
            }
        }
        .radioStationDeletionConfirmation($stationPendingDeletion) { station in
            RadioStationActions(app: app).delete(station)
        }
    }

    private func load() async {
        await loadState.load { try await app.core.radioStations.fetchAll() }
    }
}

private struct RadioStationRow: View {
    let station: RadioStation

    @Environment(AppModel.self) private var app

    var body: some View {
        let actions = RadioStationActions(app: app)

        Button {
            actions.play(station)
        } label: {
            HStack(spacing: 12) {
                MediaRow(title: station.name, subtitle: station.description_.flatMap { $0.isEmpty ? nil : $0 }) {
                    RadioStationLogo(station: station, size: 44)
                        .nowPlayingOverlay(isCurrent: actions.isCurrent(station), isPlaying: actions.isLive(station), size: 44)
                }

                Spacer(minLength: 0)

                if station.favorite {
                    Image(systemName: "heart.fill")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .accessibilityLabel("Favorite")
                }
            }
            .contentShape(.rect)
        }
        .buttonStyle(.plain)
    }
}

/// Context menu items for a station, on its row and its carousel card.
struct RadioStationMenu: View {
    let station: RadioStation
    let onEdit: () -> Void
    let onDelete: () -> Void

    @Environment(AppModel.self) private var app

    var body: some View {
        let actions = RadioStationActions(app: app)

        Section {
            if actions.isLive(station) {
                Button("Stop", systemImage: "stop.fill", action: actions.stop)
            } else {
                Button("Play", systemImage: "play.fill") { actions.play(station) }
            }
            if actions.supportsFavorites {
                EntityFavoriteButton(isFavorite: station.favorite) {
                    try await app.core.radioStations.toggleFavorite(station: station)
                }
            }
        }

        Section {
            if station.canEdit {
                Button("Edit…", systemImage: "pencil", action: onEdit)
            }
            if station.canDelete {
                Button("Delete", systemImage: "trash", role: .destructive, action: onDelete)
            }
        }
    }
}

/// The station's logo, or a radio symbol when it has none.
struct RadioStationLogo: View {
    let station: RadioStation
    let size: CGFloat
    var cornerRadius: CGFloat = 6

    var body: some View {
        Artwork(url: station.logo, size: size, cornerRadius: cornerRadius, fallbackSymbol: "antenna.radiowaves.left.and.right")
    }
}
