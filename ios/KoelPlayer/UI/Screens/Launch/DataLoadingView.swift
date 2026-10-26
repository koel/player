@preconcurrency import Shared
import SwiftUI

struct DataLoadingView: View {
    @Environment(AppModel.self) private var app

    @State private var attempt = 0
    @State private var isTakingLong = false
    @State private var hasFailed = false

    private static let takingLongAfter = Duration.seconds(6)
    private static let timeout = Duration.seconds(30)

    private var hasDownloads: Bool {
        !app.core.downloads.playables.value.isEmpty
    }

    var body: some View {
        Group {
            if hasFailed {
                ContentUnavailableView {
                    Label(LoadFailure.title, systemImage: "exclamationmark.icloud")
                } description: {
                    Text(LoadFailure.message)
                } actions: {
                    Button(LoadFailure.retry) { attempt += 1 }
                        .buttonStyle(.glass)
                    Button("Log Out", role: .destructive) {
                        Task { await app.logOut() }
                    }
                }
            } else {
                VStack(spacing: 24) {
                    ProgressView().controlSize(.large)

                    if isTakingLong {
                        Text("This is taking longer than usual…")
                            .foregroundStyle(.secondary)
                            .multilineTextAlignment(.center)

                        if hasDownloads {
                            Button("View Downloads", action: app.goOffline)
                                .buttonStyle(.glass)
                        }
                    }
                }
                .padding(40)
                .animation(.default, value: isTakingLong)
            }
        }
        .task(id: attempt) { await load() }
    }

    private func load() async {
        hasFailed = false
        isTakingLong = false

        let slowNotice = Task {
            try await Task.sleep(for: Self.takingLongAfter)
            isTakingLong = true
        }
        defer { slowNotice.cancel() }

        let loading = Task { try await app.loadLibrary() }
        let timeout = Task {
            try await Task.sleep(for: Self.timeout)
            loading.cancel()
        }
        defer { timeout.cancel() }

        do {
            try await withTaskCancellationHandler {
                try await loading.value
            } onCancel: {
                loading.cancel()
            }
        } catch {
            if !Task.isCancelled { hasFailed = true }
        }
    }
}

