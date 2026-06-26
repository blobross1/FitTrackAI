import Foundation

enum OpenAIConfig {
    private static let keychainAccount = "openai_api_key"

    /// API key from Keychain, then Info.plist `OPENAI_API_KEY`, then Xcode scheme env var.
    static var apiKey: String? {
        if let stored = KeychainHelper.load(account: keychainAccount), !stored.isEmpty {
            return stored
        }
        if let plist = Bundle.main.object(forInfoDictionaryKey: "OPENAI_API_KEY") as? String,
           !plist.isEmpty, !plist.hasPrefix("$(") {
            return plist
        }
        if let env = ProcessInfo.processInfo.environment["OPENAI_API_KEY"], !env.isEmpty {
            return env
        }
        return nil
    }

    static var hasAPIKey: Bool { apiKey != nil }

    static func saveAPIKey(_ key: String) throws {
        try KeychainHelper.save(account: keychainAccount, value: key.trimmingCharacters(in: .whitespacesAndNewlines))
    }

    static func clearAPIKey() throws {
        try KeychainHelper.delete(account: keychainAccount)
    }
}
