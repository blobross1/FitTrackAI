import SwiftUI

struct SubscriptionPaywallView: View {
    @ObservedObject var store: OnboardingStore
    var onUnlock: () -> Void
    var onRestore: (() -> Void)?

    private let benefits = [
        ("viewfinder.circle.fill", "AI physique analysis"),
        ("flame.fill", "Personalized calorie targets"),
        ("arrow.triangle.2.circlepath", "Weekly macro adjustments"),
        ("chart.xyaxis.line", "Progress tracking & projections")
    ]

    private let testimonials = [
        ("Maya R.", "Lost 4.2% body fat in 10 weeks. The scan kept me honest."),
        ("James T.", "Finally a plan that adapts when life gets busy.")
    ]

    var body: some View {
        ZStack {
            OnboardingBackground()

            ScrollView(.vertical, showsIndicators: false) {
                VStack(spacing: 24) {
                    header
                    planCards
                    benefitsSection
                    testimonialsSection
                    urgencyBanner
                }
                .padding(.horizontal, 24)
                .padding(.top, 16)
                .padding(.bottom, 120)
            }

            VStack {
                Spacer()
                ctaFooter
            }
        }
    }

    private var header: some View {
        VStack(spacing: 12) {
            Image(systemName: "crown.fill")
                .font(.system(size: 40))
                .foregroundStyle(OnboardingTheme.accentGradient)
                .shadow(color: OnboardingTheme.accent.opacity(0.5), radius: 16)

            Text("Unlock your transformation")
                .font(.system(size: 30, weight: .bold, design: .rounded))
                .foregroundStyle(.white)
                .multilineTextAlignment(.center)

            Text("Start your transformation today.")
                .font(.subheadline.weight(.medium))
                .foregroundStyle(OnboardingTheme.accentSecondary)
        }
        .padding(.top, 8)
    }

    private var planCards: some View {
        HStack(spacing: 12) {
            ForEach(SubscriptionPlan.allCases) { plan in
                Button {
                    withAnimation(.spring(response: 0.35, dampingFraction: 0.82)) {
                        store.selectedPlan = plan
                    }
                } label: {
                    VStack(alignment: .leading, spacing: 10) {
                        if let badge = plan.savingsBadge {
                            Text(badge)
                                .font(.caption2.weight(.bold))
                                .foregroundStyle(.black)
                                .padding(.horizontal, 8)
                                .padding(.vertical, 4)
                                .background(OnboardingTheme.accentSecondary)
                                .clipShape(Capsule())
                        } else {
                            Spacer().frame(height: 22)
                        }

                        Text(plan.title)
                            .font(.headline.weight(.semibold))
                            .foregroundStyle(.white)

                        HStack(alignment: .firstTextBaseline, spacing: 2) {
                            Text(plan.price)
                                .font(.title2.weight(.bold))
                            Text(plan.period)
                                .font(.caption)
                                .foregroundStyle(.white.opacity(0.5))
                        }
                        .foregroundStyle(.white)

                        if let equiv = plan.perMonthEquivalent {
                            Text(equiv)
                                .font(.caption.weight(.medium))
                                .foregroundStyle(OnboardingTheme.accentSecondary)
                        } else {
                            Text(" ")
                                .font(.caption)
                        }
                    }
                    .padding(16)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background {
                        RoundedRectangle(cornerRadius: 18, style: .continuous)
                            .fill(OnboardingTheme.card)
                            .overlay {
                                RoundedRectangle(cornerRadius: 18, style: .continuous)
                                    .stroke(
                                        store.selectedPlan == plan ? OnboardingTheme.accent : OnboardingTheme.glassStroke,
                                        lineWidth: store.selectedPlan == plan ? 2 : 1
                                    )
                            }
                            .shadow(
                                color: store.selectedPlan == plan ? OnboardingTheme.accent.opacity(0.35) : .clear,
                                radius: 14
                            )
                    }
                }
                .buttonStyle(.plain)
            }
        }
    }

    private var benefitsSection: some View {
        OnboardingGlassCard {
            VStack(alignment: .leading, spacing: 14) {
                Text("Everything included")
                    .font(.headline.weight(.semibold))
                    .foregroundStyle(.white)
                ForEach(benefits, id: \.1) { icon, text in
                    HStack(spacing: 12) {
                        Image(systemName: icon)
                            .foregroundStyle(OnboardingTheme.accent)
                            .frame(width: 28)
                        Text(text)
                            .font(.subheadline)
                            .foregroundStyle(.white.opacity(0.8))
                    }
                }
            }
        }
    }

    private var testimonialsSection: some View {
        VStack(spacing: 12) {
            ForEach(testimonials, id: \.0) { name, quote in
                OnboardingGlassCard {
                    VStack(alignment: .leading, spacing: 8) {
                        HStack(spacing: 4) {
                            ForEach(0..<5, id: \.self) { _ in
                                Image(systemName: "star.fill")
                                    .font(.caption2)
                                    .foregroundStyle(OnboardingTheme.accentSecondary)
                            }
                            Spacer()
                            Text(name)
                                .font(.caption.weight(.semibold))
                                .foregroundStyle(.white.opacity(0.5))
                        }
                        Text("\"\(quote)\"")
                            .font(.subheadline)
                            .foregroundStyle(.white.opacity(0.75))
                            .italic()
                    }
                }
            }
        }
    }

    private var urgencyBanner: some View {
        HStack(spacing: 10) {
            Image(systemName: "clock.badge.checkmark.fill")
                .foregroundStyle(OnboardingTheme.accentSecondary)
            Text("Limited-time launch pricing — cancel anytime.")
                .font(.caption)
                .foregroundStyle(.white.opacity(0.6))
        }
        .padding(14)
        .frame(maxWidth: .infinity)
        .background(OnboardingTheme.accent.opacity(0.12))
        .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
    }

    private var ctaFooter: some View {
        VStack(spacing: 12) {
            OnboardingPrimaryButton(title: "Unlock My Plan", action: onUnlock)

            Button("Restore Purchases") {
                onRestore?()
            }
            .font(.caption)
            .foregroundStyle(.white.opacity(0.45))

            Text("Mock paywall — no charge. Tap to enter the app.")
                .font(.caption2)
                .foregroundStyle(.white.opacity(0.3))
                .multilineTextAlignment(.center)
        }
        .padding(.horizontal, 24)
        .padding(.vertical, 20)
        .background {
            LinearGradient(
                colors: [.clear, Color.black.opacity(0.92), .black],
                startPoint: .top,
                endPoint: .bottom
            )
            .ignoresSafeArea(edges: .bottom)
        }
    }
}

#Preview {
    SubscriptionPaywallView(store: OnboardingStore.shared, onUnlock: {})
}
