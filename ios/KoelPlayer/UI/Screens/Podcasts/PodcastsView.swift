@preconcurrency import Shared
import SwiftUI

struct PodcastsView: View {
    @Environment(AppModel.self) private var app
    @State private var podcasts: [Podcast] = []
    @State private var newEpisodes: [any Playable] = []
    @State private var loadState = LoadState()
    @State private var isAddingPodcast = false
    @State private var podcastPendingUnsubscribe: Podcast?
    @State private var sort = SortSetting.remembered(for: Self.sortKey, default: SortSetting(field: PodcastSortOption.lastPlayedAt.rawValue, order: .desc))

    private static let sortKey = "podcasts.sort"

    private var sortField: PodcastSortField {
        (PodcastSortOption(rawValue: sort.field) ?? .lastPlayedAt).field
    }

    var body: some View {
        let sortedPodcasts = PodcastSortingKt.sorted(podcasts, field: sortField, order: sort.order)

        List {
            if !newEpisodes.isEmpty {
                SectionHeader(title: "New Episodes")
                    .listRowInsets(EdgeInsets(top: 8, leading: 0, bottom: SectionHeader.contentGap - PlayableRow.verticalInset, trailing: 0))
                    .brandListRow()
                    .listRowSeparator(.hidden)
                PlayableListContent(playables: newEpisodes)
                    .brandListRow()
            }

            ForEach(sortedPodcasts, id: \.id) { podcast in
                NavigationLink(value: Route.podcast(id: podcast.id)) {
                    PodcastRow(podcast: podcast)
                }
                .contextMenu {
                    PodcastMenu(podcast: podcast) { podcastPendingUnsubscribe = podcast }
                } preview: {
                    PodcastPreview(podcast: podcast)
                }
                .swipeActions(edge: .trailing) {
                    ConfirmedRemovalSwipeButton(title: "Unsubscribe", systemImage: "minus.circle") { podcastPendingUnsubscribe = podcast }
                }
                .brandListRow()
            }
        }
        .listStyle(.plain)
        .overlay {
            ListStateOverlay(isEmpty: podcasts.isEmpty, loadState: loadState, retry: { Task { await load() } }) {
                ContentUnavailableView {
                    Label("No podcasts", systemImage: "mic")
                } description: {
                    Text("Subscribe to a podcast and it’ll show up here.")
                } actions: {
                    Button("Add a Podcast") { isAddingPodcast = true }
                        .buttonStyle(.glass)
                }
            }
        }
        .navigationTitle("Podcasts")
        .brandMeshBackground()
        .toolbar {
            SortToolbarItem(options: SortOptions.podcasts, sort: sort, rememberKey: Self.sortKey) { sort = $0 }
            ToolbarItem(placement: .primaryAction) {
                Button("Add Podcast", systemImage: "plus") { isAddingPodcast = true }
            }
        }
        .refreshable { await load() }
        .task {
            for await value in app.core.podcasts.podcasts { podcasts = value }
        }
        .task {
            for await value in app.core.overview.recentlyAddedEpisodes { newEpisodes = value }
        }
        .task { await load() }
        .sheet(isPresented: $isAddingPodcast) { AddPodcastSheet() }
        .podcastUnsubscribeConfirmation($podcastPendingUnsubscribe) { podcast in
            PodcastActions(app: app).unsubscribe(podcast)
        }
    }

    private func load() async {
        async let episodes: Void? = try? app.core.overview.refresh()
        await loadState.load { try await app.core.podcasts.fetchAll() }
        _ = await episodes
    }
}

private struct PodcastRow: View {
    let podcast: Podcast

    var body: some View {
        MediaRow(title: podcast.title, subtitle: podcast.author, titleLineLimit: 2) {
            Artwork(url: podcast.imageUrl, size: 56, cornerRadius: 8)
        }
    }
}
