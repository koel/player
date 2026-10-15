import SwiftUI
import UIKit

/// Lyrics, biographies and episode descriptions arrive as HTML snippets.
struct HTMLText: View {
    let html: String

    @State private var text: AttributedString?

    var body: some View {
        Group {
            if let text {
                Text(text)
            } else {
                Text(html.strippingTags)
            }
        }
        .textSelection(.enabled)
        .lineSpacing(4)
        .task(id: html) { text = Self.attributed(html) }
    }

    private static func attributed(_ html: String) -> AttributedString? {
        guard let data = "<div style=\"font: -apple-system-body\">\(html)</div>".data(using: .utf8),
              let rendered = try? NSAttributedString(
                  data: data,
                  options: [.documentType: NSAttributedString.DocumentType.html, .characterEncoding: String.Encoding.utf8.rawValue],
                  documentAttributes: nil
              )
        else { return nil }

        var text = AttributedString(rendered)
        text.foregroundColor = nil
        text.font = nil
        return text
    }
}

extension String {
    var strippingTags: String {
        replacing(/<[^>]+>/, with: "").replacingOccurrences(of: "&amp;", with: "&")
    }
}
