import Foundation
import SuperwallKit

enum SuperwallPlacement {
    static let onboardingPaywall = "onboarding_paywall"
    static let mainGate = "main_gate"
    static let bodyFatScan = "body_fat_scan"
}

enum BodyFatScanGate {
    case allowed
    case paywall
    case blocked
}

@MainActor
final class SubscriptionManager: NSObject, ObservableObject {
    static let shared = SubscriptionManager()

    @Published private(set) var isSubscribed = false
    @Published private(set) var isConfigured = false

    private override init() {
        super.init()
    }

    func configure() {
        if AppConfig.bypassPaywallForDevelopment {
            isSubscribed = true
            isConfigured = true
            return
        }

        guard AppConfig.hasValidSuperwallKey else {
            isSubscribed = false
            isConfigured = false
            return
        }

        let options = SuperwallOptions()
        #if DEBUG
        options.logging.level = .debug
        options.logging.scopes = [.all]
        #else
        options.logging.level = .warn
        #endif
        options.paywalls.automaticallyDismiss = true
        options.storeKitVersion = .storeKit2

        Superwall.configure(apiKey: AppConfig.superwallAPIKey, options: options)
        Superwall.shared.delegate = self
        isConfigured = true
        refreshStatus()
    }

    func refreshStatus() {
        if AppConfig.bypassPaywallForDevelopment {
            isSubscribed = true
            return
        }

        guard isConfigured else { return }

        switch Superwall.shared.subscriptionStatus {
        case .active:
            isSubscribed = true
        case .inactive, .unknown:
            isSubscribed = false
        @unknown default:
            isSubscribed = false
        }
    }

    var canAnalyzeBodyFat: Bool {
        AppConfig.bypassPaywallForDevelopment || isSubscribed
    }

    /// Presents the onboarding paywall (if configured in dashboard). `onUnlocked` runs when the user has access (gated paywall + purchase).
    func presentOnboardingPaywall(onUnlocked: @escaping () -> Void) {
        guard isConfigured else { return }
        registerFeature(placement: SuperwallPlacement.onboardingPaywall, onAccess: onUnlocked)
    }

    @discardableResult
    func requestBodyFatScan(onAccess: @escaping () -> Void) -> BodyFatScanGate {
        if canAnalyzeBodyFat {
            onAccess()
            return .allowed
        }

        if !isConfigured {
            if AppConfig.hasValidBackend {
                onAccess()
                return .allowed
            }
            return .blocked
        }

        registerFeature(placement: SuperwallPlacement.bodyFatScan, onAccess: onAccess)
        return .paywall
    }

    @discardableResult
    func register(placement: String, onAccess: @escaping () -> Void) -> Bool {
        if placement == SuperwallPlacement.bodyFatScan {
            switch requestBodyFatScan(onAccess: onAccess) {
            case .allowed, .paywall: return true
            case .blocked: return false
            }
        }

        if canAnalyzeBodyFat {
            onAccess()
            return true
        }

        guard isConfigured else { return false }

        registerFeature(placement: placement, onAccess: onAccess)
        return true
    }

    func presentPaywall(placement: String) {
        register(placement: placement) {}
    }

    func restorePurchases() async {
        guard isConfigured else { return }
        _ = await Superwall.shared.restorePurchases()
        refreshStatus()
    }

    /// Superwall decides whether to show a paywall; the feature block runs per dashboard Feature Gating (Gated vs Non-Gated).
    private func registerFeature(placement: String, onAccess: @escaping () -> Void) {
        Superwall.shared.register(placement: placement) { [weak self] in
            Task { @MainActor in
                self?.refreshStatus()
                onAccess()
            }
        }
    }
}

extension SubscriptionManager: SuperwallDelegate {
    nonisolated func subscriptionStatusDidChange(
        from oldValue: SubscriptionStatus,
        to newValue: SubscriptionStatus
    ) {
        Task { @MainActor in
            refreshStatus()
        }
    }
}
