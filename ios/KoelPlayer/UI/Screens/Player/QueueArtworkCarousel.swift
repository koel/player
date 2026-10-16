@preconcurrency import Shared
import SwiftUI

/// The current cover in front, with the previous and next ones smaller, tilted and dimmed behind it.
/// Swiping to a neighbor plays it.
struct QueueArtworkCarousel: View {
    let state: PlaybackState

    @Environment(AppModel.self) private var app
    @State private var dragOffset: CGFloat = 0
    @State private var isSettlingSwipe = false

    private static let artworkSize: CGFloat = 280
    /// How far the covers next to the current one sit, and how far a swipe travels to reach one.
    private static let step: CGFloat = 160
    /// The outer covers tuck in closer behind the inner ones.
    private static let outerStep: CGFloat = 90
    private static let sideScale: CGFloat = 0.85
    private static let outerScale: CGFloat = 0.75
    private static let reach = 2
    private static let sideAngle: Double = 24
    private static let swipeThreshold: CGFloat = 50

    private var currentIndex: Int { Int(state.currentIndex) }

    private var visibleCovers: [(index: Int, playable: any Playable)] {
        guard currentIndex >= 0, currentIndex < state.queue.count else {
            return state.current.map { [(0, $0)] } ?? []
        }
        let range = max(currentIndex - Self.reach - 1, 0)...min(currentIndex + Self.reach + 1, state.queue.count - 1)
        return range.map { ($0, state.queue[$0]) }
    }

    var body: some View {
        ZStack {
            ForEach(visibleCovers, id: \.playable.id) { entry in
                let position = Double(entry.index - max(currentIndex, 0)) + dragOffset / Self.step
                cover(for: entry.playable, at: position)
            }
        }
        .frame(maxWidth: .infinity)
        .frame(height: Self.artworkSize)
        .contentShape(.rect)
        .gesture(swipe)
        .scaleEffect(state.isPlaying ? 1 : 0.88)
        .animation(.spring(duration: 0.45, bounce: 0.3), value: state.isPlaying)
        .onChange(of: currentIndex) { oldIndex, newIndex in
            guard !isSettlingSwipe, oldIndex >= 0, newIndex >= 0 else { return }
            dragOffset = CGFloat(max(min(newIndex - oldIndex, 1), -1)) * Self.step
            withAnimation(.spring(duration: 0.4)) { dragOffset = 0 }
        }
    }

    /// [position] is the cover's distance from the center in steps: 0 in front, ±1 and ±2 for the neighbors.
    private func cover(for playable: any Playable, at position: Double) -> some View {
        let distance = abs(position)
        let inner = min(distance, 1)
        let outer = min(max(distance - 1, 0), 1)
        let side: Double = position < 0 ? -1 : 1
        let scale = 1 - inner * (1 - Self.sideScale) - outer * (Self.sideScale - Self.outerScale)

        return Artwork(url: playable.artworkUrl, size: Self.artworkSize, cornerRadius: 16)
            .shadow(color: .black.opacity(0.4), radius: 24, y: 12)
            .scaleEffect(scale)
            .rotation3DEffect(.degrees(-side * inner * Self.sideAngle), axis: (x: 0, y: 1, z: 0), perspective: 0.5)
            .brightness(-(inner * 0.3 + outer * 0.2))
            .offset(x: side * (inner * Self.step + outer * Self.outerStep))
            .opacity(min(max(Double(Self.reach + 1) - distance, 0), 1))
            .zIndex(-distance)
            .accessibilityHidden(position != 0)
    }

    private var swipe: some Gesture {
        DragGesture(minimumDistance: 10)
            .onChanged { gesture in
                dragOffset = gesture.translation.width
            }
            .onEnded { gesture in
                let direction = swipeDirection(for: gesture.predictedEndTranslation.width)
                guard direction != 0, let target = state.queue[safe: currentIndex - direction] else {
                    withAnimation(.spring(duration: 0.35)) { dragOffset = 0 }
                    return
                }
                isSettlingSwipe = true
                withAnimation(.spring(duration: 0.35)) {
                    dragOffset = CGFloat(direction) * Self.step
                } completion: {
                    app.player.play(target)
                    dragOffset = 0
                    isSettlingSwipe = false
                }
            }
    }

    /// 1 when swiping right towards the previous cover, -1 when swiping left towards the next, 0 otherwise.
    private func swipeDirection(for translation: CGFloat) -> Int {
        if translation > Self.swipeThreshold { return 1 }
        if translation < -Self.swipeThreshold { return -1 }
        return 0
    }
}

private extension Array {
    subscript(safe index: Int) -> Element? {
        indices.contains(index) ? self[index] : nil
    }
}
