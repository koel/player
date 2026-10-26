@preconcurrency import Shared
import SwiftUI

struct DownloadsView: View {
    @Environment(AppModel.self) private var app

    var body: some View {
        DownloadsList(downloads: app.core.downloads)
    }
}

private struct DownloadsList: View {
    private static let sortKey = "downloads.sort"

    let downloads: DownloadStore

    @State private var playables: Live<[any Playable]>
    @State private var filter = ""
    @State private var sort = SortSetting.remembered(for: Self.sortKey, default: SortSetting(field: PlayableSortField.shared.TITLE, order: .asc))
    @State private var isConfirmingRemoveAll = false

    init(downloads: DownloadStore) {
        self.downloads = downloads
        _playables = State(initialValue: Live(downloads.playables))
    }

    private var displayed: [any Playable] {
        SortingKt.filtered(SortingKt.sorted(playables.value, field: sort.field, order: sort.order), keywords: filter)
    }

    var body: some View {
        let displayed = displayed

        List {
            Group {
                if !displayed.isEmpty {
                    PlayShuffleButtons(playables: displayed)
                }

                PlayableListContent(playables: displayed, isSortedByTitle: sort.field == PlayableSortField.shared.TITLE) { playable in
                    PlayableRow.Removal(title: "Remove", systemImage: "minus.circle") { downloads.remove(playable: playable) }
                }
            }
            .brandListRow()
        }
        .listStyle(.plain)
        .overlay {
            if playables.value.isEmpty {
                NoDownloadsView()
            }
        }
        .filterable(text: $filter, matchesNothing: !playables.value.isEmpty && displayed.isEmpty, isShown: !playables.value.isEmpty)
        .navigationTitle("Downloaded")
        .brandMeshBackground()
        .toolbar {
            if !playables.value.isEmpty {
                SortToolbarItem(options: SortOptions.songs, sort: sort, rememberKey: Self.sortKey) { sort = $0 }
                ToolbarItem(placement: .primaryAction) {
                    Button("Remove all", systemImage: "arrow.down.circle.dotted", role: .destructive) {
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
            Label("No downloaded songs", systemImage: "arrow.down.circle")
        } description: {
            Text("Tap the \(Image(systemName: "arrow.down.circle")) icon next to a song to download it for offline playback.")
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
            Button("Remove all downloads", role: .destructive) {
                app.core.downloads.clear()
            }
        } message: {
            Text("Downloaded songs will no longer play without a connection.")
        }
    }
}
