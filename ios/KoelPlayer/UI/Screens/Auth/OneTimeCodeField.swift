import SwiftUI

/// Flutter's segmented code input: one box per digit, filled from a single hidden field so the
/// keyboard's code suggestion and pasting fill every box at once.
struct OneTimeCodeField: View {
    @Binding var code: String
    let length: Int
    let onComplete: () -> Void

    @FocusState private var isFocused: Bool

    private static let boxShape = RoundedRectangle(cornerRadius: 8, style: .continuous)
    private static let boxFill = Color.white.opacity(0.1)
    private static let boxBorder = Color.white.opacity(0.24)

    var body: some View {
        ZStack {
            TextField("", text: $code)
                .keyboardType(.numberPad)
                .textContentType(.oneTimeCode)
                .foregroundStyle(.clear)
                .tint(.clear)
                .frame(height: 54)
                .focused($isFocused)
                .accessibilityLabel("Authentication code")
                .onChange(of: code) { _, newCode in
                    let digits = String(newCode.filter(\.isNumber).prefix(length))
                    if digits != newCode {
                        code = digits
                    } else if digits.count == length {
                        onComplete()
                    }
                }

            HStack(spacing: 8) {
                ForEach(0..<length, id: \.self) { index in
                    box(at: index)
                }
            }
            .allowsHitTesting(false)
            .accessibilityHidden(true)
        }
        .onAppear { isFocused = true }
    }

    private func box(at index: Int) -> some View {
        let digits = Array(code)
        let isCurrent = isFocused && index == min(digits.count, length - 1)

        return Text(index < digits.count ? String(digits[index]) : "")
            .font(.system(size: 20, weight: .semibold, design: .monospaced))
            .frame(width: 44, height: 54)
            .background(Self.boxFill, in: Self.boxShape)
            .overlay {
                Self.boxShape.strokeBorder(isCurrent ? Color.highlight : Self.boxBorder, lineWidth: isCurrent ? 2 : 1)
            }
    }
}
