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
    @State private var hasLoaded = false
    @State private var isLoading = false
    @State private var hasFailed = false

    init(core: KoelCore) {
        _feed = State(initialValue: HomeFeed(core: core))
    }

    var body: some View {
        ScrollView {
            if feed.isEmpty {
                placeholder
                    .containerRelativeFrame(.vertical)
            } else {
                LazyVStack(alignment: .leading, spacing: 32) {
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
            guard !hasLoaded else { return }
            hasLoaded = true
            await load()
        }
    }

    @ViewBuilder
    private var placeholder: some View {
        if isLoading || !hasLoaded {
            ProgressView()
        } else if hasFailed {
            ContentUnavailableView {
                Label("Couldn't Load Home", systemImage: "exclamationmark.triangle")
            } description: {
                Text("Check your connection and try again.")
            } actions: {
                Button("Try Again") { Task { await load() } }
                    .buttonStyle(.glass)
            }
        } else {
            ContentUnavailableView(
                "No Activities… Yet",
                systemImage: "music.note",
                description: Text("Pull down to refresh this screen.")
            )
        }
    }

    private func load() async {
        guard !isLoading else { return }
        isLoading = true
        defer { isLoading = false }

        do {
            try await feed.refresh()
            hasFailed = false
        } catch where !error.isCancellation {
            hasFailed = true
            if !feed.isEmpty { app.toasts.showError() }
        } catch {}
    }
}

private struct RecentlyPlayedSection: View {
    let playables: [any Playable]

    var body: some View {
        if !playables.isEmpty {
            VStack(spacing: 0) {
                ForEach(playables, id: \.id) { playable in
                    PlayableRow(playable: playable)
                        .padding(.horizontal)
                        .padding(.vertical, 6)
                }
            }
        }
    }
}

private struct HomeBlockCarousel: View {
    let block: HomeBlock
    let items: HomeFeed.Items

    var body: some View {
        switch items {
        case .songs(let songs):
            CardCarousel(title: block.title, seeAll: .songs) {
                ForEach(songs, id: \.id) { CarouselSongCard(playable: $0) }
            }
        case .albums(let albums):
            CardCarousel(title: block.title, seeAll: .albums) {
                ForEach(albums, id: \.id) { CarouselAlbumCard(album: $0) }
            }
        case .artists(let artists):
            CardCarousel(title: block.title, seeAll: .artists) {
                ForEach(artists, id: \.id) { CarouselArtistCard(artist: $0) }
            }
        }
    }
}
