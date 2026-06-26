import Foundation

/// Build-time keys from Info.plist (via `Secrets.xcconfig`) or Run scheme env vars.
enum AppConfig {
    static var superwallAPIKey: String {
        string(for: "SUPERWALL_API_KEY")
    }

    static var backendAnalyzeURL: URL? {
        let raw = string(for: "FITTRACK_API_URL")
        guard !raw.isEmpty else { return nil }
        guard let url = URL(string: raw), let host = url.host, !host.isEmpty else { return nil }
        return url
    }

    static var backendSecret: String? {
        let value = string(for: "FITTRACK_API_SECRET")
        return value.isEmpty ? nil : value
    }

    static var hasValidSuperwallKey: Bool {
        let key = superwallAPIKey
        return !key.isEmpty && !key.contains("YOUR_") && key.hasPrefix("pk_")
    }

    static var hasValidBackend: Bool {
        backendAnalyzeURL != nil && backendSecret != nil
    }

    static var bypassPaywallForDevelopment: Bool {
        #if DEBUG
        if ProcessInfo.processInfo.environment["BYPASS_PAYWALL"] == "1" { return true }
        if string(for: "BYPASS_PAYWALL") == "1" { return true }
        return false
        #else
        return false
        #endif
    }

    /// Helpful when analysis fails to configure (Debug only).
    static var configurationDebugSummary: String {
        let urlRaw = string(for: "FITTRACK_API_URL")
        let secretSet = !string(for: "FITTRACK_API_SECRET").isEmpty
        let urlOK = backendAnalyzeURL != nil
        if urlRaw.isEmpty && !secretSet {
            return "No FITTRACK_* keys in app bundle. Fix FitTrackAI/Secrets.xcconfig (use https:/$()/ for URLs), then Clean Build."
        }
        if !urlOK && urlRaw.hasPrefix("https:") && !urlRaw.contains("vercel") && !urlRaw.contains(".") {
            return "FITTRACK_API_URL looks truncated (xcconfig treats // as a comment). Use: https:/$()/your-app.vercel.app/api/analyze"
        }
        if !urlOK {
            return "FITTRACK_API_URL missing or invalid: \"\(urlRaw.prefix(40))\""
        }
        if !secretSet {
            return "FITTRACK_API_SECRET is empty in build settings."
        }
        return "Backend URL: \(backendAnalyzeURL?.absoluteString ?? "?")"
    }

    private static func string(for key: String) -> String {
        if let env = ProcessInfo.processInfo.environment[key] {
            let trimmed = env.trimmingCharacters(in: .whitespacesAndNewlines)
            if !trimmed.isEmpty, !trimmed.hasPrefix("$(") { return trimmed }
        }
        guard let value = Bundle.main.object(forInfoDictionaryKey: key) as? String else { return "" }
        if value.hasPrefix("$(") { return "" }
        return value.trimmingCharacters(in: .whitespacesAndNewlines)
    }
}
