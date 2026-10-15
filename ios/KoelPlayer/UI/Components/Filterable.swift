import SwiftUI

extension View {
    /// A filter field for a list. Pinned open: with the automatic display mode, iOS shows the
    /// field while the list is still loading and then hides it once rows arrive, which flickers.
    func filterable(text: Binding<String>, prompt: String = "Filter") -> some View {
        searchable(text: text, placement: .navigationBarDrawer(displayMode: .always), prompt: Text(prompt))
    }
}
