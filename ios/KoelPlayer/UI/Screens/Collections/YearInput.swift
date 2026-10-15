/// The album year field: digits only, at most four of them, empty meaning no year.
enum YearInput {
    static func sanitized(_ text: String) -> String {
        String(text.filter(\.isASCIIDigit).prefix(4))
    }

    static func value(_ text: String) -> Int? {
        Int(sanitized(text))
    }
}

private extension Character {
    var isASCIIDigit: Bool { isASCII && isNumber }
}
