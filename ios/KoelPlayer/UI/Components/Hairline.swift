import SwiftUI

extension Color {
    /// Koel's divider color, white at 10%, so it reads the same on every part of the brand mesh.
    static let hairline = Color.white.opacity(0.1)
}

/// A one-pixel divider in Koel's hairline color.
struct Hairline: View {
    @Environment(\.displayScale) private var displayScale

    var body: some View {
        Rectangle()
            .fill(Color.hairline)
            .frame(height: 1 / displayScale)
    }
}

extension View {
    /// A list row over the brand background: no fill of its own, and a hairline separator.
    func brandListRow() -> some View {
        listRowBackground(Color.clear)
            .listRowSeparatorTint(.hairline)
    }
}
