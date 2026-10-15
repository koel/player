@preconcurrency import Shared
import SwiftUI

struct PodcastDetailView: View {
    let podcastId: String

    private static let sortOptions = [
        (field: PlayableSortField.shared.TITLE, label: "Title"),
        (field: PlayableSortField.shared.CREATED_AT, label: "Recently Added"),
    ]

    @Environment(AppModel.self) private var app
    @Environment(\.dismiss) private var dismiss
    @State private var podcast: Podcast?
    @State private var episodes: [any Playable] = []
    @State private var isLoading = true
    @State private var loadFailed = false
    @State private var searchText = ""
    @State private var podcastPendingUnsubscribe: Podcast?
    @AppStorage("episodeSortField") private var sortField = PlayableSortField.shared.CREATED_AT
    @AppStorage("episodeSortDescending") private var isSortDescending = true

    private var sortOrder: Shared.SortOrder { isSortDescending ? .desc : .asc }

    private var displayedEpisodes: [any Playable] {
        SortingKt.filtered(SortingKt.sorted(episodes, field: sortField, order: sortOrder), keywords: searchText)
    }

    var body: some View {
        let displayedEpisodes = displayedEpisodes

        List {
            if episodes.isEmpty, isLoading {
                LoadingRows()
            }
            if let podcast {
                CollectionHeader(
                    artworkUrl: podcast.imageUrl,
                    title: podcast.title,
                    subtitle: podcast.author,
                    detail: episodes.isEmpty ? nil : episodes.count.pluralized("episode"),
                    playables: displayedEpisodes
                ) {
                    PodcastDescription(text: podcast.description_.strippingTags)
                }
                .asListHeaderRow()
            }
            ForEach(displayedEpisodes, id: \.id) { episode in
                PlayableRow(playable: episode, style: .podcast)
            }
        }
        .listStyle(.plain)
        .overlay { placeholder }
        .filterable(text: $searchText, prompt: "Filter")
        .navigationTitle(podcast?.title ?? "")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar { toolbarContent }
        .refreshable {
            _ = try? await app.core.podcasts.resolve(id: podcastId, forceRefresh: true)
            if let podcast { await PodcastActions(app: app).checkForNewEpisodes(podcast) }
        }
        .collect(app.core.podcasts.observe(id: podcastId)) { podcast = $0 ?? podcast }
        .collect(app.core.playables.podcastEpisodes(podcastId: podcastId)) { episodes = $0 }
        .task { await load() }
        .podcastUnsubscribeConfirmation($podcastPendingUnsubscribe) { podcast in
            PodcastActions(app: app).unsubscribe(podcast)
            dismiss()
        }
    }

    @ViewBuilder
    private var placeholder: some View {
        if episodes.isEmpty {
            if isLoading {
                EmptyView()
            } else if loadFailed {
                ContentUnavailableView {
                    Label("Couldn't Load Podcast", systemImage: "exclamationmark.triangle")
                } actions: {
                    Button("Try Again") { Task { await load() } }
                        .buttonStyle(.glass)
                }
            } else {
                ContentUnavailableView("No Episodes", systemImage: "mic")
            }
        } else if !searchText.isEmpty, displayedEpisodes.isEmpty {
            ContentUnavailableView.search(text: searchText)
        }
    }

    @ToolbarContentBuilder
    private var toolbarContent: some ToolbarContent {
        ToolbarItem(placement: .primaryAction) {
            SortMenu(options: Self.sortOptions, field: sortField, order: sortOrder) { field, order in
                sortField = field
                isSortDescending = order == .desc
            }
        }
        if let podcast {
            ToolbarItem(placement: .primaryAction) {
                Menu {
                    PodcastMenu(podcast: podcast, includesPlayback: false) {
                        podcastPendingUnsubscribe = podcast
                    }
                } label: {
                    Label("More", systemImage: "ellipsis")
                }
            }
        }
    }

    private func load() async {
        isLoading = true
        defer { isLoading = false }
        do {
            podcast = try await app.core.podcasts.resolve(id: podcastId)
            _ = try await app.core.playables.fetchForPodcast(podcastId: podcastId)
            loadFailed = false
        } catch {
            loadFailed = true
        }
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
