import SwiftUI

/// Shown when onboarding is done but the user has no active subscription.
struct AppPaywallGateView: View {
    @ObservedObject private var subscription = SubscriptionManager.shared
    @State private var didTrigger = false

    var body: some View {
        ZStack {
            OnboardingBackground()

            VStack(spacing: 24) {
                Spacer()
                Image(systemName: "lock.shield.fill")
                    .font(.system(size: 56))
                    .foregroundStyle(OnboardingTheme.accentGradient)

                Text("Subscription required")
                    .font(.title2.bold())
                    .foregroundStyle(.white)

                Text("Subscribe to run AI body fat scans and track your progress.")
                    .font(.body)
                    .foregroundStyle(.white.opacity(0.65))
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 32)

                Spacer()

                VStack(spacing: 12) {
                    OnboardingPrimaryButton(title: "Unlock My Plan") {
                        subscription.presentPaywall(placement: SuperwallPlacement.mainGate)
                    }

                    Button("Restore Purchases") {
                        Task { await subscription.restorePurchases() }
                    }
                    .font(.subheadline)
                    .foregroundStyle(.white.opacity(0.6))
                }
                .padding(.horizontal, 24)
                .padding(.bottom, 40)
            }
        }
        .onAppear {
            guard !didTrigger else { return }
            didTrigger = true
            subscription.presentPaywall(placement: SuperwallPlacement.mainGate)
        }
    }
}

#Preview {
    AppPaywallGateView()
}
