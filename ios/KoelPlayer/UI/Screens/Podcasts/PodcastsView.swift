@preconcurrency import Shared
import SwiftUI

/// The podcast sort fields, stored by raw value so the choice survives relaunches.
enum PodcastSortOption: String, CaseIterable {
    case lastPlayedAt
    case subscribedAt
    case title
    case author

    var label: String {
        switch self {
        case .lastPlayedAt: "Last Played"
        case .subscribedAt: "Subscribed"
        case .title: "Title"
        case .author: "Author"
        }
    }

    var field: PodcastSortField {
        switch self {
        case .lastPlayedAt: .lastPlayedAt
        case .subscribedAt: .subscribedAt
        case .title: .title
        case .author: .author
        }
    }
}

struct PodcastsView: View {
    @Environment(AppModel.self) private var app
    @State private var podcasts: [Podcast] = []
    @State private var isLoading = true
    @State private var loadFailed = false
    @State private var isAddingPodcast = false
    @State private var podcastPendingUnsubscribe: Podcast?
    @AppStorage("podcastSortField") private var sortOption = PodcastSortOption.lastPlayedAt
    @AppStorage("podcastSortDescending") private var isSortDescending = true

    private var sortOrder: Shared.SortOrder { isSortDescending ? .desc : .asc }

    var body: some View {
        let sortedPodcasts = PodcastSortingKt.sorted(podcasts, field: sortOption.field, order: sortOrder)

        List(sortedPodcasts, id: \.id) { podcast in
            NavigationLink(value: Route.podcast(id: podcast.id)) {
                PodcastRow(podcast: podcast)
            }
            .contextMenu {
                PodcastMenu(podcast: podcast) { podcastPendingUnsubscribe = podcast }
            } preview: {
                PodcastPreview(podcast: podcast)
            }
            .swipeActions(edge: .trailing) {
                Button("Unsubscribe", systemImage: "minus.circle") { podcastPendingUnsubscribe = podcast }
                    .tint(.red)
            }
        }
        .overlay { placeholder }
        .navigationTitle("Podcasts")
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                SortMenu(
                    options: PodcastSortOption.allCases.map { (field: $0.rawValue, label: $0.label) },
                    field: sortOption.rawValue,
                    order: sortOrder
                ) { field, order in
                    sortOption = PodcastSortOption(rawValue: field) ?? .lastPlayedAt
                    isSortDescending = order == .desc
                }
            }
            ToolbarItem(placement: .primaryAction) {
                Button("Add Podcast", systemImage: "plus") { isAddingPodcast = true }
            }
        }
        .refreshable { await load() }
        .task {
            for await value in app.core.podcasts.podcasts { podcasts = value }
        }
        .task { await load() }
        .sheet(isPresented: $isAddingPodcast) { AddPodcastSheet() }
        .podcastUnsubscribeConfirmation($podcastPendingUnsubscribe) { podcast in
            PodcastActions(app: app).unsubscribe(podcast)
        }
    }

    @ViewBuilder
    private var placeholder: some View {
        if podcasts.isEmpty {
            if isLoading {
                ProgressView()
            } else if loadFailed {
                ContentUnavailableView {
                    Label("Couldn't Load Podcasts", systemImage: "exclamationmark.triangle")
                } actions: {
                    Button("Try Again") { Task { await load() } }
                        .buttonStyle(.glass)
                }
            } else {
                ContentUnavailableView {
                    Label("No Podcasts", systemImage: "mic")
                } description: {
                    Text("Subscribe to a podcast and it'll show up here.")
                } actions: {
                    Button("Add a Podcast") { isAddingPodcast = true }
                        .buttonStyle(.glassProminent)
                }
            }
        }
    }

    private func load() async {
        isLoading = true
        defer { isLoading = false }
        do {
            try await app.core.podcasts.fetchAll()
            loadFailed = false
        } catch {
            loadFailed = true
        }
    }
}

private struct PodcastRow: View {
    let podcast: Podcast

    var body: some View {
        HStack(spacing: 12) {
            Artwork(url: podcast.imageUrl, size: 56, cornerRadius: 8)
            VStack(alignment: .leading, spacing: 2) {
                Text(podcast.title)
                    .lineLimit(2)
                Text(podcast.author)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
            }
        }
    }
}

private struct PodcastPreview: View {
    let podcast: Podcast

    var body: some View {
        VStack(spacing: 12) {
            Artwork(url: podcast.imageUrl, size: 220, cornerRadius: 12)
            VStack(spacing: 4) {
                Text(podcast.title).font(.headline)
                Text(podcast.author)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                if !podcast.description_.isEmpty {
                    Text(podcast.description_.strippingTags)
                        .font(.footnote)
                        .foregroundStyle(.tertiary)
                        .lineLimit(3)
                }
            }
            .multilineTextAlignment(.center)
            .lineLimit(2)
        }
        .padding(20)
        .frame(width: 280)
    }
}
