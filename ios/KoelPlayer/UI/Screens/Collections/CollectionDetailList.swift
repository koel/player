@preconcurrency import Shared
import SwiftUI

/// The screen of an album, genre, playlist or podcast: its header, then its songs, with placeholder
/// rows while they load. The empty, failed and no-results states sit below the header, or in the
/// middle of the screen while there is no header yet.
struct CollectionDetailList<Header: View, Empty: View, Footer: View>: View {
    let title: String
    let artworkUrl: String?
    let header: Header?
    let songs: [any Playable]
    let displayedSongs: [any Playable]
    @Binding var query: String
    let loadState: LoadState
    var style = PlayableRow.Style.standard
    var isSortedByTitle = false
    var removal: ((any Playable) -> PlayableRow.Removal)?
    let retry: () -> Void
    let refresh: () async -> Void
    @ViewBuilder let empty: () -> Empty
    @ViewBuilder let footer: () -> Footer

    var body: some View {
        List {
            if let header {
                header.asListHeaderRow()
            }

            if songs.isEmpty || header == nil, loadState.isPending {
                LoadingRows()
                    .brandListRow()
            }

            if header != nil {
                PlayableListContent(playables: displayedSongs, style: style, isSortedByTitle: isSortedByTitle, removal: removal)
                    .brandListRow()

                footer()

                placeholder.asListPlaceholderRow()
            }
        }
        .listStyle(.plain)
        .overlay {
            if header == nil { placeholder }
        }
        .collectionScreen(title: title, artworkUrl: artworkUrl)
        .filterable(text: $query, matchesNothing: false, isShown: !songs.isEmpty || loadState.isPending)
        .refreshable { await refresh() }
    }

    @ViewBuilder
    private var placeholder: some View {
        if songs.isEmpty {
            ListStateOverlay(isEmpty: true, loadState: loadState, showsSpinner: false, retry: retry, empty: empty)
        } else if displayedSongs.isEmpty {
            ContentUnavailableView.search(text: query)
        }
    }
}

extension CollectionDetailList where Footer == EmptyView {
    init(
        title: String,
        artworkUrl: String?,
        header: Header?,
        songs: [any Playable],
        displayedSongs: [any Playable],
        query: Binding<String>,
        loadState: LoadState,
        style: PlayableRow.Style = .standard,
        isSortedByTitle: Bool = false,
        removal: ((any Playable) -> PlayableRow.Removal)? = nil,
        retry: @escaping () -> Void,
        refresh: @escaping () async -> Void,
        @ViewBuilder empty: @escaping () -> Empty
    ) {
        self.init(
            title: title,
            artworkUrl: artworkUrl,
            header: header,
            songs: songs,
            displayedSongs: displayedSongs,
            query: query,
            loadState: loadState,
            style: style,
            isSortedByTitle: isSortedByTitle,
            removal: removal,
            retry: retry,
            refresh: refresh,
            empty: empty,
            footer: { EmptyView() }
        )
    }
}
