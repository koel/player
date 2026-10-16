import SwiftUI

/// A knobless progress control like Apple Music's: a thin bar, or the song's waveform when there is one.
/// Dragging moves the position by the distance moved rather than jumping to the touch.
struct PlaybackScrubber: View {
    let position: Double
    let length: Double
    var waveform: [Double] = []
    let onScrub: (Double) -> Void
    let onCommit: (Double) -> Void

    @State private var dragStartPosition: Double?

    private var isDragging: Bool { dragStartPosition != nil }
    private var fraction: Double { length > 0 ? min(max(position / length, 0), 1) : 0 }
    private var barHeight: CGFloat { isDragging ? 12 : 7 }

    var body: some View {
        GeometryReader { proxy in
            Group {
                if waveform.isEmpty {
                    bar(width: proxy.size.width)
                } else {
                    WaveformBars(levels: waveform, fraction: fraction, isHighlighted: isDragging)
                }
            }
            .frame(maxHeight: .infinity)
            .contentShape(.rect)
            .highPriorityGesture(drag(width: proxy.size.width))
        }
        .frame(height: waveform.isEmpty ? 24 : 44)
        .animation(.spring(duration: 0.25), value: isDragging)
        .animation(.easeInOut(duration: 0.3), value: waveform.isEmpty)
        .accessibilityElement()
        .accessibilityLabel("Position")
        .accessibilityValue(position.playbackTime)
        .accessibilityAdjustableAction { direction in
            let step = length / 20
            onCommit(min(max(position + (direction == .increment ? step : -step), 0), length))
        }
    }

    private func bar(width: CGFloat) -> some View {
        ZStack(alignment: .leading) {
            Rectangle()
                .fill(.white.opacity(0.2))
            Rectangle()
                .fill(.white.opacity(isDragging ? 1 : 0.75))
                .frame(width: width * fraction)
        }
        .frame(height: barHeight)
        .clipShape(.capsule)
    }

    private func drag(width: CGFloat) -> some Gesture {
        DragGesture(minimumDistance: 0)
            .onChanged { gesture in
                let start = dragStartPosition ?? position
                dragStartPosition = start
                onScrub(target(from: start, translation: gesture.translation.width, width: width))
            }
            .onEnded { gesture in
                let start = dragStartPosition ?? position
                dragStartPosition = nil
                onCommit(target(from: start, translation: gesture.translation.width, width: width))
            }
    }

    private func target(from start: Double, translation: CGFloat, width: CGFloat) -> Double {
        guard width > 0 else { return start }
        return min(max(start + Double(translation / width) * length, 0), length)
    }
}

/// Rounded vertical bars mirrored around the middle, bright up to the played fraction.
private struct WaveformBars: View {
    let levels: [Double]
    let fraction: Double
    let isHighlighted: Bool

    private static let barWidth: CGFloat = 1.5
    private static let gap: CGFloat = 2
    private static let minimumBarHeight: CGFloat = 1.5

    var body: some View {
        Canvas { context, size in
            let count = max(Int((size.width + Self.gap) / (Self.barWidth + Self.gap)), 1)
            let heights = Self.normalized(Self.resampled(levels, to: count))
            let step = count > 1 ? (size.width - Self.barWidth) / CGFloat(count - 1) : 0
            let playedX = size.width * fraction

            for (index, height) in heights.enumerated() {
                let barHeight = max(size.height * height, Self.minimumBarHeight)
                let rect = CGRect(x: CGFloat(index) * step, y: (size.height - barHeight) / 2, width: Self.barWidth, height: barHeight)
                let isPlayed = rect.midX <= playedX
                let opacity = isPlayed ? (isHighlighted ? 1 : 0.85) : 0.3
                context.fill(Path(roundedRect: rect, cornerRadius: Self.barWidth / 2), with: .color(.white.opacity(opacity)))
            }
        }
    }

    /// Each bar takes the loudest slice it covers, so short peaks stay visible.
    private static func resampled(_ levels: [Double], to count: Int) -> [Double] {
        guard !levels.isEmpty else { return Array(repeating: 0, count: count) }
        return (0..<count).map { bar in
            let start = bar * levels.count / count
            let end = max((bar + 1) * levels.count / count, start + 1)
            return levels[start..<min(end, levels.count)].max() ?? 0
        }
    }

    /// Stretches the range between the quiet floor and the loudest bar, since mastered songs sit
    /// in a narrow band and would otherwise draw as a flat block.
    private static func normalized(_ levels: [Double]) -> [Double] {
        let sorted = levels.sorted()
        guard let peak = sorted.last, peak > 0 else { return levels }
        let floor = sorted[sorted.count / 10] * 0.8
        let range = max(peak - floor, .ulpOfOne)
        return levels.map { pow(min(max(($0 - floor) / range, 0), 1), 1.6) }
    }
}
