import SwiftUI

/// Sits where the launch screen draws the logo, so the handoff from it doesn't jump.
struct LaunchLogo: View {
    var body: some View {
        Image("logo")
            .accessibilityLabel("Koel")
            .accessibilityIdentifier("launch-logo")
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .ignoresSafeArea()
    }
}
