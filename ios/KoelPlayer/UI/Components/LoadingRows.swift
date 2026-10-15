import SwiftUI

/// Placeholder song rows while a list loads. Lists must not start empty: with nothing to show,
/// iOS reveals the filter field and then hides it again once rows arrive.
struct LoadingRows: View {
    var count = 8

    var body: some View {
        ForEach(0..<count, id: \.self) { _ in
            HStack(spacing: 12) {
                RoundedRectangle(cornerRadius: 6, style: .continuous)
                    .fill(.fill.tertiary)
                    .frame(width: 44, height: 44)
                VStack(alignment: .leading, spacing: 4) {
                    Text(verbatim: "Placeholder song title")
                    Text(verbatim: "Placeholder artist").font(.subheadline)
                }
                .redacted(reason: .placeholder)
            }
            .listRowSeparator(.hidden)
        }
        .accessibilityHidden(true)
    }
}
