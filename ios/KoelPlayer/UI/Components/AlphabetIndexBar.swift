import SwiftUI

/// A side letter index like the one Lists get from `sectionIndexLabel`, for grids that have none.
/// Tapping or sliding over a letter jumps to it.
struct AlphabetIndexBar: View {
    let letters: [String]
    let onSelect: (String) -> Void

    @State private var selectedLetter: String?

    private static let letterHeight: CGFloat = 15

    /// The letter under a finger `offset` points down the bar, holding at the ends when the finger slides past them.
    static func letterIndex(at offset: CGFloat, letterCount: Int) -> Int? {
        guard letterCount > 0 else { return nil }
        return min(max(Int(offset / letterHeight), 0), letterCount - 1)
    }

    var body: some View {
        VStack(spacing: 0) {
            ForEach(letters, id: \.self) { letter in
                Text(letter)
                    .font(.caption2.weight(.semibold))
                    .frame(width: 16, height: Self.letterHeight)
            }
        }
        .foregroundStyle(.tint)
        .padding(.vertical, 4)
        .contentShape(.rect)
        .gesture(
            DragGesture(minimumDistance: 0)
                .onChanged { gesture in select(at: gesture.location.y - 4) }
                .onEnded { _ in selectedLetter = nil }
        )
        .sensoryFeedback(.selection, trigger: selectedLetter) { _, newLetter in newLetter != nil }
        .accessibilityElement()
        .accessibilityLabel("Section Index")
        .accessibilityValue(selectedLetter ?? "")
        .accessibilityAdjustableAction { direction in
            let current = selectedLetter.flatMap(letters.firstIndex(of:)) ?? -1
            let next = min(max(current + (direction == .increment ? 1 : -1), 0), letters.count - 1)
            selectedLetter = letters[next]
            onSelect(letters[next])
        }
    }

    private func select(at offset: CGFloat) {
        guard let index = Self.letterIndex(at: offset, letterCount: letters.count), letters[index] != selectedLetter else { return }
        selectedLetter = letters[index]
        onSelect(letters[index])
    }
}
