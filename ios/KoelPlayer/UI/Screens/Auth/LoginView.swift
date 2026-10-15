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

    private var canSubmit: Bool {
        !host.isBlank && !email.isBlank && !password.isEmpty && !isAuthenticating
    }

    var body: some View {
        NavigationStack {
            GeometryReader { proxy in
                ScrollView {
                    VStack(spacing: 32) {
                        VStack(spacing: 12) {
                            Image("logo")
                                .resizable()
                                .scaledToFit()
                                .frame(width: 88, height: 88)
                            Text("Koel")
                                .font(.largeTitle.bold())
                            Text("Log in to your Koel server")
                                .font(.subheadline)
                                .foregroundStyle(.secondary)
                        }

                        credentials

                        VStack(spacing: 12) {
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
                            .controlSize(.extraLarge)
                            .disabled(!canSubmit)

                            Button {
                                if DataScannerViewController.isSupported {
                                    isScanning = true
                                } else {
                                    errorMessage = "This device can't scan QR codes. Log in with your email and password instead."
                                }
                            } label: {
                                Label("Log In with QR Code", systemImage: "qrcode.viewfinder")
                                    .frame(maxWidth: .infinity)
                            }
                            .buttonStyle(.glass)
                            .controlSize(.extraLarge)
                            .disabled(isAuthenticating)
                        }
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
            CredentialField(systemImage: "server.rack") {
                TextField("Server URL", text: $host)
                    .keyboardType(.URL)
                    .textContentType(.URL)
                    .accessibilityLabel("Host")
            }
            Divider().padding(.leading, 52)
            CredentialField(systemImage: "envelope") {
                TextField("Email", text: $email)
                    .keyboardType(.emailAddress)
                    .textContentType(.username)
                    .accessibilityLabel("Email")
            }
            Divider().padding(.leading, 52)
            CredentialField(systemImage: "lock") {
                SecureField("Password", text: $password)
                    .textContentType(.password)
                    .accessibilityLabel("Password")
                    .onSubmit(logIn)
            }
        }
        .textInputAutocapitalization(.never)
        .autocorrectionDisabled()
        .glassEffect(.regular, in: .rect(cornerRadius: 28, style: .continuous))
    }

    private func logIn() {
        guard canSubmit else { return }

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
    let systemImage: String
    @ViewBuilder let field: () -> Field

    var body: some View {
        HStack(spacing: 14) {
            Image(systemName: systemImage)
                .foregroundStyle(.secondary)
                .frame(width: 22)
            field()
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 16)
    }
}
