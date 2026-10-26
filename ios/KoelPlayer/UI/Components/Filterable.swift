import SwiftUI

extension View {
    /// A filter field for a list, tucked away until the user pulls down, as in Apple Music.
    /// The list must have rows from its first layout (see `LoadingRows`) or the field flickers,
    /// so keep `isShown` on while the list loads and turn it off only once it's loaded empty.
    /// `matchesNothing` shows the No Results state over the list.
    @ViewBuilder
    func filterable(text: Binding<String>, matchesNothing: Bool, isShown: Bool, prompt: String = "Filter") -> some View {
        if isShown {
            searchable(text: text, placement: .navigationBarDrawer(displayMode: .automatic), prompt: Text(prompt))
                .overlay {
                    if matchesNothing {
                        ContentUnavailableView.search(text: text.wrappedValue)
                    }
                }
        } else {
            self
        }
    }
}
