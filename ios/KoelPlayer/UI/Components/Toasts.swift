import Observation
import SwiftUI

/// Brief confirmations such as "Queued" or "Added", as Flutter's message overlay showed them.
@Observable
final class Toasts {
    struct Toast: Equatable, Identifiable {
        let id = UUID()
        let caption: String
        let message: String?
        let systemImage: String
    }

    static let defaultDuration: Duration = .seconds(2)

    /// Flutter's 80 points above the bottom, which keeps clear of Now Playing's queue heading.
    static let bottomPadding: CGFloat = 80
    /// The gap above the tab bar and mini player, which the tabs' safe area already covers.
    static let bottomPaddingAboveBars: CGFloat = 16

    private(set) var current: Toast?
    @ObservationIgnored private let duration: Duration
    @ObservationIgnored private var dismissal: Task<Void, Never>?

    init(duration: Duration = defaultDuration) {
        self.duration = duration
    }

    func show(_ caption: String, message: String? = nil, systemImage: String = "checkmark.circle.fill") {
        current = Toast(caption: caption, message: message, systemImage: systemImage)
        dismissal?.cancel()
        dismissal = Task { [duration] in
            try? await Task.sleep(for: duration)
            guard !Task.isCancelled else { return }
            current = nil
        }
    }

    func showError(_ caption: String = "Error", message: String? = nil) {
        show(caption, message: message, systemImage: "exclamationmark.triangle")
    }

    func dismiss() {
        dismissal?.cancel()
        current = nil
    }
}

/// Now Playing covers the tabs, so it shows its own overlay while the tabs' one stays hidden.
struct ToastOverlay: ViewModifier {
    let toasts: Toasts
    var isShown = true
    var bottomPadding = Toasts.bottomPadding

    func body(content: Content) -> some View {
        content.overlay(alignment: .bottom) {
            if isShown, let toast = toasts.current {
                ToastCard(toast: toast)
                    .padding(.horizontal, 32)
                    .padding(.bottom, bottomPadding)
                    .onTapGesture { toasts.dismiss() }
                    .transition(.opacity.combined(with: .scale(scale: 0.95)))
                    .id(toast.id)
            }
        }
        .animation(.easeInOut(duration: 0.3), value: toasts.current)
        .sensoryFeedback(.impact(weight: .light), trigger: toasts.current) { _, new in isShown && new != nil }
    }
}

private struct ToastCard: View {
    let toast: Toasts.Toast

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: toast.systemImage)
                .font(.title2)
                .foregroundStyle(.tertiary)
            VStack(alignment: .leading, spacing: 2) {
                Text(toast.caption)
                    .font(.subheadline.weight(.semibold))
                if let message = toast.message {
                    Text(message)
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                }
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .glassEffect(.regular, in: .rect(cornerRadius: 16))
        .accessibilityElement(children: .combine)
        .accessibilityAddTraits(.updatesFrequently)
    }
}
