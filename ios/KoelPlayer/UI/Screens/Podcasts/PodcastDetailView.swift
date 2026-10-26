@preconcurrency import Shared
import SwiftUI

struct PodcastDetailView: View {
    let podcastId: String

    @Environment(AppModel.self) private var app
    @Environment(\.dismiss) private var dismiss
    @State private var podcast: Podcast?
    @State private var episodes: [any Playable] = []
    @State private var loadState = LoadState()
    @State private var query = ""
    @State private var podcastPendingUnsubscribe: Podcast?
    @State private var sort = SortSetting.remembered(for: Self.sortKey, default: SortSetting(field: PlayableSortField.shared.CREATED_AT, order: .desc))

    private static let sortKey = "podcast.sort"

    private var displayedEpisodes: [any Playable] {
        SortingKt.filtered(SortingKt.sorted(episodes, field: sort.field, order: sort.order), keywords: query)
    }

    var body: some View {
        let displayedEpisodes = displayedEpisodes

        CollectionDetailList(
            title: podcast?.title ?? "",
            artworkUrl: podcast?.imageUrl,
            header: podcast.map { podcast in
                CollectionHeader(
                    artworkUrl: podcast.imageUrl,
                    title: podcast.title,
                    subtitle: podcast.author,
                    detail: episodes.isEmpty ? nil : episodes.count.pluralized("episode"),
                    playables: displayedEpisodes
                ) {
                    PodcastDescription(text: podcast.description_.strippingTags)
                }
            },
            songs: episodes,
            displayedSongs: displayedEpisodes,
            query: $query,
            loadState: loadState,
            style: .podcast,
            retry: { Task { await load() } },
            refresh: refresh
        ) {
            ContentUnavailableView("No episodes", systemImage: "mic")
        }
        .toolbar {
            SortToolbarItem(options: SortOptions.podcastEpisodes, sort: sort, rememberKey: Self.sortKey) { sort = $0 }
            if let podcast {
                MoreMenuToolbarItem {
                    PodcastMenu(podcast: podcast, includesPlayback: false) {
                        podcastPendingUnsubscribe = podcast
                    }
                }
            }
        }
        .collect(app.core.podcasts.observe(id: podcastId)) { podcast = $0 ?? podcast }
        .collect(app.core.playables.podcastEpisodes(podcastId: podcastId)) { episodes = $0 }
        .task { await load() }
        .podcastUnsubscribeConfirmation($podcastPendingUnsubscribe) { podcast in
            PodcastActions(app: app).unsubscribe(podcast)
            dismiss()
        }
    }

    private func load() async {
        await loadState.load {
            podcast = try await app.core.podcasts.resolve(id: podcastId)
            _ = try await app.core.playables.fetchForPodcast(podcastId: podcastId)
        }
    }

    private func refresh() async {
        _ = try? await app.core.podcasts.resolve(id: podcastId, forceRefresh: true)
        if let podcast { await PodcastActions(app: app).checkForNewEpisodes(podcast) }
    }
}

/// The podcast's blurb, three lines until tapped.
private struct PodcastDescription: View {
    let text: String

    @State private var isExpanded = false

    var body: some View {
        if !text.isEmpty {
            Text(text)
                .font(.footnote)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
                .lineLimit(isExpanded ? nil : 3)
                .padding(.horizontal)
                .contentShape(.rect)
                .onTapGesture { withAnimation { isExpanded.toggle() } }
                .accessibilityAddTraits(.isButton)
        }
    }
}
