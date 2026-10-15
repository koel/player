import SwiftUI

/// An album's wiki or an artist's biography below their songs, collapsed to a few lines.
struct AboutSection: View {
    let title: String
    let html: String

    @State private var isExpanded = false

    var body: some View {
        if !html.isBlank {
            Section {
                VStack(alignment: .leading, spacing: 8) {
                    HTMLText(html: html)
                        .lineLimit(isExpanded ? nil : 4)
                    Button(isExpanded ? "Less" : "More") {
                        withAnimation { isExpanded.toggle() }
                    }
                    .font(.subheadline.weight(.semibold))
                    .buttonStyle(.borderless)
                }
                .padding(.vertical, 4)
            } header: {
                Text(title)
                    .font(.title3.bold())
                    .foregroundStyle(.primary)
            }
        }
    }
}
