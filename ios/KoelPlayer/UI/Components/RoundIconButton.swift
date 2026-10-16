import SwiftUI

/// A neutral glass circle holding one symbol, for the secondary actions around a Play button.
struct RoundIconButton: View {
    let title: String
    let systemImage: String
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Image(systemName: systemImage)
                .contentTransition(.symbolEffect(.replace))
                .frame(width: 24, height: 24)
        }
        .accessibilityLabel(title)
        .buttonStyle(.glass)
        .buttonBorderShape(.circle)
        .tint(.primary)
    }
}
