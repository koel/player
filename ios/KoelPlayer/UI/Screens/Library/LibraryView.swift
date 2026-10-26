@preconcurrency import Shared
import SwiftUI

struct LibraryView: View {
    @Environment(AppModel.self) private var app

    var body: some View {
        LibraryScreen(core: app.core)
    }
}

/// The library's sections, the albums added last (like Apple Music's Library), then the most played songs.
private struct LibraryScreen: View {
    @Environment(AppModel.self) private var app
    @State private var recentlyAddedAlbums: Live<[Album]>
    @State private var mostPlayedSongs: Live<[any Playable]>
    @State private var containerWidth: CGFloat = 0
    @State private var editingAlbum: Album?

    init(core: KoelCore) {
        _recentlyAddedAlbums = State(initialValue: Live(core.overview.recentlyAddedAlbums))
        _mostPlayedSongs = State(initialValue: Live(core.overview.mostPlayedSongs))
    }

    private var destinations: [LibraryDestination] {
        LibraryDestination.visible(
            supportsPodcasts: app.core.session.supports(feature: .podcasts),
            supportsRadio: app.core.session.supports(feature: .radioStations)
        )
    }

    var body: some View {
        let albums = recentlyAddedAlbums.value
        let songs = mostPlayedSongs.value

        List {
            Group {
                ForEach(destinations) { destination in
                    NavigationLink(value: destination.route) {
                        Label(destination.title, systemImage: destination.systemImage)
                            .font(.title3)
                    }
                }
            }
            .brandListRow()

            if !albums.isEmpty {
                VStack(alignment: .leading, spacing: SectionHeader.contentGap) {
                    SectionHeader(title: "Recently added")
                    AlbumGrid(albums: albums, layout: GridLayout(containerWidth: containerWidth)) { editingAlbum = $0 }
                }
                .padding(.top, SectionHeader.sectionGap)
                .listRowInsets(EdgeInsets())
                .brandListRow()
                .listRowSeparator(.hidden)
            }

            if !songs.isEmpty {
                SectionHeader(title: "Most played")
                    .listRowInsets(EdgeInsets(top: SectionHeader.sectionGap, leading: 0, bottom: SectionHeader.contentGap - PlayableRow.verticalInset, trailing: 0))
                    .brandListRow()
                    .listRowSeparator(.hidden)
                PlayableListContent(playables: songs)
                    .brandListRow()
            }
        }
        .listStyle(.plain)
        .onGeometryChange(for: CGFloat.self, of: \.size.width) { containerWidth = $0 }
        .navigationTitle("Library")
        .brandMeshBackground()
        .albumEditSheet($editingAlbum)
        .task {
            guard albums.isEmpty else { return }
            try? await app.core.overview.refresh()
        }
    }
}
