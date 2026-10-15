@preconcurrency import Shared
import SwiftUI

/// The avatar in Home's toolbar: who is logged in, Remove All Downloads and Log Out.
struct ProfileMenu: View {
    let user: User?

    @Environment(AppModel.self) private var app
    @State private var isConfirmingLogOut = false
    @State private var isConfirmingRemoveAllDownloads = false

    var body: some View {
        Menu {
            Section {
                Button("Remove All Downloads", systemImage: "arrow.down.circle.dotted", role: .destructive) {
                    isConfirmingRemoveAllDownloads = true
                }
                .disabled(app.downloadedIds.value.isEmpty)

                Button("Log Out", systemImage: "rectangle.portrait.and.arrow.right", role: .destructive) {
                    isConfirmingLogOut = true
                }
            } header: {
                if let user {
                    Text("\(user.name)\n\(user.email)")
                }
            }
        } label: {
            avatar
        }
        .accessibilityLabel("Profile")
        .alert("Log out?", isPresented: $isConfirmingLogOut) {
            Button("Log Out", role: .destructive) {
                Task { await app.logOut() }
            }
            Button("Cancel", role: .cancel) {}
        }
        .removeAllDownloadsConfirmation(isPresented: $isConfirmingRemoveAllDownloads)
    }

    @ViewBuilder
    private var avatar: some View {
        if let avatarUrl = user?.avatar {
            Artwork(url: avatarUrl, size: 30, isCircle: true)
        } else {
            Image(systemName: "person.crop.circle")
        }
    }
}
