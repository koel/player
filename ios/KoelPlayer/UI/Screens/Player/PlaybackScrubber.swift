import SwiftUI

/// A knobless progress control like Apple Music's: a thin bar, or the song's waveform when there is one.
/// A tap jumps to the touched spot; dragging moves the position by the distance moved.
struct PlaybackScrubber: View {
    let position: Double
    let length: Double
    var waveform: [Double] = []
    var isPlaying = false
    let onScrub: (Double) -> Void
    let onCommit: (Double) -> Void

    @State private var dragStartPosition: Double?
    @State private var waveformGrowth: Double = 0
    @State private var positionUpdatedAt = Date.now

    private static let tapTolerance: CGFloat = 4

    private var isDragging: Bool { dragStartPosition != nil }
    private var isAdvancing: Bool { isPlaying && !isDragging }

    /// The position only arrives a couple of times a second, so it is carried forward between updates to keep the progress moving smoothly.
    private func fraction(at date: Date) -> Double {
        guard length > 0 else { return 0 }
        let elapsed = isAdvancing ? max(date.timeIntervalSince(positionUpdatedAt), 0) : 0
        return min(max((position + elapsed) / length, 0), 1)
    }
    private var barHeight: CGFloat { isDragging ? 12 : 7 }

    var body: some View {
        GeometryReader { proxy in
            TimelineView(.animation(paused: !isAdvancing)) { timeline in
                let fraction = fraction(at: timeline.date)
                if waveform.isEmpty {
                    bar(width: proxy.size.width, fraction: fraction)
                } else {
                    WaveformBars(levels: waveform, fraction: fraction, isHighlighted: isDragging, growth: waveformGrowth)
                }
            }
            .frame(maxHeight: .infinity)
            .contentShape(.rect)
            .highPriorityGesture(drag(width: proxy.size.width))
        }
        .onChange(of: position) { positionUpdatedAt = .now }
        .onChange(of: isAdvancing) { positionUpdatedAt = .now }
        .onChange(of: waveform, initial: true) { growWaveform() }
        .frame(height: 44)
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

    private func bar(width: CGFloat, fraction: Double) -> some View {
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

    private func growWaveform() {
        waveformGrowth = 0
        guard !waveform.isEmpty else { return }
        withAnimation(.easeOut(duration: 0.9)) { waveformGrowth = 1 }
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
                if abs(gesture.translation.width) < Self.tapTolerance, width > 0 {
                    onCommit(min(max(Double(gesture.location.x / width), 0), 1) * length)
                } else {
                    onCommit(target(from: start, translation: gesture.translation.width, width: width))
                }
            }
    }

    private func target(from start: Double, translation: CGFloat, width: CGFloat) -> Double {
        guard width > 0 else { return start }
        return min(max(start + Double(translation / width) * length, 0), length)
    }
}

/// Rounded vertical bars mirrored around the middle, bright up to the played fraction.
struct WaveformBars: View, Animatable {
    let levels: [Double]
    let fraction: Double
    let isHighlighted: Bool
    /// From 0 to 1 as the bars rise from flat, left to right, when a waveform arrives.
    var growth: Double

    @Environment(\.brandColor) private var brandColor

    var animatableData: Double {
        get { growth }
        set { growth = newValue }
    }

    private static let barWidth: CGFloat = 1.5
    private static let gap: CGFloat = 2
    private static let minimumBarHeight: CGFloat = 1.5
    private static let playheadWidth: CGFloat = 1
    /// How far from the playhead bars still swell, in points.
    static let glowRadius: CGFloat = 22
    private static let glowGrowth: CGFloat = 0.6
    /// How much of the rise is spent waiting for the bars to the left to start first.
    private static let riseStagger: Double = 0.5

    var body: some View {
        Canvas { context, size in
            let count = max(Int((size.width + Self.gap) / (Self.barWidth + Self.gap)), 1)
            let heights = Self.normalized(Self.resampled(levels, to: count))
            let step = count > 1 ? (size.width - Self.barWidth) / CGFloat(count - 1) : 0
            let playedX = size.width * fraction

            let restingHeight = size.height / (1 + Self.glowGrowth)

            var played = context
            played.clip(to: Path(CGRect(x: 0, y: 0, width: playedX, height: size.height)))

            for (index, height) in heights.enumerated() {
                let x = CGFloat(index) * step
                let glow = Self.glow(atDistance: x + Self.barWidth / 2 - playedX)
                let rise = Self.rise(of: index, among: heights.count, growth: growth)
                let barHeight = max(restingHeight * height * rise * (1 + Self.glowGrowth * glow), Self.minimumBarHeight)
                let rect = CGRect(x: x, y: (size.height - barHeight) / 2, width: Self.barWidth, height: barHeight)
                let bar = Path(roundedRect: rect, cornerRadius: Self.barWidth / 2)

                var unplayedBar = context
                unplayedBar.opacity = 0.3 + 0.5 * glow
                unplayedBar.fill(bar, with: .color(.white))

                var playedBar = played
                playedBar.opacity = isHighlighted ? 1 : 0.85 + 0.15 * glow
                playedBar.fill(bar, with: .color(.white))
            }

            let playhead = CGRect(x: playedX - Self.playheadWidth / 2, y: 0, width: Self.playheadWidth, height: size.height)
            context.fill(Path(playhead), with: .color(brandColor))
        }
    }

    static func rise(of index: Int, among count: Int, growth: Double) -> CGFloat {
        let delay = riseStagger * Double(index) / Double(max(count - 1, 1))
        return CGFloat(min(max((growth - delay) / (1 - riseStagger), 0), 1))
    }

    /// 1 right at the playhead, easing to 0 at [glowRadius] behind it; bars ahead of it stay plain.
    static func glow(atDistance distance: CGFloat) -> CGFloat {
        guard distance <= 0 else { return 0 }
        let normalized = min(-distance / glowRadius, 1)
        return 0.5 + 0.5 * cos(normalized * .pi)
    }

    /// Each bar takes the loudest slice it covers, so short peaks stay visible.
    static func resampled(_ levels: [Double], to count: Int) -> [Double] {
        guard !levels.isEmpty else { return Array(repeating: 0, count: count) }
        return (0..<count).map { bar in
            let start = bar * levels.count / count
            let end = max((bar + 1) * levels.count / count, start + 1)
            return levels[start..<min(end, levels.count)].max() ?? 0
        }
    }

    /// Stretches the range between the quiet floor and the loudest bar, since mastered songs sit
    /// in a narrow band and would otherwise draw as a flat block.
    static func normalized(_ levels: [Double]) -> [Double] {
        let sorted = levels.sorted()
        guard let peak = sorted.last, peak > 0 else { return levels }
        let floor = sorted[sorted.count / 10] * 0.8
        let range = max(peak - floor, .ulpOfOne)
        return levels.map { pow(min(max(($0 - floor) / range, 0), 1), 1.6) }
    }
}
