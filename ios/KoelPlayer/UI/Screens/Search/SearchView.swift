@preconcurrency import Shared
import SwiftUI

struct SearchView: View {
    private static let debounce = Duration.milliseconds(300)

    @Environment(AppModel.self) private var app
    @State private var text = ""
    @State private var result: SearchResult?
    @State private var searchedKeywords = ""
    @FocusState private var isSearchFocused: Bool

    var body: some View {
        let sections = result.map { SearchSection.visible(in: $0, supports: app.core.session.supports(feature:)) } ?? []

        ScrollView {
            if let result {
                SearchResults(result: result, keywords: searchedKeywords, sections: sections)
            }
        }
        .overlay {
            if result != nil, sections.isEmpty {
                ContentUnavailableView.search(text: searchedKeywords)
            }
        }
        .navigationTitle("Search")
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
        switch SearchQuery(text) {
        case .clear:
            result = nil
        case .keepResults:
            break
        case .search(let keywords):
            do {
                try await Task.sleep(for: Self.debounce)
                let found = try await app.core.search.searchExcerpts(keywords: keywords)
                guard !Task.isCancelled else { return }
                result = found
                searchedKeywords = keywords
            } catch {
                if !Task.isCancelled { app.toasts.showError() }
            }
        }
    }
}

private struct SearchResults: View {
    let result: SearchResult
    let keywords: String
    let sections: [SearchSection]

    var body: some View {
        LazyVStack(alignment: .leading, spacing: 32) {
            ForEach(sections, id: \.self) { section in
                switch section {
                case .songs:
                    SongResults(playables: result.playables, keywords: keywords)
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
    }
}

private struct SongResults: View {
    let playables: [any Playable]
    let keywords: String

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack(alignment: .firstTextBaseline) {
                Text(SearchSection.songs.title).font(.title3.bold())
                Spacer()
                NavigationLink("See All") {
                    SearchSongsView(keywords: keywords)
                }
            }
            .padding(.horizontal)
            .padding(.bottom, 4)

            ForEach(playables, id: \.id) { playable in
                PlayableRow(playable: playable)
                    .padding(.horizontal)
                    .padding(.vertical, 6)
            }
        }
    }
}
