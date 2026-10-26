@preconcurrency import Shared

enum CollectionSummary {
    /// "2019 · 12 songs · 48 min", skipping whatever is unknown.
    static func detail(year: Int32? = nil, songs: [any Playable]) -> String? {
        detail(label: year.map { "\($0)" }, songs: songs)
    }

    /// "Smart playlist · 12 songs · 48 min".
    static func detail(label: String?, songs: [any Playable]) -> String? {
        detail(label: label, songCount: songs.count, totalLength: songs.reduce(0) { $0 + $1.length })
    }

    static func detail(label: String?, songCount: Int, totalLength: Double) -> String? {
        guard songCount > 0 else { return label }
        return [label, songCount.pluralized("song"), totalLength.totalLength]
            .compactMap { $0 }
            .joined(separator: " · ")
    }
}
