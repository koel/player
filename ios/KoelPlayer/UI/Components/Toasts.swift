import Observation
import SwiftUI

/// Brief confirmations such as "Queued" or "Added to Playlist", like Apple Music's HUD.
@Observable
final class Toasts {
    struct Toast: Equatable, Identifiable {
        let id = UUID()
        let title: String
        let systemImage: String
    }

    private(set) var current: Toast?
    @ObservationIgnored private var dismissal: Task<Void, Never>?

    func show(_ title: String, systemImage: String = "checkmark") {
        current = Toast(title: title, systemImage: systemImage)
        dismissal?.cancel()
        dismissal = Task {
            try? await Task.sleep(for: .seconds(1.6))
            guard !Task.isCancelled else { return }
            current = nil
        }
    }

    func showError(_ title: String = "Something went wrong") {
        show(title, systemImage: "exclamationmark.triangle")
    }
}

struct ToastOverlay: ViewModifier {
    let toasts: Toasts

    func body(content: Content) -> some View {
        content.overlay(alignment: .top) {
            if let toast = toasts.current {
                Label(toast.title, systemImage: toast.systemImage)
                    .font(.subheadline.weight(.semibold))
                    .padding(.horizontal, 20)
                    .padding(.vertical, 12)
                    .glassEffect(.regular, in: .capsule)
                    .transition(.move(edge: .top).combined(with: .opacity))
                    .id(toast.id)
                    .accessibilityAddTraits(.updatesFrequently)
            }
        }
        .animation(.spring(duration: 0.35), value: toasts.current)
        .sensoryFeedback(.success, trigger: toasts.current) { _, new in new != nil }
    }
}
