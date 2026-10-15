import Shared
import SwiftUI

struct TwoFactorView: View {
    let challenge: TwoFactorChallenge

    @Environment(AppModel.self) private var app
    @Environment(\.dismiss) private var dismiss

    @State private var usesRecoveryCode = false
    @State private var code = ""
    @State private var isVerifying = false
    @State private var errorMessage: String?
    @FocusState private var isCodeFocused: Bool

    private static let authenticatorCodeLength = 6

    var body: some View {
        Form {
            Section {
                if usesRecoveryCode {
                    TextField("Recovery code", text: $code)
                        .textInputAutocapitalization(.characters)
                        .autocorrectionDisabled()
                        .monospaced()
                        .onSubmit(verify)
                } else {
                    TextField("Authentication code", text: $code)
                        .keyboardType(.numberPad)
                        .textContentType(.oneTimeCode)
                        .monospacedDigit()
                        .onChange(of: code) { _, newCode in
                            let digits = String(newCode.filter(\.isNumber).prefix(Self.authenticatorCodeLength))
                            if digits != newCode { code = digits }
                            if digits.count == Self.authenticatorCodeLength { verify() }
                        }
                }
            } footer: {
                Text(usesRecoveryCode ? "Enter one of your recovery codes." : "Enter the code from your authenticator app.")
            }
            .focused($isCodeFocused)

            Section {
                Button(action: verify) {
                    Group {
                        if isVerifying { ProgressView() } else { Text("Verify") }
                    }
                    .frame(maxWidth: .infinity)
                }
                .buttonStyle(.glassProminent)
                .controlSize(.large)
                .disabled(code.isBlank || isVerifying)
                .listRowBackground(Color.clear)
                .listRowInsets(EdgeInsets())

                Button(usesRecoveryCode ? "Use Authenticator Code Instead" : "Use a Recovery Code") {
                    usesRecoveryCode.toggle()
                    code = ""
                    isCodeFocused = true
                }
                .frame(maxWidth: .infinity)
                .disabled(isVerifying)
                .listRowBackground(Color.clear)
            }
        }
        .navigationTitle("Two-Factor Authentication")
        .navigationBarTitleDisplayMode(.inline)
        .onAppear { isCodeFocused = true }
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
