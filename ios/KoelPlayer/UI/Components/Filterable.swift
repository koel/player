import SwiftUI

extension View {
    /// A filter field for a list, tucked away until the user pulls down, as in Apple Music.
    /// The list must have rows from its first layout (see `LoadingRows`) or the field flickers.
    func filterable(text: Binding<String>, prompt: String = "Filter") -> some View {
        searchable(text: text, placement: .navigationBarDrawer(displayMode: .automatic), prompt: Text(prompt))
    }
}
