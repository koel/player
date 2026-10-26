import SwiftUI

/// An album's wiki or an artist's biography below their songs, collapsed to a few lines.
struct AboutSection: View {
    let title: String
    let html: String

    @State private var isExpanded = false

    var body: some View {
        let text = html.plainText

        if !text.isBlank {
            VStack(alignment: .leading, spacing: SectionHeader.contentGap) {
                SectionHeader(title: title)
                VStack(alignment: .leading, spacing: 8) {
                    Text(text)
                        .lineLimit(isExpanded ? nil : 4)
                        .textSelection(.enabled)
                    Button(isExpanded ? "Less" : "More") {
                        withAnimation { isExpanded.toggle() }
                    }
                    .font(.subheadline.weight(.semibold))
                    .buttonStyle(.borderless)
                }
                .padding(.horizontal)
            }
            .padding(.bottom, 12)
            .frame(maxWidth: .infinity, alignment: .leading)
            .listRowInsets(EdgeInsets())
            .listRowSeparator(.hidden)
        }
    }
}
