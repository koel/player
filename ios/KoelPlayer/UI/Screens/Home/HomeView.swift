@preconcurrency import Shared
import SwiftUI

struct HomeView: View {
    @Environment(AppModel.self) private var app

    var body: some View {
        HomeScreen(core: app.core)
    }
}

private struct HomeScreen: View {
    @Environment(AppModel.self) private var app
    @State private var feed: HomeFeed
    @State private var loadState = LoadState()

    init(core: KoelCore) {
        _feed = State(initialValue: HomeFeed(core: core))
    }

    var body: some View {
        ScrollView {
            if feed.isEmpty {
                placeholder
                    .containerRelativeFrame(.vertical)
            } else {
                LazyVStack(alignment: .leading, spacing: SectionHeader.sectionGap) {
                    RecentlyPlayedSection(playables: feed.recentlyPlayed)
                    ForEach(feed.blocks, id: \.self) { block in
                        HomeBlockCarousel(block: block, items: feed.items(for: block))
                    }
                }
                .padding(.vertical)
            }
        }
        .refreshable { await load() }
        .navigationTitle("Home")
        .brandMeshBackground()
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                NavigationLink(value: Route.recentlyPlayed) {
                    Label("Recently Played", systemImage: "clock")
                }
            }
            ToolbarSpacer(.fixed, placement: .topBarTrailing)
            ToolbarItem(placement: .topBarTrailing) {
                ProfileMenu(user: feed.user)
            }
        }
        .task {
            guard !loadState.hasLoaded else { return }
            await load()
        }
    }

    private var placeholder: some View {
        ListStateOverlay(isEmpty: true, loadState: loadState, retry: { Task { await load() } }) {
            ContentUnavailableView(
                "No activities… yet",
                systemImage: "music.note",
                description: Text("Pull down to refresh this screen.")
            )
        }
    }

    private func load() async {
        await loadState.load { try await feed.refresh() }
        if loadState.hasFailed, !feed.isEmpty { app.toasts.showError() }
    }
}

private struct RecentlyPlayedSection: View {
    let playables: [any Playable]

    var body: some View {
        if !playables.isEmpty {
            PlayableRowStack(playables: playables)
        }
    }
}

struct HomeBlockCarousel: View {
    let block: HomeBlock
    let items: HomeFeed.Items

    var body: some View {
        switch items {
        case .songs(let songs):
            CardCarousel(title: block.title, seeAll: block.seeAll) {
                ForEach(songs, id: \.id) { CarouselSongCard(playable: $0) }
            }
        case .albums(let albums):
            CardCarousel(title: block.title, seeAll: block.seeAll) {
                ForEach(albums, id: \.id) { CarouselAlbumCard(album: $0) }
            }
        case .artists(let artists):
            CardCarousel(title: block.title, seeAll: block.seeAll) {
                ForEach(artists, id: \.id) { CarouselArtistCard(artist: $0) }
            }
        }
    }
}
