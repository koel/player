import Foundation

extension String {
    /// Podcast feeds and radio streams must be absolute http(s) URLs.
    var isWebURL: Bool {
        guard let url = URL(string: trimmingCharacters(in: .whitespacesAndNewlines)),
              let scheme = url.scheme?.lowercased(),
              let host = url.host(),
              !host.isEmpty
        else { return false }
        return scheme == "http" || scheme == "https"
    }
}
