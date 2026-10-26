import SwiftUI

extension View {
    /// Lets a `CollectionHeader` sit inside a `List` without a row background or separator.
    func asListHeaderRow() -> some View {
        listRowInsets(EdgeInsets(top: 0, leading: 0, bottom: 16, trailing: 0))
            .brandListRow()
            .listRowSeparator(.hidden)
    }
}

extension View {
    /// An empty or failed state shown below a `CollectionHeader` instead of on top of it.
    func asListPlaceholderRow() -> some View {
        frame(maxWidth: .infinity)
            .brandListRow()
            .listRowSeparator(.hidden)
    }
}
