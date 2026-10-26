@preconcurrency import Shared
import SwiftUI

struct TwoFactorView: View {
    let challenge: TwoFactorChallenge

    @Environment(AppModel.self) private var app
    @Environment(\.dismiss) private var dismiss

    @State private var usesRecoveryCode = false
    @State private var code = ""
    @State private var isVerifying = false
    @State private var errorMessage: String?
    @FocusState private var isRecoveryCodeFocused: Bool

    private static let authenticatorCodeLength = 6

    var body: some View {
        ScrollView {
            VStack(spacing: 16) {
                Text("Two-Factor Authentication")
                    .font(.title2.bold())
                    .multilineTextAlignment(.center)

                Text(usesRecoveryCode ? "Enter one of your recovery codes." : "Enter the code from your authenticator app.")
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)

                if usesRecoveryCode {
                    TextField("Recovery code", text: $code)
                        .textInputAutocapitalization(.characters)
                        .autocorrectionDisabled()
                        .monospaced()
                        .tracking(2)
                        .multilineTextAlignment(.center)
                        .submitLabel(.go)
                        .onSubmit(verify)
                        .onChange(of: code) { _, newCode in
                            let uppercased = newCode.uppercased()
                            if uppercased != newCode { code = uppercased }
                        }
                        .focused($isRecoveryCodeFocused)
                        .onAppear { isRecoveryCodeFocused = true }
                        .padding(.horizontal, 20)
                        .padding(.vertical, 16)
                        .authFieldBackground()
                } else {
                    OneTimeCodeField(code: $code, length: Self.authenticatorCodeLength, onComplete: verify)
                }

                Button(action: verify) {
                    Group {
                        if isVerifying { ProgressView() } else { Text("Verify").fontWeight(.semibold) }
                    }
                    .frame(maxWidth: .infinity)
                }
                .buttonStyle(.glassProminent)
                .tint(.highlight)
                .controlSize(.extraLarge)
                .disabled(isVerifying)

                Button(usesRecoveryCode ? "Use authenticator code instead" : "Use a recovery code") {
                    usesRecoveryCode.toggle()
                    code = ""
                }
                .disabled(isVerifying)

                Button("Back to login") { dismiss() }
                    .disabled(isVerifying)
            }
            .tint(.white)
            .padding(.horizontal, 24)
            .frame(maxWidth: 480)
            .frame(maxWidth: .infinity)
        }
        .defaultScrollAnchor(.center)
        .scrollDismissesKeyboard(.interactively)
        .background { BrandMeshBackground() }
        .toolbar(.hidden, for: .navigationBar)
        .alert("Error", isPresented: $errorMessage.isPresent) {
            Button("OK", role: .cancel) {}
        } message: {
            Text(errorMessage ?? "")
        }
    }

    private func verify() {
        guard !code.isBlank, !isVerifying else { return }

        Task {
            isVerifying = true
            defer { isVerifying = false }

            do {
                try await app.core.auth.completeTwoFactorChallenge(challenge: challenge, code: code.trimmed)
                _ = try await app.core.auth.fetchCurrentUser()
                app.didLogIn()
            } catch {
                code = ""
                errorMessage = error.httpStatus == 401
                    ? "Invalid authentication code."
                    : "There was a problem verifying the code. Please try again."
            }
        }
    }
}
