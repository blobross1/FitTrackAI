import SwiftUI

struct WorkoutFrequencyView: View {
    @ObservedObject var store: OnboardingStore

    private let dayIcons = [
        "figure.walk", "figure.run", "figure.strengthtraining.traditional",
        "dumbbell.fill", "heart.fill", "flame.fill", "bolt.heart.fill", "star.fill"
    ]

    var body: some View {
        OnboardingScreenShell(
            step: OnboardingStep.frequency.progressIndex,
            title: "How many times do you work out per week?",
            subtitle: "We’ll tune your calorie and recovery recommendations."
        ) {
            VStack(spacing: 28) {
                ZStack {
                    Circle()
                        .fill(OnboardingTheme.glowGradient)
                        .frame(width: 200, height: 200)
                    Image(systemName: dayIcons[min(store.workoutsPerWeek, dayIcons.count - 1)])
                        .font(.system(size: 64))
                        .foregroundStyle(OnboardingTheme.accentGradient)
                        .symbolEffect(.bounce, value: store.workoutsPerWeek)
                }
                .frame(maxWidth: .infinity)

                Text("\(store.workoutsPerWeek)")
                    .font(.system(size: 72, weight: .bold, design: .rounded))
                    .foregroundStyle(.white)
                    .contentTransition(.numericText())
                    .animation(.spring(response: 0.4, dampingFraction: 0.75), value: store.workoutsPerWeek)

                Text(store.workoutsPerWeek == 1 ? "day per week" : "days per week")
                    .font(.title3.weight(.medium))
                    .foregroundStyle(.white.opacity(0.55))

                HStack(spacing: 16) {
                    dayButton("-") {
                        if store.workoutsPerWeek > 0 {
                            withAnimation { store.workoutsPerWeek -= 1 }
                        }
                    }
                    dayButton("+") {
                        if store.workoutsPerWeek < 7 {
                            withAnimation { store.workoutsPerWeek += 1 }
                        }
                    }
                }

                HStack(spacing: 8) {
                    ForEach(0...7, id: \.self) { day in
                        Button {
                            withAnimation(.spring(response: 0.35, dampingFraction: 0.8)) {
                                store.workoutsPerWeek = day
                            }
                        } label: {
                            Text("\(day)")
                                .font(.subheadline.weight(.semibold))
                                .frame(width: 36, height: 40)
                                .foregroundStyle(store.workoutsPerWeek == day ? .black : .white.opacity(0.7))
                                .background {
                                    if store.workoutsPerWeek == day {
                                        OnboardingTheme.accentGradient
                                    } else {
                                        Color.white.opacity(0.08)
                                    }
                                }
                                .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
                        }
                        .buttonStyle(.plain)
                    }
                }
            }
            .padding(.vertical, 8)
        } footer: {
            VStack(spacing: 8) {
                OnboardingPrimaryButton(title: "Continue", enabled: true, action: store.advance)
                OnboardingSecondaryButton(title: "Back", action: store.goBack)
            }
        }
    }

    private func dayButton(_ symbol: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Image(systemName: symbol == "-" ? "minus" : "plus")
                .font(.title2.weight(.semibold))
                .frame(width: 56, height: 56)
                .foregroundStyle(.white)
                .background(OnboardingTheme.card)
                .clipShape(Circle())
                .overlay(Circle().stroke(OnboardingTheme.glassStroke, lineWidth: 1))
        }
        .buttonStyle(.plain)
    }
}

#Preview {
    WorkoutFrequencyView(store: OnboardingStore.shared)
}
