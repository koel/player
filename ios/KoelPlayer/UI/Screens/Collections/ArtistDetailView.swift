@preconcurrency import Shared
import SwiftUI

struct ArtistDetailView: View {
    let artistId: String

    @Environment(AppModel.self) private var app
    @State private var artist: Artist?
    @State private var songs: [any Playable] = []
    @State private var biography = ""
    @State private var sort = SortSetting.remembered(for: Self.sortKey, default: SortSetting(field: PlayableSortField.shared.TITLE, order: .asc))
    @State private var query = ""
    @State private var hasFailed = false
    @State private var editingArtist: Artist?

    private static let sortKey = "artist.sort"

    private var displayedSongs: [any Playable] {
        SortingKt.filtered(SortingKt.sorted(songs, field: sort.field, order: sort.order), keywords: query)
    }

    var body: some View {
        List {
            if let artist {
                CollectionHeader(
                    artworkUrl: artist.imageUrl,
                    title: artist.name,
                    detail: CollectionSummary.detail(songs: songs),
                    isCircular: true,
                    playables: displayedSongs
                )
                .listRowSeparator(.hidden)

                PlayableListContent(
                    playables: displayedSongs,
                    style: .artist,
                    isSortedByTitle: sort.field == PlayableSortField.shared.TITLE
                )

                AboutSection(title: "About", html: biography)
            }
        }
        .listStyle(.plain)
        .navigationTitle(artist?.name ?? "")
        .navigationBarTitleDisplayMode(.inline)
        .searchable(text: $query, prompt: "Filter Songs")
        .refreshable { await load(forceRefresh: true) }
        .toolbar {
            if let artist {
                CollectionToolbar(
                    isFavorite: artist.favorite,
                    toggleFavorite: { try await app.core.artists.toggleFavorite(artist: artist) },
                    sortOptions: SortOptions.artistSongs,
                    sort: $sort,
                    sortKey: Self.sortKey
                ) {
                    ArtistMenu(artist: artist) { editingArtist = artist }
                }
            }
        }
        .overlay {
            if artist == nil {
                if hasFailed {
                    LoadFailedView { Task { await load() } }
                } else {
                    ProgressView()
                }
            }
        }
        .artistEditSheet($editingArtist)
        .collect(app.core.artists.observe(id: artistId), id: artistId) { artist = $0 }
        .collect(app.core.playables.artistSongs(artistId: artistId), id: artistId) { songs = $0 }
        .task(id: artistId) { await load() }
        .task(id: artistId) {
            biography = (try? await app.core.mediaInfo.fetchForArtist(artistId: artistId).biography) ?? ""
        }
    }

    private func load(forceRefresh: Bool = false) async {
        do {
            async let resolvedArtist = app.core.artists.resolve(id: artistId, forceRefresh: forceRefresh)
            async let fetchedSongs = app.core.playables.fetchForArtist(artistId: artistId, forceRefresh: forceRefresh)
            _ = try await (resolvedArtist, fetchedSongs)
            hasFailed = false
        } catch {
            hasFailed = true
        }
    }
}
