import SwiftUI

/// Koel's slider, like the Android app's: a thin track filled up to a small white thumb. Tapping or dragging along
/// the track sets the value.
struct KoelSlider: View {
    @Binding var value: Double
    let range: ClosedRange<Double>
    var step: Double = 1

    static let thumbSize: CGFloat = 16
    private static let trackThickness: CGFloat = 3

    var body: some View {
        GeometryReader { geometry in
            let length = geometry.size.width

            ZStack(alignment: .leading) {
                bar(upTo: range.upperBound, length: length)
                    .foregroundStyle(.white.opacity(0.3))
                bar(upTo: value, length: length)
                    .foregroundStyle(.secondary)
                Circle()
                    .fill(.white)
                    .frame(width: Self.thumbSize, height: Self.thumbSize)
                    .offset(x: thumbCenter(length: length) - Self.thumbSize / 2)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .leading)
            .contentShape(.rect)
            .gesture(
                DragGesture(minimumDistance: 0).onChanged { drag in
                    value = snapped(range.lowerBound + (drag.location.x / length).clamped * span)
                }
            )
        }
        .frame(height: Self.thumbSize)
        .accessibilityRepresentation {
            Slider(value: $value, in: range, step: step)
        }
    }

    private var span: Double { range.upperBound - range.lowerBound }

    private func fraction(of sliderValue: Double) -> CGFloat {
        CGFloat((sliderValue - range.lowerBound) / span).clamped
    }

    private func thumbCenter(length: CGFloat) -> CGFloat {
        min(max(fraction(of: value) * length, Self.thumbSize / 2), length - Self.thumbSize / 2)
    }

    private func bar(upTo end: Double, length: CGFloat) -> some View {
        Capsule()
            .frame(width: fraction(of: end) * length, height: Self.trackThickness)
    }

    private func snapped(_ rawValue: Double) -> Double {
        let stepped = (rawValue / step).rounded() * step
        return min(max(stepped, range.lowerBound), range.upperBound)
    }
}

private extension CGFloat {
    var clamped: CGFloat { Swift.min(Swift.max(self, 0), 1) }
}
