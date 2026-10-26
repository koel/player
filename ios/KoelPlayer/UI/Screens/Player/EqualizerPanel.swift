@preconcurrency import Shared
import SwiftUI

/// Koel web's equalizer: the preamp, a dB scale, then the ten bands with a curve drawn through their handles.
struct EqualizerPanel: View {
    static let cornerRadius: CGFloat = 6

    let preset: EqualizerPreset
    let onChange: (EqualizerPreset) -> Void

    var body: some View {
        HStack(alignment: .top, spacing: 4) {
            EqualizerBandSlider(label: "Preamp", accessibilityName: "Preamp", decibels: preampBinding)
            scale
            bands
        }
        .padding(16)
        .background(.black.opacity(0.2), in: .rect(cornerRadius: Self.cornerRadius))
    }

    private var scale: some View {
        VStack {
            Text("+20")
            Spacer(minLength: 0)
            Text("0")
            Spacer(minLength: 0)
            Text("-20")
        }
        .font(.caption2)
        .lineLimit(1)
        .fixedSize(horizontal: true, vertical: false)
        .opacity(0.5)
        .frame(minWidth: 20)
        .frame(height: EqualizerScale.trackHeight)
        .accessibilityHidden(true)
    }

    private var bands: some View {
        let gains = preset.gains.map(\.doubleValue)

        return ZStack(alignment: .top) {
            EqualizerBaseline()
            EqualizerCurveLine(gains: gains)
            HStack(spacing: 0) {
                ForEach(gains.indices, id: \.self) { band in
                    if band > 0 { Spacer(minLength: 0) }
                    EqualizerBandSlider(
                        label: Equalizer.shared.bandLabel(band: Int32(band)),
                        accessibilityName: Equalizer.shared.bandDescription(band: Int32(band)),
                        decibels: gainBinding(band)
                    )
                    .frame(width: EqualizerBandSlider.width)
                }
            }
        }
    }

    private var preampBinding: Binding<Double> {
        Binding {
            preset.preamp
        } set: { decibels in
            onChange(preset.withPreamp(decibels: decibels))
        }
    }

    private func gainBinding(_ band: Int) -> Binding<Double> {
        Binding {
            preset.gains[band].doubleValue
        } set: { decibels in
            onChange(preset.withGain(band: Int32(band), decibels: decibels))
        }
    }

    /// The centers of the band handles, with the bands spread edge to edge across `width`.
    nonisolated static func handleCenters(gains: [Double], width: CGFloat) -> [CurvePoint] {
        let gap = gains.count > 1 ? (width - EqualizerBandSlider.width) / CGFloat(gains.count - 1) : 0

        return gains.enumerated().map { band, gain in
            CurvePoint(x: Double(EqualizerBandSlider.width / 2 + CGFloat(band) * gap), y: Double(EqualizerScale.y(of: gain)))
        }
    }
}

/// The 0 dB line behind the bands, fading out at both ends.
private struct EqualizerBaseline: View {
    var body: some View {
        Rectangle()
            .fill(
                LinearGradient(
                    stops: [
                        .init(color: .clear, location: 0),
                        .init(color: .primary.opacity(0.1), location: 0.05),
                        .init(color: .primary.opacity(0.1), location: 0.95),
                        .init(color: .clear, location: 1),
                    ],
                    startPoint: .leading,
                    endPoint: .trailing
                )
            )
            .frame(height: 1)
            .offset(y: EqualizerScale.y(of: 0))
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
            .allowsHitTesting(false)
    }
}

/// The smooth line through the band handles, highlight at the top fading to green at the bottom.
private struct EqualizerCurveLine: View {
    let gains: [Double]

    @Environment(\.brandColor) private var brandColor

    private static let overhang = CGFloat(EqualizerCurve.companion.OVERHANG)

    var body: some View {
        EqualizerCurveShape(gains: AnimatableGains(gains))
            .stroke(
                LinearGradient(colors: [brandColor.opacity(0.8), Color.success.opacity(0.8)], startPoint: .top, endPoint: .bottom),
                style: StrokeStyle(lineWidth: 2, lineCap: .round)
            )
            .mask { fadeAtBothEnds }
            .frame(height: EqualizerScale.trackHeight)
            .allowsHitTesting(false)
    }

    private var fadeAtBothEnds: some View {
        HStack(spacing: 0) {
            LinearGradient(colors: [.clear, .black], startPoint: .leading, endPoint: .trailing)
                .frame(width: Self.overhang)
            Color.black
            LinearGradient(colors: [.black, .clear], startPoint: .leading, endPoint: .trailing)
                .frame(width: Self.overhang)
        }
        .padding(.horizontal, EqualizerBandSlider.width / 2 - Self.overhang)
        .padding(.vertical, -EqualizerScale.trackHeight / 2)
    }
}

private nonisolated struct EqualizerCurveShape: Shape {
    var gains: AnimatableGains

    var animatableData: AnimatableGains {
        get { gains }
        set { gains = newValue }
    }

    func path(in rect: CGRect) -> Path {
        var path = Path()
        let handles = EqualizerPanel.handleCenters(gains: gains.values, width: rect.width)
        guard let curve = EqualizerCurve.companion.through(handles: handles) else { return path }

        path.move(to: CGPoint(curve.start))
        for segment in curve.segments {
            path.addCurve(to: CGPoint(segment.end), control1: CGPoint(segment.control1), control2: CGPoint(segment.control2))
        }
        return path
    }
}

private nonisolated extension CGPoint {
    init(_ point: CurvePoint) {
        self.init(x: point.x, y: point.y)
    }
}

/// The band gains as one animatable value, so the curve glides along with the handles when a preset is picked.
nonisolated struct AnimatableGains: VectorArithmetic {
    var values: [Double]

    init(_ values: [Double]) {
        self.values = values
    }

    static var zero: Self { Self([]) }

    static func + (lhs: Self, rhs: Self) -> Self { combine(lhs, rhs, with: +) }

    static func - (lhs: Self, rhs: Self) -> Self { combine(lhs, rhs, with: -) }

    mutating func scale(by rate: Double) {
        values = values.map { $0 * rate }
    }

    var magnitudeSquared: Double {
        values.reduce(0) { sum, value in sum + value * value }
    }

    private static func combine(_ lhs: Self, _ rhs: Self, with operation: (Double, Double) -> Double) -> Self {
        let count = max(lhs.values.count, rhs.values.count)
        return Self((0..<count).map { i in
            operation(lhs.values.indices.contains(i) ? lhs.values[i] : 0, rhs.values.indices.contains(i) ? rhs.values[i] : 0)
        })
    }
}
