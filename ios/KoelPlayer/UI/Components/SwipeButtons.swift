import SwiftUI

/// Queues a song or a whole collection at the end, the same purple button on every list.
struct PlayLastSwipeButton: View {
    let action: () -> Void

    var body: some View {
        Button("Play Last", systemImage: "text.line.last.and.arrowtriangle.forward", action: action)
            .tint(.purple)
    }
}

/// Queues a whole album at the end from a leading swipe, in the green of Flutter's swipe-to-queue.
struct QueueSwipeButton: View {
    let action: () -> Void

    var body: some View {
        Button("Queue", systemImage: "text.badge.plus", action: action)
            .tint(.green)
    }
}

/// Delete or Unsubscribe, which asks first. Tinted rather than given the destructive role,
/// which would slide the row away before the user confirms.
struct ConfirmedRemovalSwipeButton: View {
    let title: String
    let systemImage: String
    let action: () -> Void

    var body: some View {
        Button(title, systemImage: systemImage, action: action)
            .tint(.red)
    }
}

/// Takes a row out of its list straight away. Tinted red as well, since the app's tint would otherwise turn it white.
struct RemovalSwipeButton: View {
    var title = "Remove"
    var systemImage = "minus.circle"
    let action: () -> Void

    var body: some View {
        Button(title, systemImage: systemImage, role: .destructive, action: action)
            .tint(.red)
    }
}
