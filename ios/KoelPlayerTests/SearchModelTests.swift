@testable import KoelPlayer
@preconcurrency import Shared
import Testing

@MainActor
struct SearchModelTests {
    private struct SearchFailed: Error {}

    @Test func showsSkeletonsWhileSearching() async throws {
        let model = SearchModel()
        var wasSearchingDuringFetch = false

        try await model.search("love", debounce: .zero) { _ in
            wasSearchingDuringFetch = model.isSearching && model.result == nil
            return SearchResult()
        }

        #expect(wasSearchingDuringFetch)
        #expect(!model.isSearching)
        #expect(model.result != nil)
        #expect(model.searchedKeywords == "love")
    }

    @Test func aNewSearchReplacesTheOldResultsWithSkeletons() async throws {
        let model = SearchModel()
        try await model.search("love", debounce: .zero) { _ in SearchResult() }
        var hadOldResultsDuringFetch = true

        try await model.search("hate", debounce: .zero) { _ in
            hadOldResultsDuringFetch = model.result != nil
            return SearchResult()
        }

        #expect(!hadOldResultsDuringFetch)
        #expect(model.searchedKeywords == "hate")
    }

    @Test func aFailedSearchStopsTheSkeletons() async {
        let model = SearchModel()

        await #expect(throws: SearchFailed.self) {
            try await model.search("love", debounce: .zero) { _ in throw SearchFailed() }
        }

        #expect(!model.isSearching)
    }

    @Test func clearingTheFieldStopsTheSkeletons() async throws {
        let model = SearchModel()
        try await model.search("love", debounce: .zero) { _ in SearchResult() }

        try await model.search("", find: { _ in SearchResult() })

        #expect(!model.isSearching)
        #expect(model.result == nil)
    }
}
