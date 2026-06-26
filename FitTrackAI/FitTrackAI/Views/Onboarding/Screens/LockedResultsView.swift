import SwiftUI
import Charts

struct LockedResultsView: View {
    @ObservedObject var store: OnboardingStore

    private var plan: TransformationPlan? { store.transformationPlan }

    private var goalPercentText: String {
        String(format: "%.1f%%", store.goalBodyFatPercent)
    }

    private var bodyFatCaption: String {
        let value = store.scannedBodyFatPercent ?? 0
        return String(format: "You are %.1f%% body fat", value)
    }

    var body: some View {
        OnboardingScreenShell(
            step: OnboardingStep.lockedResults.progressIndex,
            title: "Your analysis is ready",
            subtitle: resultsSubtitle
        ) {
            VStack(spacing: 16) {
                if store.bodyPhoto != nil {
                    onboardingPhotoCard
                }

                reachGoalBanner

                transformationChart

                BlurredMetricValue(label: "Goal weight", icon: "scalemass.fill", tint: .cyan)
                BlurredMetricValue(label: "Estimated body fat", icon: "percent")
                BlurredMetricValue(
                    label: "Daily calorie target",
                    icon: "flame.fill",
                    tint: OnboardingTheme.accentSecondary
                )
                BlurredMetricValue(label: "Days to goal", icon: "calendar", tint: .purple)

                OnboardingGlassCard {
                    VStack(alignment: .leading, spacing: 12) {
                        HStack {
                            Image(systemName: "sparkles")
                                .foregroundStyle(OnboardingTheme.accentSecondary)
                            Text("Personalized transformation plan")
                                .font(.headline.weight(.semibold))
                                .foregroundStyle(.white)
                        }
                        planRow(icon: "fork.knife", text: "Daily protein · calorie targets")
                        planRow(icon: "chart.line.downtrend.xyaxis", text: "Body fat goal · timeline")
                        planRow(icon: "figure.strengthtraining.traditional", text: "Workout frequency · metabolism")
                        planRow(icon: "bell.badge", text: "Weekly AI adjustments & check-ins")
                    }
                    .blur(radius: 10)
                }
                .overlay(alignment: .center) {
                    VStack(spacing: 8) {
                        Image(systemName: "lock.fill")
                            .font(.title)
                            .foregroundStyle(.white.opacity(0.9))
                        Text("Unlock to view full plan")
                            .font(.caption.weight(.semibold))
                            .foregroundStyle(.white.opacity(0.7))
                    }
                    .padding()
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .background(Color.black.opacity(0.55))
                    .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
                }
            }
        } footer: {
            OnboardingPrimaryButton(title: "Reveal My Plan", action: store.advance)
        }
    }

    private var resultsSubtitle: String {
        "Unlock to reveal calories, macros, and your full projection."
    }

    private var onboardingPhotoCard: some View {
        VStack(spacing: 12) {
            if let image = store.bodyPhoto {
                Image(uiImage: image)
                    .resizable()
                    .scaledToFit()
                    .frame(maxWidth: .infinity)
                    .frame(maxHeight: 280)
                    .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
            }

            Text(bodyFatCaption)
                .font(.title3.weight(.bold))
                .foregroundStyle(.white)
                .blur(radius: 10)
                .overlay {
                    RoundedRectangle(cornerRadius: 6)
                        .fill(Color.white.opacity(0.12))
                        .frame(height: 28)
                        .padding(.horizontal, 24)
                }
                .accessibilityLabel("Body fat percentage hidden until unlock")
        }
        .frame(maxWidth: .infinity)
    }

    private var reachGoalBanner: some View {
        OnboardingGlassCard {
            VStack(alignment: .leading, spacing: 8) {
                Text("You can reach")
                    .font(.subheadline)
                    .foregroundStyle(.white.opacity(0.65))
                VStack(alignment: .leading, spacing: 6) {
                    HStack(alignment: .firstTextBaseline, spacing: 6) {
                        Text(goalPercentText)
                            .font(.title.weight(.bold))
                            .foregroundStyle(OnboardingTheme.accentGradient)
                        Text("body fat at")
                            .font(.title3.weight(.semibold))
                            .foregroundStyle(.white)
                        Text("██")
                            .font(.title.weight(.bold))
                            .foregroundStyle(.white)
                            .blur(radius: 12)
                            .overlay {
                                RoundedRectangle(cornerRadius: 4)
                                    .fill(Color.white.opacity(0.1))
                                    .frame(width: 40, height: 28)
                            }
                        Text("kg")
                            .font(.title3.weight(.semibold))
                            .foregroundStyle(.white)
                    }
                    HStack(alignment: .firstTextBaseline, spacing: 6) {
                        Text("in")
                            .font(.title3.weight(.semibold))
                            .foregroundStyle(.white.opacity(0.65))
                        Text("███")
                            .font(.title.weight(.bold))
                            .foregroundStyle(.white)
                            .blur(radius: 12)
                            .overlay {
                                RoundedRectangle(cornerRadius: 4)
                                    .fill(Color.white.opacity(0.1))
                                    .frame(width: 52, height: 28)
                            }
                        Text("days")
                            .font(.title3.weight(.semibold))
                            .foregroundStyle(.white)
                    }
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
    }

    private var transformationChart: some View {
        OnboardingGlassCard {
            VStack(alignment: .leading, spacing: 12) {
                Text("Body fat projection")
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(.white.opacity(0.7))

                Chart(projectionPoints) { point in
                    AreaMark(
                        x: .value("Week", point.week),
                        y: .value("BF%", point.value)
                    )
                    .foregroundStyle(
                        LinearGradient(
                            colors: [OnboardingTheme.accent.opacity(0.4), .clear],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    )
                    LineMark(
                        x: .value("Week", point.week),
                        y: .value("BF%", point.value)
                    )
                    .foregroundStyle(OnboardingTheme.accentGradient)
                    .lineStyle(StrokeStyle(lineWidth: 3, lineCap: .round))
                }
                .chartXAxis {
                    AxisMarks(values: .automatic) { _ in
                        AxisValueLabel().foregroundStyle(.white.opacity(0.45))
                    }
                }
                .chartYAxis {
                    AxisMarks { _ in
                        AxisValueLabel().foregroundStyle(.white.opacity(0.45))
                    }
                }
                .frame(height: 160)
                .blur(radius: 14)
                .overlay {
                    ZStack {
                        Color.black.opacity(0.35)
                        Image(systemName: "lock.fill")
                            .font(.title2)
                            .foregroundStyle(.white.opacity(0.5))
                    }
                }
            }
        }
    }

    private var projectionPoints: [ProjectionPoint] {
        let start = plan?.currentBodyFatPercent ?? 17.8
        let end = plan?.goalBodyFatPercent ?? store.goalBodyFatPercent
        let weeks = plan?.weeksToGoal ?? store.goalWeeks
        return (0...weeks).map { week in
            let t = Double(week) / Double(max(weeks, 1))
            return ProjectionPoint(week: week, value: start + (end - start) * t)
        }
    }

    private func planRow(icon: String, text: String) -> some View {
        HStack(spacing: 10) {
            Image(systemName: icon)
                .foregroundStyle(OnboardingTheme.accent)
                .frame(width: 22)
            Text(text)
                .font(.subheadline)
                .foregroundStyle(.white.opacity(0.75))
        }
    }
}

private struct ProjectionPoint: Identifiable {
    let id = UUID()
    let week: Int
    let value: Double
}

#Preview {
    LockedResultsView(store: OnboardingStore.previewWithResults)
}
