import SwiftUI

extension View {
    /// Asks before deleting or unsubscribing from `item`, which is set by a swipe, menu or button.
    func destructiveConfirmation<Item>(
        _ title: String,
        item: Binding<Item?>,
        actionLabel: String,
        message: @escaping (Item) -> String,
        action: @escaping (Item) -> Void
    ) -> some View {
        confirmationDialog(
            title,
            isPresented: Binding(get: { item.wrappedValue != nil }, set: { if !$0 { item.wrappedValue = nil } }),
            titleVisibility: .visible,
            presenting: item.wrappedValue
        ) { confirmed in
            Button(actionLabel, role: .destructive) { action(confirmed) }
        } message: { confirmed in
            Text(message(confirmed))
        }
    }
}
