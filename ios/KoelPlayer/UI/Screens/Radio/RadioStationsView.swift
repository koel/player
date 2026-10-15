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
    @State private var isLoading = true
    @State private var loadFailed = false
    @State private var sheet: Sheet?
    @State private var stationPendingDeletion: RadioStation?

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
                        Button("Delete", systemImage: "trash") { stationPendingDeletion = station }
                            .tint(.red)
                    }
                }
        }
        .overlay { placeholder }
        .navigationTitle("Radio")
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                Button("New Station", systemImage: "plus") { sheet = .newStation }
            }
        }
        .refreshable { await load() }
        .task {
            for await value in app.core.radioStations.stations { stations = value }
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

    @ViewBuilder
    private var placeholder: some View {
        if stations.isEmpty {
            if isLoading {
                ProgressView()
            } else if loadFailed {
                ContentUnavailableView {
                    Label("Couldn't Load Stations", systemImage: "exclamationmark.triangle")
                } actions: {
                    Button("Try Again") { Task { await load() } }
                        .buttonStyle(.glass)
                }
            } else {
                ContentUnavailableView {
                    Label("No Radio Stations", systemImage: "antenna.radiowaves.left.and.right")
                } description: {
                    Text("No radio stations available.")
                } actions: {
                    Button("Add a Station") { sheet = .newStation }
                        .buttonStyle(.glassProminent)
                }
            }
        }
    }

    private func load() async {
        isLoading = true
        defer { isLoading = false }
        do {
            try await app.core.radioStations.fetchAll()
            loadFailed = false
        } catch {
            loadFailed = true
        }
    }
}

private struct RadioStationRow: View {
    let station: RadioStation

    @Environment(AppModel.self) private var app

    var body: some View {
        let actions = RadioStationActions(app: app)
        let isCurrent = actions.isCurrent(station)

        Button {
            actions.play(station)
        } label: {
            HStack(spacing: 12) {
                StationLogo(station: station, size: 44)
                    .overlay {
                        if isCurrent {
                            NowPlayingIndicator(isPlaying: actions.isLive(station))
                                .frame(width: 44, height: 44)
                                .background(.black.opacity(0.45), in: .rect(cornerRadius: 6))
                        }
                    }

                VStack(alignment: .leading, spacing: 2) {
                    Text(station.name)
                        .lineLimit(1)
                        .foregroundStyle(isCurrent ? Color.highlight : .primary)
                    if let description = station.description_, !description.isEmpty {
                        Text(description)
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                            .lineLimit(1)
                    }
                }

                Spacer(minLength: 0)

                if station.favorite {
                    Image(systemName: "star.fill")
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

private struct RadioStationMenu: View {
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
                Button(
                    station.favorite ? "Undo Favorite" : "Favorite",
                    systemImage: station.favorite ? "star.slash" : "star"
                ) {
                    actions.toggleFavorite(station)
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
private struct StationLogo: View {
    let station: RadioStation
    let size: CGFloat
    var cornerRadius: CGFloat = 6

    var body: some View {
        if let logo = station.logo, !logo.isEmpty {
            Artwork(url: logo, size: size, cornerRadius: cornerRadius)
        } else {
            Image(systemName: "antenna.radiowaves.left.and.right")
                .font(.system(size: size * 0.4))
                .foregroundStyle(.secondary)
                .frame(width: size, height: size)
                .background(.quaternary, in: .rect(cornerRadius: cornerRadius))
                .accessibilityHidden(true)
        }
    }
}

private struct RadioStationPreview: View {
    let station: RadioStation

    var body: some View {
        VStack(spacing: 12) {
            StationLogo(station: station, size: 220, cornerRadius: 12)
            VStack(spacing: 4) {
                Text(station.name).font(.headline)
                if let description = station.description_, !description.isEmpty {
                    Text(description)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
            }
            .multilineTextAlignment(.center)
            .lineLimit(3)
        }
        .padding(20)
        .frame(width: 280)
    }
}
