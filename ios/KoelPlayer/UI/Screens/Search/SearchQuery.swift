/// What typing into the search field should do, as Flutter's search screen decided it.
enum SearchQuery: Equatable {
    case clear
    case keepResults
    case search(String)

    static let minimumLength = 2

    init(_ text: String) {
        let keywords = text.trimmingCharacters(in: .whitespacesAndNewlines)

        if keywords.isEmpty {
            self = .clear
        } else if keywords.count < Self.minimumLength {
            self = .keepResults
        } else {
            self = .search(keywords)
        }
    }
}
