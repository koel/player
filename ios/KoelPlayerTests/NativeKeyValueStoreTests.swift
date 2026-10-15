import Foundation
@testable import KoelPlayer
import Testing

struct NativeKeyValueStoreTests {
    private let defaults = UserDefaults(suiteName: "NativeKeyValueStoreTests-\(UUID().uuidString)")!
    private let service = "NativeKeyValueStoreTests-\(UUID().uuidString)"

    @Test func keepsTokensOutOfUserDefaults() {
        let store = NativeKeyValueStore(defaults: defaults, keychainService: service)

        store.set(key: "apiToken", value: "secret")
        store.set(key: "hostUrl", value: "https://koel.test")

        #expect(store.get(key: "apiToken") == "secret")
        #expect(defaults.string(forKey: "apiToken") == nil)
        #expect(store.get(key: "hostUrl") == "https://koel.test")
    }

    @Test func clearsAndOverwritesValues() {
        let store = NativeKeyValueStore(defaults: defaults, keychainService: service)

        store.set(key: "audioToken", value: "first")
        store.set(key: "audioToken", value: "second")
        #expect(store.get(key: "audioToken") == "second")

        store.set(key: "audioToken", value: nil)
        store.set(key: "email", value: nil)
        #expect(store.get(key: "audioToken") == nil)
        #expect(store.get(key: "email") == nil)
    }
}
