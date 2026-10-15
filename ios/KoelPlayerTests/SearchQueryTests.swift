@testable import KoelPlayer
import Testing

struct SearchQueryTests {
    @Test func clearsResultsWhenTheFieldIsEmpty() {
        #expect(SearchQuery("") == .clear)
        #expect(SearchQuery("   ") == .clear)
    }

    @Test func keepsResultsWhileTheQueryIsTooShort() {
        #expect(SearchQuery("a") == .keepResults)
    }

    @Test func searchesTrimmedKeywords() {
        #expect(SearchQuery(" ab ") == .search("ab"))
    }
}
