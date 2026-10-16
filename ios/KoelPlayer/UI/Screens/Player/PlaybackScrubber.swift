import SwiftUI

/// A knobless progress bar like Apple Music's: thin at rest, thicker while dragged, and dragging
/// moves the position by the distance moved rather than jumping to the touch.
struct PlaybackScrubber: View {
    let position: Double
    let length: Double
    let onScrub: (Double) -> Void
    let onCommit: (Double) -> Void

    @State private var dragStartPosition: Double?

    private var isDragging: Bool { dragStartPosition != nil }
    private var barHeight: CGFloat { isDragging ? 12 : 7 }
    private var fraction: Double { length > 0 ? min(max(position / length, 0), 1) : 0 }

    var body: some View {
        GeometryReader { proxy in
            ZStack(alignment: .leading) {
                Rectangle()
                    .fill(.white.opacity(0.2))
                Rectangle()
                    .fill(.white.opacity(isDragging ? 1 : 0.75))
                    .frame(width: proxy.size.width * fraction)
            }
            .frame(height: barHeight)
            .clipShape(.capsule)
            .frame(maxHeight: .infinity)
            .contentShape(.rect)
            .highPriorityGesture(drag(width: proxy.size.width))
        }
        .frame(height: 24)
        .animation(.spring(duration: 0.25), value: isDragging)
        .accessibilityElement()
        .accessibilityLabel("Position")
        .accessibilityValue(position.playbackTime)
        .accessibilityAdjustableAction { direction in
            let step = length / 20
            onCommit(min(max(position + (direction == .increment ? step : -step), 0), length))
        }
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
