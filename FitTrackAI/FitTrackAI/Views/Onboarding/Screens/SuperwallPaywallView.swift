import SwiftUI

/// Onboarding paywall step — presents Superwall when configured.
struct SuperwallPaywallView: View {
    @ObservedObject var onboarding: OnboardingStore
    @ObservedObject private var subscription = SubscriptionManager.shared

    private var isDevBypass: Bool { AppConfig.bypassPaywallForDevelopment }

    var body: some View {
        ZStack {
            OnboardingBackground()

            VStack(spacing: 20) {
                Spacer()

                Image(systemName: "crown.fill")
                    .font(.system(size: 48))
                    .foregroundStyle(OnboardingTheme.accentGradient)

                Text("Unlock your plan")
                    .font(.title.bold())
                    .foregroundStyle(.white)

                Text("Start your transformation today.")
                    .font(.subheadline)
                    .foregroundStyle(OnboardingTheme.accentSecondary)

                if isDevBypass {
                    Text("Dev mode: paywall bypassed. Tap below to enter the app.")
                        .font(.caption)
                        .foregroundStyle(.green)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 24)
                } else if !AppConfig.hasValidSuperwallKey {
                    Text("Add your pk_… key to FitTrackAI/Secrets.xcconfig as SUPERWALL_API_KEY, then Clean Build. See SUPERWALL_SETUP.md.")
                        .font(.caption)
                        .foregroundStyle(.orange)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 24)
                } else {
                    Text("Choose a plan to unlock AI scans, your calorie target, and full analytics.")
                        .font(.caption)
                        .foregroundStyle(.white.opacity(0.55))
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 24)
                }

                Spacer()

                VStack(spacing: 12) {
                    if isDevBypass {
                        OnboardingPrimaryButton(title: "Continue to App") {
                            onboarding.completeOnboarding()
                        }
                    } else if AppConfig.hasValidSuperwallKey {
                        OnboardingPrimaryButton(title: "View Plans") {
                            subscription.presentOnboardingPaywall {
                                onboarding.completeOnboarding()
                            }
                        }

                        Button("Restore Purchases") {
                            Task {
                                await subscription.restorePurchases()
                                if subscription.isSubscribed {
                                    onboarding.completeOnboarding()
                                }
                            }
                        }
                        .font(.subheadline)
                        .foregroundStyle(.white.opacity(0.6))

                        if subscription.isSubscribed {
                            OnboardingPrimaryButton(title: "Continue to App") {
                                onboarding.completeOnboarding()
                            }
                        }
                    }
                }
                .padding(.horizontal, 24)
                .padding(.bottom, 32)
            }
        }
        .onAppear {
            guard !isDevBypass, AppConfig.hasValidSuperwallKey else { return }
            subscription.presentOnboardingPaywall {
                onboarding.completeOnboarding()
            }
        }
        .onChange(of: subscription.isSubscribed) { _, subscribed in
            if subscribed, !isDevBypass {
                onboarding.completeOnboarding()
            }
        }
    }
}

#Preview {
    SuperwallPaywallView(onboarding: OnboardingStore.shared)
}
