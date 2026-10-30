import Foundation
import Security

/// Anthropic API key storage. Reads never show a UI prompt: if the Keychain
/// would need to ask (e.g. after a rebuild changed the ad-hoc signature), the
/// read fails fast and the reason is logged instead of blocking a thread.
enum Keychain {
    private static let service = "PillReminderMontyPython"
    private static let account = "anthropic_api_key"

    enum ReadResult {
        case found(String)
        case missing
        case denied(OSStatus)
    }

    static func read() -> ReadResult {
        let q: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: account,
            kSecReturnData as String: true,
            kSecMatchLimit as String: kSecMatchLimitOne,
            kSecUseAuthenticationUI as String: kSecUseAuthenticationUIFail,
        ]
        var out: AnyObject?
        let status = SecItemCopyMatching(q as CFDictionary, &out)
        switch status {
        case errSecSuccess:
            if let d = out as? Data, let s = String(data: d, encoding: .utf8), !s.isEmpty { return .found(s) }
            return .missing
        case errSecItemNotFound:
            return .missing
        default:
            return .denied(status)
        }
    }

    @discardableResult
    static func save(_ key: String) -> Bool {
        let base: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: account,
        ]
        SecItemDelete(base as CFDictionary)
        let trimmed = key.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return true }
        var add = base
        add[kSecValueData as String] = Data(trimmed.utf8)
        add[kSecAttrAccessible as String] = kSecAttrAccessibleAfterFirstUnlock
        let status = SecItemAdd(add as CFDictionary, nil)
        if status != errSecSuccess { Log.error("Keychain save failed: OSStatus \(status)") }
        return status == errSecSuccess
    }

    /// Keychain first, then the ANTHROPIC_API_KEY environment variable.
    static func apiKey() -> (key: String?, source: String) {
        switch read() {
        case .found(let k): return (k, "keychain")
        case .denied(let s):
            if let env = ProcessInfo.processInfo.environment["ANTHROPIC_API_KEY"], !env.isEmpty { return (env, "env") }
            return (nil, "keychain access denied (OSStatus \(s)) — re-enter the key in Settings")
        case .missing:
            if let env = ProcessInfo.processInfo.environment["ANTHROPIC_API_KEY"], !env.isEmpty { return (env, "env") }
            return (nil, "no API key — add one in Settings")
        }
    }
}
