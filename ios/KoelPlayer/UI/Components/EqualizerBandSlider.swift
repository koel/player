@preconcurrency import Shared
import SwiftUI

/// Where a gain sits on an equalizer band: +20 dB at the top of the track, -20 dB at the bottom.
nonisolated enum EqualizerScale {
    static let trackHeight: CGFloat = 100
    static let range = -Equalizer.shared.MAX_DECIBELS...Equalizer.shared.MAX_DECIBELS
    private static let stepsPerDecibel = 10.0

    static func y(of decibels: Double) -> CGFloat {
        CGFloat((range.upperBound - decibels) / span) * trackHeight
    }

    static func decibels(atY y: CGFloat) -> Double {
        let raw = range.upperBound - Double(y / trackHeight) * span
        let stepped = (raw * stepsPerDecibel).rounded() / stepsPerDecibel
        return min(max(stepped, range.lowerBound), range.upperBound)
    }

    private static var span: Double { range.upperBound - range.lowerBound }
}

/// One vertical equalizer band like Koel web's: a faint line, a small white handle and a label below.
struct EqualizerBandSlider: View {
    let label: String
    let accessibilityName: String
    @Binding var decibels: Double

    nonisolated static let width: CGFloat = 24
    private static let handleSize: CGFloat = 13
    private static let hitSize: CGFloat = 28

    private static let trackFade = LinearGradient(
        stops: [
            .init(color: .clear, location: 0),
            .init(color: .primary.opacity(0.15), location: 0.15),
            .init(color: .primary.opacity(0.15), location: 0.85),
            .init(color: .clear, location: 1),
        ],
        startPoint: .top,
        endPoint: .bottom
    )

    var body: some View {
        VStack(spacing: 8) {
            ZStack(alignment: .top) {
                Rectangle()
                    .fill(Self.trackFade)
                    .frame(width: 1)
                Circle()
                    .fill(.white)
                    .frame(width: Self.handleSize, height: Self.handleSize)
                    .offset(y: EqualizerScale.y(of: decibels) - Self.handleSize / 2)
            }
            .frame(width: Self.width, height: EqualizerScale.trackHeight)
            .contentShape(Rectangle().inset(by: -(Self.hitSize - Self.handleSize) / 2))
            .gesture(
                DragGesture(minimumDistance: 0).onChanged { drag in
                    decibels = EqualizerScale.decibels(atY: drag.location.y)
                }
            )
            .accessibilityRepresentation {
                Slider(value: $decibels, in: EqualizerScale.range, step: 1)
                    .accessibilityLabel(accessibilityName)
                    .accessibilityValue("\(decibels.signedDecibels) dB")
            }

            Text(label)
                .font(.caption2)
                .fixedSize()
                .accessibilityHidden(true)
        }
        .frame(minWidth: Self.width)
    }
}

extension Double {
    var signedDecibels: String {
        formatted(.number.sign(strategy: .always(includingZero: false)).precision(.fractionLength(0...1)))
    }
}
