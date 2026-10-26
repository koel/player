import SwiftUI

/// One line of text that, when too long to fit, pauses and then scrolls sideways in a loop.
struct MarqueeText: View {
    let text: String

    @State private var textWidth: CGFloat = 0
    @State private var availableWidth: CGFloat = 0
    @State private var startedAt = Date.now

    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    static let gap: CGFloat = 48
    static let pointsPerSecond: CGFloat = 30
    static let pause: TimeInterval = 2.5
    private static let edgeFade: CGFloat = 12

    private var overflows: Bool { textWidth > availableWidth + 1 && !reduceMotion }

    var body: some View {
        Text(text)
            .lineLimit(1)
            .hidden()
            .frame(maxWidth: .infinity, alignment: .leading)
            .onGeometryChange(for: CGFloat.self, of: \.size.width) { availableWidth = $0 }
            .overlay(alignment: .leading) {
                if overflows {
                    scrollingText
                } else {
                    Text(text).lineLimit(1)
                }
            }
            .background(alignment: .leading) {
                Text(text)
                    .fixedSize()
                    .hidden()
                    .onGeometryChange(for: CGFloat.self, of: \.size.width) { textWidth = $0 }
            }
            .onChange(of: text) { startedAt = .now }
            .accessibilityElement()
            .accessibilityLabel(text)
    }

    private var scrollingText: some View {
        TimelineView(.animation) { timeline in
            let offset = offset(at: timeline.date)
            HStack(spacing: Self.gap) {
                Text(text)
                Text(text)
            }
            .fixedSize()
            .offset(x: offset)
            .frame(width: availableWidth, alignment: .leading)
            .mask(fadedEdges(fadesLeading: offset < 0))
        }
    }

    private func fadedEdges(fadesLeading: Bool) -> some View {
        HStack(spacing: 0) {
            LinearGradient(colors: [fadesLeading ? .clear : .black, .black], startPoint: .leading, endPoint: .trailing)
                .frame(width: Self.edgeFade)
            Color.black
            LinearGradient(colors: [.black, .clear], startPoint: .leading, endPoint: .trailing)
                .frame(width: Self.edgeFade)
        }
    }

    private func offset(at date: Date) -> CGFloat {
        Self.offset(elapsed: date.timeIntervalSince(startedAt), textWidth: textWidth)
    }

    static func offset(elapsed: TimeInterval, textWidth: CGFloat) -> CGFloat {
        let distance = textWidth + gap
        let cycle = pause + distance / pointsPerSecond
        let elapsedInCycle = elapsed.truncatingRemainder(dividingBy: cycle)
        guard elapsedInCycle > pause else { return 0 }
        return -CGFloat(elapsedInCycle - pause) * pointsPerSecond
    }
}
