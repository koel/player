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
                            .buttonStyle(.glass)

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
            .background {
                Image("background")
                    .resizable()
                    .scaledToFill()
                    .ignoresSafeArea()
            }
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
        VStack(spacing: 0) {
            CredentialField {
                TextField("Server URL", text: $host)
                    .keyboardType(.URL)
                    .textContentType(.URL)
                    .accessibilityLabel("Host")
                    .focused($focusedField, equals: .host)
                    .submitLabel(.next)
                    .onSubmit { focusedField = .email }
            }
            Divider().padding(.leading, 20)
            CredentialField {
                TextField("Email", text: $email)
                    .keyboardType(.emailAddress)
                    .textContentType(.username)
                    .accessibilityLabel("Email")
                    .focused($focusedField, equals: .email)
                    .submitLabel(.next)
                    .onSubmit { focusedField = .password }
            }
            Divider().padding(.leading, 20)
            CredentialField {
                SecureField("Password", text: $password)
                    .textContentType(.password)
                    .accessibilityLabel("Password")
                    .focused($focusedField, equals: .password)
                    .submitLabel(.go)
                    .onSubmit(logIn)
            }
        }
        .textInputAutocapitalization(.never)
        .autocorrectionDisabled()
        .glassEffect(.regular, in: .rect(cornerRadius: 28, style: .continuous))
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

extension Optional {
    /// Drives `.alert(isPresented:)` from an optional message.
    var isPresent: Bool {
        get { self != nil }
        set { if !newValue { self = nil } }
    }
}

private struct CredentialField<Field: View>: View {
    @ViewBuilder let field: () -> Field

    var body: some View {
        field()
            .padding(.horizontal, 20)
            .padding(.vertical, 16)
    }
}
