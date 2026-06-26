import SwiftUI

struct GoalTimelineView: View {
    @ObservedObject var store: OnboardingStore

    var body: some View {
        OnboardingScreenShell(
            step: OnboardingStep.timeline.progressIndex,
            title: "When do you want to reach your goal?",
            subtitle: "We’ll calculate your daily calories from your stats, body fat, and target leanness."
        ) {
            VStack(spacing: 24) {
                VStack(spacing: 8) {
                    Text("\(store.goalWeeks)")
                        .font(.system(size: 64, weight: .bold, design: .rounded))
                        .foregroundStyle(.white)
                        .contentTransition(.numericText())
                        .animation(.spring(response: 0.35, dampingFraction: 0.8), value: store.goalWeeks)

                    Text(store.goalWeeks == 1 ? "week" : "weeks")
                        .font(.title3.weight(.medium))
                        .foregroundStyle(.white.opacity(0.55))
                }
                .frame(maxWidth: .infinity)

                VStack(spacing: 6) {
                    Slider(
                        value: Binding(
                            get: { Double(store.goalWeeks) },
                            set: { store.goalWeeks = Int($0.rounded()) }
                        ),
                        in: 1...12,
                        step: 1
                    )
                    .tint(OnboardingTheme.accent)

                    HStack {
                        Text("1 wk")
                        Spacer()
                        Text("12 wks")
                    }
                    .font(.caption)
                    .foregroundStyle(.white.opacity(0.45))
                }

                OnboardingGlassCard {
                    VStack(alignment: .leading, spacing: 10) {
                        Label("How we calculate calories", systemImage: "function")
                            .font(.subheadline.weight(.semibold))
                            .foregroundStyle(OnboardingTheme.accentSecondary)

                        Text("We estimate your metabolism (Mifflin–St Jeor), then spread the energy needed to lose fat—about 7,700 kcal per kg—across your timeline while keeping lean mass steady.")
                            .font(.caption)
                            .foregroundStyle(.white.opacity(0.65))
                            .fixedSize(horizontal: false, vertical: true)
                    }
                }
            }
        } footer: {
            VStack(spacing: 8) {
                OnboardingPrimaryButton(title: "Continue", action: store.advance)
                OnboardingSecondaryButton(title: "Skip for now") {
                    store.skipTimeline()
                    store.advance()
                }
            }
        }
    }
}

#Preview {
    GoalTimelineView(store: OnboardingStore.shared)
}
