import SwiftUI

extension View {
    /// The frosted, rounded box behind each field on the login and two-factor screens.
    func authFieldBackground() -> some View {
        glassEffect(.regular, in: .rect(cornerRadius: 16, style: .continuous))
    }
}
