import SwiftUI
import VisionKit

/// What Koel's web UI encodes in its login QR code: base64 of `{"host": …, "token": …}`.
struct LoginQRPayload: Decodable, Equatable {
    let host: String
    let token: String

    init?(scanned: String) {
        guard let data = Data(base64Encoded: scanned.trimmingCharacters(in: .whitespacesAndNewlines)),
              let payload = try? JSONDecoder().decode(Self.self, from: data)
        else { return nil }
        self = payload
    }
}

struct LoginQRScanner: View {
    let onScan: (LoginQRPayload) -> Void

    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            Scanner(onScan: onScan)
                .ignoresSafeArea()
                .navigationTitle("Scan Login Code")
                .navigationBarTitleDisplayMode(.inline)
                .toolbar {
                    ToolbarItem(placement: .cancellationAction) {
                        Button("Cancel", systemImage: "xmark", role: .cancel) { dismiss() }
                    }
                }
        }
    }

    private struct Scanner: UIViewControllerRepresentable {
        let onScan: (LoginQRPayload) -> Void

        func makeUIViewController(context: Context) -> DataScannerViewController {
            let scanner = DataScannerViewController(
                recognizedDataTypes: [.barcode(symbologies: [.qr])],
                qualityLevel: .balanced,
                isHighlightingEnabled: true
            )
            scanner.delegate = context.coordinator
            try? scanner.startScanning()
            return scanner
        }

        func updateUIViewController(_ scanner: DataScannerViewController, context: Context) {}

        func makeCoordinator() -> Coordinator {
            Coordinator(onScan: onScan)
        }

        final class Coordinator: NSObject, DataScannerViewControllerDelegate {
            private let onScan: (LoginQRPayload) -> Void
            private var hasScanned = false

            init(onScan: @escaping (LoginQRPayload) -> Void) {
                self.onScan = onScan
            }

            func dataScanner(_ scanner: DataScannerViewController, didAdd items: [RecognizedItem], allItems: [RecognizedItem]) {
                guard !hasScanned else { return }

                for case .barcode(let barcode) in items {
                    guard let payload = barcode.payloadStringValue.flatMap(LoginQRPayload.init(scanned:)) else { continue }
                    hasScanned = true
                    UINotificationFeedbackGenerator().notificationOccurred(.success)
                    onScan(payload)
                    return
                }
            }
        }
    }
}
