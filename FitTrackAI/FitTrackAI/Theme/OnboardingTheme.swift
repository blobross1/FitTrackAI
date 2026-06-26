import SwiftUI

enum OnboardingTheme {
    static let accent = Color(red: 0.2, green: 0.55, blue: 1.0)
    static let accentSecondary = Color(red: 0.35, green: 0.95, blue: 0.75)
    static let charcoal = Color(red: 0.06, green: 0.06, blue: 0.08)
    static let card = Color(red: 0.12, green: 0.13, blue: 0.16)
    static let glassStroke = Color.white.opacity(0.12)

    static let accentGradient = LinearGradient(
        colors: [
            Color(red: 0.25, green: 0.55, blue: 1.0),
            Color(red: 0.35, green: 0.9, blue: 0.85)
        ],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )

    static let backgroundGradient = LinearGradient(
        colors: [
            Color.black,
            Color(red: 0.04, green: 0.06, blue: 0.14),
            Color.black
        ],
        startPoint: .top,
        endPoint: .bottom
    )

    static let glowGradient = RadialGradient(
        colors: [accent.opacity(0.35), .clear],
        center: .center,
        startRadius: 20,
        endRadius: 220
    )
}
