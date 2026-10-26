import SwiftUI

/// The last row of a paginated list: loads the next page as it scrolls into view, or offers to retry one that failed.
struct NextPageRow: View {
    let hasMore: Bool
    let loadedCount: Int
    let loadState: LoadState
    let load: () async -> Void

    var body: some View {
        switch loadState.nextPage(hasMore: hasMore, loadedCount: loadedCount) {
        case .none:
            EmptyView()
        case .loadable:
            LoadMoreRow(loadedCount: loadedCount, load: load)
        case .failed:
            LoadFailedView { Task { await load() } }
                .listRowSeparator(.hidden)
        }
    }
}

private struct LoadMoreRow: View {
    /// Changes after each page, so the row loads again if it is still visible.
    let loadedCount: Int
    let load: () async -> Void

    @State private var isVisible = false

    private struct Trigger: Equatable {
        let loadedCount: Int
        let isVisible: Bool
    }

    var body: some View {
        ProgressView()
            .frame(maxWidth: .infinity)
            .listRowSeparator(.hidden)
            .onScrollVisibilityChange { isVisible = $0 }
            .task(id: Trigger(loadedCount: loadedCount, isVisible: isVisible)) {
                if isVisible { await load() }
            }
    }
}

enum LoadFailure {
    static let title = "Oops!"
    static let message = "The request cannot be completed. Please double-check if you are connected to the internet."
    static let retry = "Retry"
}

struct LoadFailedView: View {
    let retry: () -> Void

    var body: some View {
        ContentUnavailableView {
            Label(LoadFailure.title, systemImage: "wifi.exclamationmark")
        } description: {
            Text(LoadFailure.message)
        } actions: {
            Button(LoadFailure.retry, action: retry)
                .buttonStyle(.glass)
        }
    }
}

/// Loading, failure and empty states for a list that has nothing to show yet.
struct ListStateOverlay<Empty: View>: View {
    let isEmpty: Bool
    let isLoading: Bool
    let hasFailed: Bool
    /// Off for lists that show `LoadingRows` instead.
    var showsSpinner = true
    let retry: () -> Void
    @ViewBuilder var empty: () -> Empty

    var body: some View {
        if isEmpty {
            if hasFailed {
                LoadFailedView(retry: retry)
            } else if isLoading {
                if showsSpinner { ProgressView() }
            } else {
                empty()
            }
        }
    }
}

extension ListStateOverlay {
    init(
        isEmpty: Bool,
        loadState: LoadState,
        showsSpinner: Bool = true,
        retry: @escaping () -> Void,
        @ViewBuilder empty: @escaping () -> Empty
    ) {
        self.init(
            isEmpty: isEmpty,
            isLoading: loadState.isPending,
            hasFailed: loadState.hasFailed,
            showsSpinner: showsSpinner,
            retry: retry,
            empty: empty
        )
    }
}
