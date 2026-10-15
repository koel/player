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
                    VStack(spacing: 24) {
                        Image("logo")
                            .resizable()
                            .scaledToFit()
                            .frame(width: 120, height: 120)

                        credentials

                        VStack(spacing: 12) {
                            Button(action: logIn) {
                                Group {
                                    if isAuthenticating {
                                        ProgressView()
                                    } else {
                                        Text("Log In")
                                    }
                                }
                                .frame(maxWidth: .infinity)
                            }
                            .buttonStyle(.glassProminent)
                            .controlSize(.large)
                            .disabled(!canSubmit)

                            Button("Log In with QR Code", systemImage: "qrcode.viewfinder") {
                                if DataScannerViewController.isSupported {
                                    isScanning = true
                                } else {
                                    errorMessage = "This device can't scan QR codes. Log in with your email and password instead."
                                }
                            }
                            .disabled(isAuthenticating)
                        }
                    }
                    .padding(.horizontal, 20)
                    .frame(maxWidth: 480)
                    .frame(maxWidth: .infinity, minHeight: proxy.size.height)
                }
                .scrollDismissesKeyboard(.interactively)
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
            TextField("Host", text: $host, prompt: Text(verbatim: "https://koel.example.com"))
                .keyboardType(.URL)
                .textContentType(.URL)
                .accessibilityLabel("Host")
                .padding(.vertical, 14)
            Divider()
            TextField("Email", text: $email, prompt: Text(verbatim: "you@example.com"))
                .keyboardType(.emailAddress)
                .textContentType(.username)
                .accessibilityLabel("Email")
                .padding(.vertical, 14)
            Divider()
            SecureField("Password", text: $password)
                .textContentType(.password)
                .accessibilityLabel("Password")
                .onSubmit(logIn)
                .padding(.vertical, 14)
        }
        .textInputAutocapitalization(.never)
        .autocorrectionDisabled()
        .padding(.horizontal, 16)
        .background(.fill.tertiary, in: .rect(cornerRadius: 24, style: .continuous))
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
