import SwiftUI

/// The title above a section of songs or cards, the same everywhere. With a destination, the title
/// and its chevron open the full list; with an action, a button sits at the trailing edge.
struct SectionHeader: View {
    /// From the heading to the top of the content below it, whether cards, rows or text.
    static let contentGap: CGFloat = 16
    /// Between one section's content and the next section's heading.
    static let sectionGap: CGFloat = 32

    struct Action {
        let title: String
        var role: ButtonRole?
        let perform: () -> Void
    }

    let title: String
    var destination: Route?
    var action: Action?

    var body: some View {
        HStack {
            titleView
                .frame(maxWidth: .infinity, alignment: .leading)

            if let action {
                Button(action.title, role: action.role, action: action.perform)
                    .font(.body)
                    .buttonStyle(.borderless)
                    .tint(action.role == .destructive ? .red : nil)
            }
        }
        .padding(.horizontal)
    }

    private var titleView: some View {
        Group {
            if let destination {
                NavigationLink(value: destination) { showAllLabel }
                    .buttonStyle(.plain)
                    .accessibilityHint("Shows all")
            } else {
                Text(title)
            }
        }
        .font(.title3.bold())
        .foregroundStyle(.primary)
        .textCase(nil)
    }

    private var showAllLabel: some View {
        HStack(spacing: 4) {
            Text(title)
            Image(systemName: "chevron.forward")
                .foregroundStyle(.secondary)
                .imageScale(.small)
        }
    }
}
