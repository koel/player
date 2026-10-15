@preconcurrency import Shared
import SwiftUI

struct DownloadsView: View {
    @Environment(AppModel.self) private var app

    var body: some View {
        DownloadsList(downloads: app.core.downloads)
    }
}

private struct DownloadsList: View {
    private static let sortOptions = [
        (field: "title", label: "Title"),
        (field: "artist_name", label: "Artist"),
        (field: "created_at", label: "Recently Added"),
    ]

    let downloads: DownloadStore

    @State private var playables: Live<[any Playable]>
    @State private var filter = ""
    @State private var sortField = "title"
    @State private var sortOrder = Shared.SortOrder.asc
    @State private var isConfirmingRemoveAll = false

    init(downloads: DownloadStore) {
        self.downloads = downloads
        _playables = State(initialValue: Live(downloads.playables))
    }

    private var displayed: [any Playable] {
        SortingKt.filtered(SortingKt.sorted(playables.value, field: sortField, order: sortOrder), keywords: filter)
    }

    var body: some View {
        let displayed = displayed

        List {
            if !displayed.isEmpty {
                PlayShuffleButtons(playables: displayed)
                    .listRowInsets(EdgeInsets(top: 8, leading: 0, bottom: 8, trailing: 0))
                    .listRowSeparator(.hidden)
            }

            ForEach(displayed, id: \.id) { playable in
                PlayableRow(playable: playable, removal: .init(title: "Remove", systemImage: "minus.circle") { downloads.remove(playable: playable) })
            }
        }
        .listStyle(.plain)
        .overlay {
            if playables.value.isEmpty {
                NoDownloadsView()
            } else if displayed.isEmpty {
                ContentUnavailableView.search(text: filter)
            }
        }
        .filterable(text: $filter, prompt: "Filter")
        .navigationTitle("Downloaded")
        .toolbar {
            if !playables.value.isEmpty {
                ToolbarItem(placement: .topBarTrailing) {
                    SortMenu(options: Self.sortOptions, field: sortField, order: sortOrder) { field, order in
                        sortField = field
                        sortOrder = order
                    }
                }
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Remove All", systemImage: "arrow.down.circle.dotted", role: .destructive) {
                        isConfirmingRemoveAll = true
                    }
                }
            }
        }
        .removeAllDownloadsConfirmation(isPresented: $isConfirmingRemoveAll)
    }
}

private struct NoDownloadsView: View {
    var body: some View {
        ContentUnavailableView {
            Label("No Downloaded Songs", systemImage: "arrow.down.circle")
        } description: {
            Text("Choose Download from a song's menu to play it without a connection.")
        }
    }
}

extension View {
    func removeAllDownloadsConfirmation(isPresented: Binding<Bool>) -> some View {
        modifier(RemoveAllDownloadsConfirmation(isPresented: isPresented))
    }
}

private struct RemoveAllDownloadsConfirmation: ViewModifier {
    @Binding var isPresented: Bool

    @Environment(AppModel.self) private var app

    func body(content: Content) -> some View {
        content.confirmationDialog("Remove all downloads?", isPresented: $isPresented, titleVisibility: .visible) {
            Button("Remove All Downloads", role: .destructive) {
                app.core.downloads.clear()
            }
        } message: {
            Text("Downloaded songs will no longer play without a connection.")
        }
    }
}
