@preconcurrency import Shared
import SwiftUI

/// The current cover with the previous and next ones peeking at the edges. Swiping to a neighbor plays it.
struct QueueArtworkCarousel: View {
    let state: PlaybackState

    @Environment(AppModel.self) private var app
    @State private var scrolledId: String?

    private static let artworkSize: CGFloat = 320
    private static let neighborScale: CGFloat = 0.8
    private static let spacing: CGFloat = -12

    private var neighborhood: [any Playable] {
        let index = Int(state.currentIndex)
        guard index >= 0, index < state.queue.count else { return state.current.map { [$0] } ?? [] }
        return Array(state.queue[max(index - 1, 0)...min(index + 1, state.queue.count - 1)])
    }

    var body: some View {
        GeometryReader { proxy in
            ScrollView(.horizontal) {
                LazyHStack(spacing: Self.spacing) {
                    ForEach(neighborhood, id: \.id) { playable in
                        let isCurrent = playable.id == state.current?.id
                        Artwork(url: playable.artworkUrl, size: Self.artworkSize, cornerRadius: 14)
                            .shadow(color: .black.opacity(isCurrent ? 0.5 : 0.2), radius: 30, y: 16)
                            .scrollTransition(.interactive, axis: .horizontal) { content, phase in
                                content
                                    .scaleEffect(phase.isIdentity ? 1 : Self.neighborScale)
                                    .brightness(phase.isIdentity ? 0 : -0.4)
                            }
                            .scaleEffect(state.isPlaying ? 1 : 0.86)
                            .animation(.spring(duration: 0.45, bounce: 0.3), value: state.isPlaying)
                            .accessibilityHidden(!isCurrent)
                    }
                }
                .scrollTargetLayout()
            }
            .contentMargins(.horizontal, max((proxy.size.width - Self.artworkSize) / 2, 0), for: .scrollContent)
            .scrollTargetBehavior(.viewAligned(limitBehavior: .alwaysByOne))
            .scrollIndicators(.hidden)
            .scrollClipDisabled()
            .scrollPosition(id: $scrolledId, anchor: .center)
            .onScrollPhaseChange { _, phase in
                guard phase == .idle else { return }
                playScrolledNeighbor()
            }
        }
        .frame(height: Self.artworkSize)
        .onAppear { scrolledId = state.current?.id }
        .onChange(of: state.current?.id) { _, currentId in
            withAnimation { scrolledId = currentId }
        }
    }

    private func playScrolledNeighbor() {
        guard let scrolledId, scrolledId != state.current?.id,
              let neighbor = neighborhood.first(where: { $0.id == scrolledId })
        else { return }
        app.player.play(neighbor)
    }
}
