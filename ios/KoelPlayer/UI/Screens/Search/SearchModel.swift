@preconcurrency import Shared
import SwiftUI

@MainActor @Observable
final class SearchModel {
    static let debounce = Duration.milliseconds(300)

    private(set) var result: SearchResult?
    private(set) var searchedKeywords = ""
    private(set) var isSearching = false

    func search(
        _ text: String,
        debounce: Duration = SearchModel.debounce,
        find: (String) async throws -> SearchResult
    ) async throws {
        switch SearchQuery(text) {
        case .clear:
            result = nil
            isSearching = false
        case .keepResults:
            isSearching = false
        case .search(let keywords):
            result = nil
            isSearching = true
            do {
                try await Task.sleep(for: debounce)
                let found = try await find(keywords)
                try Task.checkCancellation()
                result = found
                searchedKeywords = keywords
                isSearching = false
            } catch {
                if !Task.isCancelled { isSearching = false }
                throw error
            }
        }
    }
}
