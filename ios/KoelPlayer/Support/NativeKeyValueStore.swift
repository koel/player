import Foundation
import Security
@preconcurrency import Shared

/// Backs the shared `Preferences`: tokens go to the Keychain, everything else to UserDefaults.
nonisolated final class NativeKeyValueStore: NSObject, KeyValueStore {
    private static let keychainKeys: Set = ["apiToken", "audioToken"]

    private let defaults: UserDefaults
    private let keychainService: String

    init(defaults: UserDefaults = .standard, keychainService: String = Bundle.main.bundleIdentifier ?? "dev.koel.koel") {
        self.defaults = defaults
        self.keychainService = keychainService
    }

    func get(key: String) -> String? {
        Self.keychainKeys.contains(key) ? readKeychain(key) : defaults.string(forKey: key)
    }

    func set(key: String, value: String?) {
        guard Self.keychainKeys.contains(key) else {
            defaults.set(value, forKey: key)
            return
        }

        deleteKeychain(key)
        if let value { writeKeychain(key, value: value) }
    }

    private func query(for key: String) -> [String: Any] {
        [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: keychainService,
            kSecAttrAccount as String: key,
        ]
    }

    private func readKeychain(_ key: String) -> String? {
        var query = query(for: key)
        query[kSecReturnData as String] = true
        query[kSecMatchLimit as String] = kSecMatchLimitOne

        var result: AnyObject?
        guard SecItemCopyMatching(query as CFDictionary, &result) == errSecSuccess, let data = result as? Data else { return nil }
        return String(data: data, encoding: .utf8)
    }

    private func writeKeychain(_ key: String, value: String) {
        var query = query(for: key)
        query[kSecValueData as String] = Data(value.utf8)
        // Playback continues while the phone is locked, and stream URLs need the audio token.
        query[kSecAttrAccessible as String] = kSecAttrAccessibleAfterFirstUnlock
        SecItemAdd(query as CFDictionary, nil)
    }

    private func deleteKeychain(_ key: String) {
        SecItemDelete(query(for: key) as CFDictionary)
    }
}
