import SwiftUI

struct RootView: View {
    @EnvironmentObject private var store: AppDataStore
    @ObservedObject private var onboarding = OnboardingStore.shared
    @ObservedObject private var subscription = SubscriptionManager.shared

    var body: some View {
        Group {
            if !onboarding.hasCompletedOnboarding {
                OnboardingFlowView(store: onboarding)
            } else if !subscription.isSubscribed {
                AppPaywallGateView()
            } else {
                MainTabView()
            }
        }
        .animation(.easeInOut(duration: 0.35), value: onboarding.hasCompletedOnboarding)
        .animation(.easeInOut(duration: 0.35), value: subscription.isSubscribed)
        .onReceive(NotificationCenter.default.publisher(for: UIApplication.didBecomeActiveNotification)) { _ in
            subscription.refreshStatus()
        }
    }
}

#Preview("Onboarding") {
    RootView()
        .environmentObject(AppDataStore.shared)
        .onAppear { OnboardingStore.shared.resetForPreview() }
}

#Preview("Main app") {
    RootView()
        .environmentObject(AppDataStore.shared)
        .onAppear {
            OnboardingStore.shared.completeOnboarding()
            SubscriptionManager.shared.refreshStatus()
        }
}
