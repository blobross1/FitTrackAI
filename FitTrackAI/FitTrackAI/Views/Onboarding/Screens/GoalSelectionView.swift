import SwiftUI

struct GoalSelectionView: View {
    @ObservedObject var store: OnboardingStore
    @State private var showCustomSlider = false

    var body: some View {
        OnboardingScreenShell(
            step: OnboardingStep.goal.progressIndex,
            title: "What is your desired body fat percentage?",
            subtitle: "We’ll personalize your cut plan to hit this target."
        ) {
            VStack(spacing: 12) {
                ForEach(BodyFatGoalRange.allCases) { range in
                    Button {
                        withAnimation(.spring(response: 0.35, dampingFraction: 0.82)) {
                            store.goalRange = range
                            showCustomSlider = range == .custom
                        }
                    } label: {
                        OnboardingGlassCard(isSelected: store.goalRange == range) {
                            HStack {
                                VStack(alignment: .leading, spacing: 4) {
                                    Text(range.rawValue)
                                        .font(.headline.weight(.semibold))
                                        .foregroundStyle(.white)
                                    Text(range.subtitle)
                                        .font(.subheadline)
                                        .foregroundStyle(.white.opacity(0.55))
                                }
                                Spacer()
                                if store.goalRange == range {
                                    Image(systemName: "checkmark.circle.fill")
                                        .foregroundStyle(OnboardingTheme.accentSecondary)
                                }
                            }
                        }
                    }
                    .buttonStyle(.plain)
                }

                if showCustomSlider || store.goalRange == .custom {
                    OnboardingGlassCard {
                        VStack(alignment: .leading, spacing: 12) {
                            HStack {
                                Text("Custom target")
                                    .font(.subheadline.weight(.medium))
                                    .foregroundStyle(.white.opacity(0.7))
                                Spacer()
                                Text("\(store.customGoalPercent, specifier: "%.1f")%")
                                    .font(.title3.weight(.bold))
                                    .foregroundStyle(OnboardingTheme.accentSecondary)
                            }
                            Slider(value: $store.customGoalPercent, in: 8...22, step: 0.5)
                                .tint(OnboardingTheme.accent)
                        }
                    }
                    .transition(.opacity.combined(with: .move(edge: .top)))
                }
            }
        } footer: {
            OnboardingPrimaryButton(
                title: "Continue",
                enabled: store.canContinueFromGoal,
                action: store.advance
            )
        }
    }
}

#Preview {
    GoalSelectionView(store: OnboardingStore.shared)
}
