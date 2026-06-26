import SwiftUI

struct AccountView: View {
    @EnvironmentObject private var store: AppDataStore
    @State private var draft: UserGoals = .default
    @State private var savedMessage: String?

    private var currentBF: Double {
        store.averageBodyFatPercent() ?? store.userGoals.currentBodyFatPercent ?? 17.8
    }

    private var bodyFatSampleCount: Int {
        let calendar = Calendar.current
        guard let cutoff = calendar.date(byAdding: .day, value: -7, to: Date()) else { return 0 }
        return store.progressPhotos.filter { $0.createdAt >= cutoff }.count
    }

    var body: some View {
        NavigationStack {
            ZStack {
                PremiumScreenBackground()
                TabScreenScroll {
                    VStack(alignment: .leading, spacing: 20) {
                        header
                        bodyStatsSection
                        goalSection
                        timelineSection
                        workoutSection
                        if let calories = draft.dailyCalorieTarget {
                            planSummary(calories: calories)
                        }
                        saveButton
                        replayOnboardingButton
                    }
                }
            }
            .navigationBarHidden(true)
            .onAppear {
                store.syncGoalsWithRecentBodyFat()
                draft = store.userGoals
            }
        }
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text("Account")
                .font(.largeTitle.bold())
                .foregroundStyle(AppTheme.textPrimary)
            Text("Update your stats and transformation goals")
                .font(.subheadline)
                .foregroundStyle(AppTheme.textSecondary)
        }
    }

    private var bodyStatsSection: some View {
        glassSection(title: "Body stats", icon: "person.fill") {
            Picker("Sex", selection: $draft.sex) {
                ForEach(NutritionCalculator.BiologicalSex.allCases) { sex in
                    Text(sex.displayName).tag(sex)
                }
            }
            .pickerStyle(.segmented)

            HStack(spacing: 12) {
                numberField(label: "Weight (kg)", value: $draft.weightKg)
                numberField(label: "Height (cm)", value: $draft.heightCm)
            }

            VStack(alignment: .leading, spacing: 6) {
                HStack {
                    Text("Age")
                        .font(.subheadline)
                        .foregroundStyle(AppTheme.textSecondary)
                    Spacer()
                    Text("\(draft.age)")
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(AppTheme.accentSecondary)
                }
                Slider(
                    value: Binding(
                        get: { Double(draft.age) },
                        set: { draft.age = Int($0.rounded()) }
                    ),
                    in: 16...75,
                    step: 1
                )
                .tint(AppTheme.accent)
            }
        }
    }

    private var goalSection: some View {
        glassSection(title: "Body fat goal", icon: "target") {
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Text(String(format: "%.1f%%", draft.goalBodyFatPercent))
                        .font(.title2.weight(.bold))
                        .foregroundStyle(AppTheme.accentGradient)
                    Spacer()
                }
                Slider(value: $draft.goalBodyFatPercent, in: 8...22, step: 0.5)
                    .tint(AppTheme.accent)
                HStack {
                    Text("8%")
                    Spacer()
                    Text("22%")
                }
                .font(.caption)
                .foregroundStyle(AppTheme.textSecondary)
            }
        }
    }

    private var timelineSection: some View {
        glassSection(title: "Timeline", icon: "calendar") {
            VStack(spacing: 8) {
                Text("\(draft.goalWeeks) weeks")
                    .font(.title2.weight(.bold))
                    .foregroundStyle(.white)
                Slider(
                    value: Binding(
                        get: { Double(draft.goalWeeks) },
                        set: { draft.goalWeeks = Int($0.rounded()) }
                    ),
                    in: 1...12,
                    step: 1
                )
                .tint(AppTheme.accent)
            }
        }
    }

    private var workoutSection: some View {
        glassSection(title: "Workouts per week", icon: "dumbbell.fill") {
            Stepper("\(draft.workoutsPerWeek) days", value: $draft.workoutsPerWeek, in: 0...7)
                .foregroundStyle(.white)
        }
    }

    private func planSummary(calories: Int) -> some View {
        glassSection(title: "Your plan", icon: "flame.fill") {
            VStack(alignment: .leading, spacing: 10) {
                summaryRow("Daily calories", "\(calories) kcal")
                if let protein = draft.proteinGrams {
                    summaryRow("Protein", "\(protein) g")
                }
                if let goalKg = draft.goalWeightKg {
                    summaryRow("Goal weight", String(format: "%.1f kg", goalKg))
                }
                summaryRow("Current weight", String(format: "%.1f kg", draft.weightKg))
                if let days = draft.daysToGoal {
                    summaryRow("Days to goal", "\(days)")
                }
                if let bf = draft.currentBodyFatPercent {
                    let label = bodyFatSampleCount > 0
                        ? "Current body fat (7-day avg, \(bodyFatSampleCount) scan\(bodyFatSampleCount == 1 ? "" : "s"))"
                        : "Current body fat"
                    summaryRow(label, String(format: "%.1f%%", bf))
                }
            }
        }
    }

    private func summaryRow(_ label: String, _ value: String) -> some View {
        HStack {
            Text(label)
                .foregroundStyle(AppTheme.textSecondary)
            Spacer()
            Text(value)
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(.white)
        }
    }

    private var saveButton: some View {
        Button {
            var goals = draft
            let plan = NutritionCalculator.buildPlan(from: goals.nutritionInput(currentBF: currentBF))
            goals.apply(plan: plan)
            store.updateUserGoals(goals)
            draft = goals
            savedMessage = "Goals updated"
        } label: {
            Text("Save & recalculate")
                .font(.headline)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 16)
        }
        .buttonStyle(.plain)
        .background(AppTheme.accentGradient)
        .foregroundStyle(.white)
        .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
        .padding(.bottom, 8)
    }

    private var replayOnboardingButton: some View {
        Button {
            OnboardingStore.shared.resetOnboarding()
        } label: {
            Text("Replay onboarding")
                .font(.subheadline.weight(.medium))
                .frame(maxWidth: .infinity)
                .padding(.vertical, 14)
        }
        .buttonStyle(.plain)
        .foregroundStyle(AppTheme.textSecondary)
        .background(AppTheme.card.opacity(0.6))
        .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
    }

    private func glassSection<Content: View>(
        title: String,
        icon: String,
        @ViewBuilder content: () -> Content
    ) -> some View {
        VStack(alignment: .leading, spacing: 14) {
            Label(title, systemImage: icon)
                .font(.headline)
                .foregroundStyle(.white)
            content()
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(AppTheme.card)
        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .stroke(AppTheme.glassStroke, lineWidth: 1)
        }
    }

    private func numberField(label: String, value: Binding<Double>) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(label)
                .font(.caption)
                .foregroundStyle(AppTheme.textSecondary)
            TextField("0", value: value, format: .number.precision(.fractionLength(1)))
                .keyboardType(.decimalPad)
                .font(.body.weight(.semibold))
                .foregroundStyle(.white)
                .padding(12)
                .background(Color.white.opacity(0.06))
                .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
        }
    }
}

#Preview {
    AccountView()
        .environmentObject(AppDataStore.shared)
}
