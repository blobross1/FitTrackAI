import SwiftUI

/// Unified premium palette (matches onboarding / paywall).
enum AppTheme {
    static let background = Color.black
    static let card = OnboardingTheme.card
    static let cardMuted = OnboardingTheme.card.opacity(0.5)
    static let accent = OnboardingTheme.accent
    static let accentSecondary = OnboardingTheme.accentSecondary
    static let accentGradient = OnboardingTheme.accentGradient
    static let backgroundGradient = OnboardingTheme.backgroundGradient
    static let glassStroke = OnboardingTheme.glassStroke
    static let textPrimary = Color.white
    static let textSecondary = Color.white.opacity(0.55)
    static let push = OnboardingTheme.accent
    static let pull = OnboardingTheme.accentSecondary
    static let legs = Color.green
}

struct PremiumScreenBackground: View {
    @State private var animate = false

    var body: some View {
        ZStack {
            AppTheme.backgroundGradient.ignoresSafeArea()

            Circle()
                .fill(AppTheme.accent.opacity(0.18))
                .frame(width: 280, height: 280)
                .blur(radius: 70)
                .offset(x: animate ? 70 : -50, y: animate ? -140 : -90)

            Circle()
                .fill(AppTheme.accentSecondary.opacity(0.12))
                .frame(width: 220, height: 220)
                .blur(radius: 60)
                .offset(x: animate ? -60 : 80, y: animate ? 280 : 220)
        }
        .onAppear {
            withAnimation(.easeInOut(duration: 6).repeatForever(autoreverses: true)) {
                animate = true
            }
        }
    }
}
