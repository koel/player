@preconcurrency import Shared
import SwiftUI
import VisionKit

struct LoginView: View {
    @Environment(AppModel.self) private var app

    @State private var host = ""
    @State private var email = ""
    @State private var password = ""
    @State private var isAuthenticating = false
    @State private var errorMessage: String?
    @State private var challenge: TwoFactorChallenge?
    @State private var isScanning = false
    @State private var isPasswordRevealed = false

    private enum Field {
        case host, email, password
    }

    @FocusState private var focusedField: Field?

    private var firstMissingField: Field? {
        if host.isBlank { return .host }
        if email.isBlank { return .email }
        if password.isEmpty { return .password }
        return nil
    }

    var body: some View {
        NavigationStack {
            GeometryReader { proxy in
                ScrollView {
                    VStack(spacing: 32) {
                        Image("logo")
                            .resizable()
                            .scaledToFit()
                            .frame(width: 120, height: 120)
                            .accessibilityLabel("Koel")

                        credentials

                        HStack(spacing: 12) {
                            Button(action: logIn) {
                                Group {
                                    if isAuthenticating {
                                        ProgressView()
                                    } else {
                                        Text("Log In").fontWeight(.semibold)
                                    }
                                }
                                .frame(maxWidth: .infinity)
                            }
                            .buttonStyle(.glassProminent)
                            .tint(.highlight)

                            Button(action: scanQRCode) {
                                Image(systemName: "qrcode.viewfinder")
                            }
                            .buttonStyle(.glass)
                            .buttonBorderShape(.circle)
                            .accessibilityLabel("Log In with QR Code")
                        }
                        .controlSize(.extraLarge)
                        .disabled(isAuthenticating)
                    }
                    .padding(.horizontal, 24)
                    .frame(maxWidth: 480)
                    .frame(maxWidth: .infinity, minHeight: proxy.size.height)
                }
                .scrollDismissesKeyboard(.interactively)
            }
            .background { BrandMeshBackground() }
            .navigationDestination(item: $challenge) { challenge in
                TwoFactorView(challenge: challenge)
            }
            .sheet(isPresented: $isScanning) {
                LoginQRScanner { payload in
                    isScanning = false
                    logIn(with: payload)
                }
            }
            .alert("Error", isPresented: $errorMessage.isPresent) {
                Button("OK", role: .cancel) {}
            } message: {
                Text(errorMessage ?? "")
            }
        }
        .onAppear {
            host = app.core.auth.host ?? ""
            email = app.core.auth.lastEmail ?? ""
        }
    }

    private var credentials: some View {
        VStack(spacing: 12) {
            CredentialField(label: "Host", isFloating: isFloating(.host, text: host)) {
                TextField("Host", text: $host, prompt: hint("https://www.koel.music", for: .host, text: host))
                    .keyboardType(.URL)
                    .textContentType(.URL)
                    .accessibilityLabel("Host")
                    .focused($focusedField, equals: .host)
                    .submitLabel(.next)
                    .onSubmit { focusedField = .email }
            }
            CredentialField(label: "Email", isFloating: isFloating(.email, text: email)) {
                TextField("Email", text: $email, prompt: hint("you@koel.music", for: .email, text: email))
                    .keyboardType(.emailAddress)
                    .textContentType(.username)
                    .accessibilityLabel("Email")
                    .focused($focusedField, equals: .email)
                    .submitLabel(.next)
                    .onSubmit { focusedField = .password }
            }
            CredentialField(label: "Password", isFloating: isFloating(.password, text: password)) {
                Group {
                    if isPasswordRevealed {
                        TextField("Password", text: $password, prompt: Text(""))
                    } else {
                        SecureField("Password", text: $password, prompt: Text(""))
                    }
                }
                .textContentType(.password)
                .accessibilityLabel("Password")
                .focused($focusedField, equals: .password)
                .submitLabel(.go)
                .onSubmit(logIn)
            } trailing: {
                Button(action: togglePasswordReveal) {
                    Image(systemName: isPasswordRevealed ? "eye.slash" : "eye")
                        .foregroundStyle(.secondary)
                        .contentTransition(.symbolEffect(.replace))
                }
                .buttonStyle(.plain)
                .accessibilityLabel(isPasswordRevealed ? "Hide Password" : "Show Password")
            }
        }
        .textInputAutocapitalization(.never)
        .autocorrectionDisabled()
    }

