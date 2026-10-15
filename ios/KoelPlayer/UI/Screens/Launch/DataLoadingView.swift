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
                    Label("Oops!", systemImage: "exclamationmark.icloud")
                } description: {
                    Text("The request cannot be completed. Please double-check if you are connected to the internet.")
                } actions: {
                    Button("Retry") { attempt += 1 }
                        .buttonStyle(.glassProminent)
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

        do {
            try await withThrowingTaskGroup(of: Void.self) { [app] group in
                group.addTask { @MainActor in try await app.core.loadData() }
                group.addTask {
                    try await Task.sleep(for: Self.timeout)
                    throw TimeoutError()
                }
                defer { group.cancelAll() }
                try await group.next()
            }
            app.didLoadData()
        } catch is CancellationError {
            return
        } catch {
            hasFailed = true
        }
    }
}

private struct TimeoutError: Error {}
