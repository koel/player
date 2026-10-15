import SwiftUI

extension View {
    /// Lets a `CollectionHeader` sit inside a `List` without a row background or separator.
    func asListHeaderRow() -> some View {
        listRowInsets(EdgeInsets(top: 0, leading: 0, bottom: 16, trailing: 0))
            .listRowBackground(Color.clear)
            .listRowSeparator(.hidden)
    }
}
