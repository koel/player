import SwiftUI

/// A short form in a sheet with Cancel and a submit button, like Flutter's showFormSheet.
/// Dismisses itself once `submit` succeeds; shows `failureMessage` when it throws.
struct FormSheet<Fields: View>: View {
    let title: String
    let submitLabel: String
    let canSubmit: Bool
    let failureMessage: (any Error) -> String
    let submit: () async throws -> Void
    @ViewBuilder var fields: () -> Fields

    @Environment(\.dismiss) private var dismiss
    @State private var isSubmitting = false
    @State private var failure: String?

    var body: some View {
        NavigationStack {
            Form(content: fields)
                .disabled(isSubmitting)
                .navigationTitle(title)
                .navigationBarTitleDisplayMode(.inline)
                .toolbar {
                    ToolbarItem(placement: .cancellationAction) {
                        Button("Cancel", role: .cancel) { dismiss() }
                    }
                    ToolbarItem(placement: .confirmationAction) {
                        if isSubmitting {
                            ProgressView()
                        } else {
                            Button(submitLabel, role: .confirm) {
                                Task { await performSubmit() }
                            }
                            .disabled(!canSubmit)
                        }
                    }
                }
                .alert("Error", isPresented: Binding(get: { failure != nil }, set: { if !$0 { failure = nil } })) {
                    Button("OK", role: .cancel) {}
                } message: {
                    Text(failure ?? "")
                }
        }
        .presentationDetents([.medium, .large])
    }

    private func performSubmit() async {
        isSubmitting = true
        defer { isSubmitting = false }
        do {
            try await submit()
            dismiss()
        } catch {
            failure = failureMessage(error)
        }
    }
}
