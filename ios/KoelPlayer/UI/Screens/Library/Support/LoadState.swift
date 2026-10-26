import Observation

/// Whether a screen's fetch is running, has succeeded once, or failed, shared by every list that
/// loads from the server. Paged lists call `load` for each next page and `refresh` for the first.
@MainActor @Observable
final class LoadState {
    private(set) var isLoading = false
    private(set) var hasLoaded = false
    private(set) var hasFailed = false

    @ObservationIgnored private var refreshGeneration = 0
    @ObservationIgnored private var runningRefreshes = 0

    /// Nothing to show yet: before the first fetch starts, and while any fetch runs.
    var isPending: Bool {
        isLoading || (!hasLoaded && !hasFailed)
    }

    /// Skipped while another load or a refresh runs, so a list's last row can ask for the next page as often as it likes.
    func load(_ fetch: () async throws -> Void) async {
        await load(fetch, apply: { _ in })
    }

    /// A page fetched before a refresh started is dropped instead of applied, as it belongs to the old list.
    func load<Page>(_ fetch: () async throws -> Page, apply: (Page) -> Void) async {
        guard !isLoading, runningRefreshes == 0 else { return }
        isLoading = true
        hasFailed = false
        defer { isLoading = false }
        await perform(fetch, apply: apply, showsFailure: true, generation: refreshGeneration)
    }

    /// Runs even while a page loads, since a new sort must win. A failure keeps what's on screen.
    func refresh(hasItems: @autoclosure () -> Bool, _ fetch: () async throws -> Void) async {
        await refresh(hasItems: hasItems(), fetch, apply: { _ in })
    }

    /// Only the latest refresh applies its result, so the last sort picked wins.
    func refresh<Page>(hasItems: @autoclosure () -> Bool, _ fetch: () async throws -> Page, apply: (Page) -> Void) async {
        refreshGeneration += 1
        runningRefreshes += 1
        defer { runningRefreshes -= 1 }
        await perform(fetch, apply: apply, showsFailure: !hasItems(), generation: refreshGeneration)
    }

    enum NextPage { case none, loadable, failed }

    /// A failed page waits for a tap on Retry, so it isn't requested again and again as the row stays visible.
    func nextPage(hasMore: Bool, loadedCount: Int) -> NextPage {
        guard hasMore, loadedCount > 0 else { return .none }
        return hasFailed ? .failed : .loadable
    }

    private func perform<Page>(_ fetch: () async throws -> Page, apply: (Page) -> Void, showsFailure: Bool, generation: Int) async {
        do {
            let page = try await fetch()
            guard generation == refreshGeneration else { return }
            apply(page)
            hasLoaded = true
            hasFailed = false
        } catch where error.isCancellation {
        } catch {
            guard generation == refreshGeneration else { return }
            hasFailed = showsFailure
        }
    }
}
