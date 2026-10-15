import SwiftUI

/// Koel's purple-and-pink brand backdrop, slowly drifting. Colors are sampled from the Flutter
/// app's background artwork.
struct BrandMeshBackground: View {
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    private static let colors: [Color] = [
        Color(red: 0.10, green: 0.00, blue: 0.22), Color(red: 0.11, green: 0.00, blue: 0.27), Color(red: 0.13, green: 0.00, blue: 0.32),
        .highlight, Color(red: 0.31, green: 0.22, blue: 0.53), Color(red: 0.14, green: 0.06, blue: 0.27),
        Color(red: 0.20, green: 0.13, blue: 0.36), Color(red: 0.32, green: 0.23, blue: 0.55), Color(red: 0.31, green: 0.22, blue: 0.53),
    ]

    var body: some View {
        TimelineView(.animation(paused: reduceMotion)) { context in
            MeshGradient(
                width: 3,
                height: 3,
                points: Self.points(at: reduceMotion ? 0 : context.date.timeIntervalSinceReferenceDate),
                colors: Self.colors
            )
        }
        .ignoresSafeArea()
    }

    /// Corners stay pinned; edge midpoints slide along their edge and the center wanders,
    /// each on its own slow period so the pattern never visibly repeats.
    private static func points(at time: TimeInterval) -> [SIMD2<Float>] {
        func drift(_ period: Double, _ amplitude: Double, phase: Double = 0) -> Float {
            Float(sin(time * 2 * .pi / period + phase) * amplitude)
        }

        return [
            [0, 0], [0.5 + drift(11, 0.3), 0], [1, 0],
            [0, 0.5 + drift(13, 0.3, phase: 1)], [0.5 + drift(10, 0.28, phase: 2), 0.5 + drift(14, 0.28)], [1, 0.5 + drift(12, 0.3, phase: 3)],
            [0, 1], [0.5 + drift(16, 0.3, phase: 4), 1], [1, 1],
        ]
    }
}