    private func isFloating(_ field: Field, text: String) -> Bool {
        !text.isEmpty || focusedField == field
    }

    /// The example only shows once the label has moved out of its way.
    private func hint(_ example: String, for field: Field, text: String) -> Text {
        Text(isFloating(field, text: text) ? example : "")
    }

    private func togglePasswordReveal() {
        let wasEditingPassword = focusedField == .password
        isPasswordRevealed.toggle()
        if wasEditingPassword {
            focusedField = .password
        }
    }

    private func scanQRCode() {
        if DataScannerViewController.isSupported {
            isScanning = true
        } else {
            errorMessage = "This device can't scan QR codes. Log in with your email and password instead."
        }
    }

    private func logIn() {
        guard !isAuthenticating else { return }
        if let missing = firstMissingField {
            focusedField = missing
            return
        }

        Task {
            isAuthenticating = true
            defer { isAuthenticating = false }

            do {
                if let challenge = try await app.core.auth.login(host: host.normalizedHost, email: email.trimmed, password: password) {
                    self.challenge = challenge
                    return
                }
                _ = try await app.core.auth.fetchCurrentUser()
                app.didLogIn()
            } catch {
                errorMessage = error.httpStatus == 401
                    ? "Invalid email or password."
                    : "There was a problem logging in. Please try again."
            }
        }
    }

    private func logIn(with payload: LoginQRPayload) {
        Task {
            isAuthenticating = true
            defer { isAuthenticating = false }

            do {
                try await app.core.auth.loginWithOneTimeToken(host: payload.host.normalizedHost, token: payload.token)
                _ = try await app.core.auth.fetchCurrentUser()
                app.didLogIn()
            } catch {
                errorMessage = error.httpStatus == 401
                    ? "Invalid login token."
                    : "There was a problem logging in. Please try again."
            }
        }
    }
}

extension TwoFactorChallenge: @retroactive Identifiable {
    public var id: String { loginToken }
}

extension String {
    var trimmed: String { trimmingCharacters(in: .whitespacesAndNewlines) }

    var isBlank: Bool { trimmed.isEmpty }

    /// Koel hosts are typed by hand; accept "koel.example.com/" as "https://koel.example.com".
    var normalizedHost: String {
        var host = trimmed
        while host.hasSuffix("/") { host.removeLast() }
        return host.hasPrefix("http://") || host.hasPrefix("https://") ? host : "https://\(host)"
    }
}

/// A login field with a label that sits inside it while it's empty and moves to the top once
/// it has focus or text, like the Flutter app's.
private struct CredentialField<Field: View, Trailing: View>: View {
    let label: String
    let isFloating: Bool
    @ViewBuilder let field: () -> Field
    @ViewBuilder let trailing: () -> Trailing

    private static var floatingOffset: CGFloat { 10 }

    var body: some View {
        HStack {
            ZStack(alignment: .leading) {
                Text(label)
                    .font(isFloating ? .caption : .body)
                    .foregroundStyle(isFloating ? .secondary : .tertiary)
                    .offset(y: isFloating ? -Self.floatingOffset - 2 : 0)
                    .allowsHitTesting(false)
                    .accessibilityHidden(true)
                field()
                    .offset(y: isFloating ? Self.floatingOffset : 0)
            }
            trailing()
        }
        .frame(minHeight: 48)
        .padding(.horizontal, 20)
        .padding(.vertical, 6)
        .authFieldBackground()
        .animation(.snappy(duration: 0.2), value: isFloating)
    }
}

extension CredentialField where Trailing == EmptyView {
    init(label: String, isFloating: Bool, @ViewBuilder field: @escaping () -> Field) {
        self.init(label: label, isFloating: isFloating, field: field, trailing: { EmptyView() })
    }
}
