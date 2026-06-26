import Foundation
import Security

enum KeychainHelper {
    static func save(account: String, value: String) throws {
        let data = Data(value.utf8)
        try delete(account: account)

        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrAccount as String: account,
            kSecAttrService as String: Bundle.main.bundleIdentifier ?? "FitTrackAI",
            kSecValueData as String: data
        ]

        let status = SecItemAdd(query as CFDictionary, nil)
        guard status == errSecSuccess else {
            throw KeychainError.operationFailed(status)
        }
    }

    static func load(account: String) -> String? {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrAccount as String: account,
            kSecAttrService as String: Bundle.main.bundleIdentifier ?? "FitTrackAI",
            kSecReturnData as String: true,
            kSecMatchLimit as String: kSecMatchLimitOne
        ]

        var item: CFTypeRef?
        let status = SecItemCopyMatching(query as CFDictionary, &item)
        guard status == errSecSuccess, let data = item as? Data else { return nil }
        return String(data: data, encoding: .utf8)
    }

    static func delete(account: String) throws {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrAccount as String: account,
            kSecAttrService as String: Bundle.main.bundleIdentifier ?? "FitTrackAI"
        ]
        let status = SecItemDelete(query as CFDictionary)
        guard status == errSecSuccess || status == errSecItemNotFound else {
            throw KeychainError.operationFailed(status)
        }
    }
}

enum KeychainError: LocalizedError {
    case operationFailed(OSStatus)

    var errorDescription: String? {
        switch self {
        case .operationFailed(let status):
            return "Keychain error (\(status))"
        }
    }
}
