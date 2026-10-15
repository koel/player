import SwiftUI

/// The last row of a paginated list: loads the next page whenever it scrolls into view.
struct LoadMoreRow: View {
    /// Changes after each page, so the row loads again if it is still visible.
    let loadedCount: Int
    let load: () async -> Void

    var body: some View {
        ProgressView()
            .frame(maxWidth: .infinity)
            .listRowSeparator(.hidden)
            .task(id: loadedCount) { await load() }
    }
}

struct LoadFailedView: View {
    let retry: () -> Void

    var body: some View {
        ContentUnavailableView {
            Label("Couldn’t Load", systemImage: "wifi.exclamationmark")
        } description: {
            Text("Check your connection and try again.")
        } actions: {
            Button("Try Again", action: retry)
                .buttonStyle(.glass)
        }
    }
}

/// Loading, failure and empty states for a list that has nothing to show yet.
struct ListStateOverlay<Empty: View>: View {
    let isEmpty: Bool
    let isLoading: Bool
    let hasFailed: Bool
    let retry: () -> Void
    /// Off for lists that show `LoadingRows` instead.
    var showsSpinner = true
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
