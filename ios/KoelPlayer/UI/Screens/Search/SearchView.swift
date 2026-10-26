@preconcurrency import Shared
import SwiftUI

struct SearchView: View {
    private static let skeletonRowCount = 5

    @Environment(AppModel.self) private var app
    @State private var text = ""
    @State private var model = SearchModel()
    @FocusState private var isSearchFocused: Bool

    var body: some View {
        let sections = model.result.map { SearchSection.visible(in: $0, supports: app.core.session.supports(feature:)) } ?? []

        ScrollView {
            if model.isSearching {
                LoadingRowStack(count: Self.skeletonRowCount)
                    .padding(.vertical)
            } else if let result = model.result {
                SearchResults(result: result, keywords: model.searchedKeywords, sections: sections)
            }
        }
        .overlay {
            if model.result != nil, sections.isEmpty {
                ContentUnavailableView.search(text: model.searchedKeywords)
            }
        }
        .navigationTitle("Search")
        .brandMeshBackground()
        .searchable(text: $text, prompt: "Search your library")
        .searchFocused($isSearchFocused)
        .task(id: text) { await search(text) }
        .onChange(of: app.navigator.wantsSearchFocus, initial: true) { _, wantsFocus in
            guard wantsFocus else { return }
            isSearchFocused = true
            app.navigator.wantsSearchFocus = false
        }
    }

    private func search(_ text: String) async {
        do {
            try await model.search(text) { try await app.core.search.searchExcerpts(keywords: $0) }
        } catch {
            if !Task.isCancelled { app.toasts.showError() }
        }
    }
}

private struct SearchResults: View {
    let result: SearchResult
    let keywords: String
    let sections: [SearchSection]

    @Environment(AppModel.self) private var app
    @State private var livePlayables: [any Playable]?

    var body: some View {
        LazyVStack(alignment: .leading, spacing: SectionHeader.sectionGap) {
            ForEach(sections, id: \.self) { section in
                switch section {
                case .songs:
                    PlayableSection(title: section.title, destination: .searchSongs(keywords: keywords), playables: livePlayables ?? result.playables)
                case .albums:
                    CardCarousel(title: section.title) {
                        ForEach(result.albums, id: \.id) { CarouselAlbumCard(album: $0) }
                    }
                case .artists:
                    CardCarousel(title: section.title) {
                        ForEach(result.artists, id: \.id) { CarouselArtistCard(artist: $0) }
                    }
                case .podcasts:
                    CardCarousel(title: section.title) {
                        ForEach(result.podcasts, id: \.id) { CarouselPodcastCard(podcast: $0) }
                    }
                case .radioStations:
                    CardCarousel(title: section.title) {
                        ForEach(result.radioStations, id: \.id) { CarouselRadioStationCard(station: $0) }
                    }
                }
            }
        }
        .padding(.vertical)
        .collect(app.core.playables.live(playables: result.playables), id: result.playables.map(\.id)) { livePlayables = $0 }
    }
}
