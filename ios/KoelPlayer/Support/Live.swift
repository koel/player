import Observation
import Shared
import SwiftUI

/// Mirrors a Kotlin `StateFlow` into SwiftUI observation, for state many views share.
@Observable
final class Live<Value> {
    private(set) var value: Value
    @ObservationIgnored private var task: Task<Void, Never>?

    init(_ flow: SkieSwiftStateFlow<Value>) {
        value = flow.value
        task = Task { [weak self] in
            for await next in flow { self?.value = next }
        }
    }

    init<Wrapped>(_ flow: SkieSwiftOptionalStateFlow<Wrapped>) where Value == Wrapped? {
        value = flow.value
        task = Task { [weak self] in
            for await next in flow { self?.value = next }
        }
    }

    isolated deinit {
        task?.cancel()
    }
}

extension View {
    /// Collects a Kotlin `Flow` for as long as the view is visible, restarting when `id` changes.
    func collect<Value>(
        _ flow: @autoclosure @escaping () -> SkieSwiftFlow<Value>,
        id: some Equatable = 0,
        perform action: @escaping (Value) -> Void
    ) -> some View {
        task(id: id) {
            for await value in flow() { action(value) }
        }
    }

    func collect<Wrapped>(
        _ flow: @autoclosure @escaping () -> SkieSwiftOptionalFlow<Wrapped>,
        id: some Equatable = 0,
        perform action: @escaping (Wrapped?) -> Void
    ) -> some View {
        task(id: id) {
            for await value in flow() { action(value) }
        }
    }
}
