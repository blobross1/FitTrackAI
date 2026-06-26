import SwiftUI
import UIKit

@MainActor
final class OnboardingStore: ObservableObject {
    static let shared = OnboardingStore()

    private let completedKey = "fittrack_onboarding_completed"

    @Published var step: OnboardingStep = .goal
    @Published var goalRange: BodyFatGoalRange?
    @Published var customGoalPercent: Double = 12
    @Published var goalWeeks: Int = 8
    @Published var timelineWasSkipped = false
    @Published var workoutsPerWeek: Int = 4
    @Published var biologicalSex: NutritionCalculator.BiologicalSex = .male
    @Published var age: Int = 30
    @Published var heightText = ""
    @Published var bodyPhoto: UIImage?
    @Published var weightText = ""
    @Published var isScanning = false
    @Published var scanProgress: Double = 0
    @Published var scanStatusText = ""
    @Published var scanError: String?
    @Published var transformationPlan: TransformationPlan?
    @Published var selectedPlan: SubscriptionPlan = .yearly
    /// First scan from onboarding; saved to the account when analysis finishes.
    @Published private(set) var onboardingProgressPhoto: ProgressPhoto?
    @Published private(set) var hasCompletedOnboarding: Bool

    private init() {
        hasCompletedOnboarding = UserDefaults.standard.bool(forKey: completedKey)
    }

    var goalBodyFatPercent: Double {
        if goalRange == .custom { return customGoalPercent }
        return goalRange?.midpointPercent ?? 12
    }

    var scannedBodyFatPercent: Double? {
        transformationPlan?.currentBodyFatPercent ?? onboardingProgressPhoto?.bodyFatPercent
    }

    var canContinueFromGoal: Bool {
        goalRange != nil && (goalRange != .custom || (8...25).contains(customGoalPercent))
    }

    var canContinueFromTimeline: Bool { true }
    var canContinueFromFrequency: Bool { workoutsPerWeek >= 0 }
    var canContinueFromBodyScan: Bool { bodyPhoto != nil }

    var parsedWeightKg: Double? {
        let trimmed = weightText.trimmingCharacters(in: .whitespaces)
        guard !trimmed.isEmpty else { return nil }
        return Double(trimmed.replacingOccurrences(of: ",", with: "."))
    }

    var parsedHeightCm: Double? {
        let trimmed = heightText.trimmingCharacters(in: .whitespaces)
        guard !trimmed.isEmpty else { return nil }
        return Double(trimmed.replacingOccurrences(of: ",", with: "."))
    }

    func skipTimeline() {
        timelineWasSkipped = true
        goalWeeks = 8
    }

    func advance() {
        guard let next = OnboardingStep(rawValue: step.rawValue + 1) else { return }
        withAnimation(.spring(response: 0.45, dampingFraction: 0.86)) {
            step = next
        }
    }

    func goBack() {
        guard let prev = OnboardingStep(rawValue: step.rawValue - 1) else { return }
        withAnimation(.spring(response: 0.45, dampingFraction: 0.86)) {
            step = prev
        }
    }

    func runBodyScan() async {
        guard let image = bodyPhoto,
              let imageData = ImagePreprocessor.jpegForAPI(from: image) else { return }

        isScanning = true
        scanProgress = 0
        scanError = nil
        transformationPlan = nil
        onboardingProgressPhoto = nil

        let steps = [
            "Analyzing physique…",
            "Mapping muscle definition…",
            "Estimating body composition…",
            "Calculating calorie targets…",
            "Finalizing your plan…"
        ]

        let progressTask = Task { @MainActor in
            let duration: TimeInterval = 4.5
            let start = Date()
            let stepDuration = duration / Double(steps.count)
            while !Task.isCancelled {
                let elapsed = Date().timeIntervalSince(start)
                if elapsed >= duration { break }
                scanProgress = min((elapsed / duration) * 100, 92)
                let stepIndex = min(Int(elapsed / stepDuration), steps.count - 1)
                scanStatusText = steps[stepIndex]
                try? await Task.sleep(nanoseconds: 16_000_000)
            }
        }

        let weight = parsedWeightKg

        do {
            guard AppConfig.hasValidBackend else {
                throw BackendError.notConfigured
            }
            let analysis = try await AppDataStore.shared.analyzeBodyFat(imageData: imageData, weight: weight)

            let bodyFatPercent = BodyFatNormalizer.normalizedEstimate(
                rawLow: analysis.bodyFatLow,
                rawHigh: analysis.bodyFatHigh
            )

            progressTask.cancel()
            scanProgress = 100
            scanStatusText = steps[steps.count - 1]

            let photo = ProgressPhoto(
                id: UUID(),
                photoData: imageData,
                aiBodyFatLow: analysis.bodyFatLow,
                aiBodyFatHigh: analysis.bodyFatHigh,
                bodyFatPercent: bodyFatPercent,
                weight: weight,
                aiFeedback: analysis.feedback,
                createdAt: Date()
            )
            onboardingProgressPhoto = photo
            AppDataStore.shared.saveProgressPhoto(photo)

            let plan = buildNutritionPlan(currentBodyFatPercent: bodyFatPercent)
            transformationPlan = TransformationPlan(
                currentBodyFatPercent: plan.currentBodyFatPercent,
                goalBodyFatPercent: plan.goalBodyFatPercent,
                currentWeightKg: plan.currentWeightKg,
                goalWeightKg: plan.targetWeightKg,
                calorieTarget: plan.dailyCalorieTarget,
                daysToGoal: plan.daysToGoal,
                weeksToGoal: plan.weeksToGoal,
                proteinGrams: plan.proteinGrams,
                weightToLoseKg: plan.weightToLoseKg
            )

            advance()
        } catch {
            progressTask.cancel()
            scanError = error.localizedDescription
        }

        isScanning = false
    }

    func buildNutritionPlan(currentBodyFatPercent: Double) -> NutritionCalculator.Plan {
        let weight = parsedWeightKg ?? 75
        let height = parsedHeightCm ?? 175

        return NutritionCalculator.buildPlan(
            from: NutritionCalculator.Input(
                sex: biologicalSex,
                age: age,
                heightCm: height,
                weightKg: weight,
                currentBodyFatPercent: currentBodyFatPercent,
                goalBodyFatPercent: goalBodyFatPercent,
                goalWeeks: goalWeeks,
                workoutsPerWeek: workoutsPerWeek
            )
        )
    }

    func makeUserGoals(currentBodyFatPercent: Double?) -> UserGoals {
        var goals = UserGoals.default
        goals.sex = biologicalSex
        goals.age = age
        goals.heightCm = parsedHeightCm ?? 175
        goals.weightKg = parsedWeightKg ?? AppDataStore.shared.userGoals.weightKg
        goals.goalBodyFatPercent = goalBodyFatPercent
        goals.goalWeeks = goalWeeks
        goals.timelineWasSkipped = timelineWasSkipped
        goals.workoutsPerWeek = workoutsPerWeek

        let bf = currentBodyFatPercent
            ?? onboardingProgressPhoto?.bodyFatPercent
            ?? transformationPlan?.currentBodyFatPercent

        if let bf {
            if let plan = transformationPlan {
                goals.currentBodyFatPercent = bf
                goals.weightKg = plan.currentWeightKg
                goals.goalWeightKg = plan.goalWeightKg
                goals.dailyCalorieTarget = plan.calorieTarget
                goals.daysToGoal = plan.daysToGoal
                goals.proteinGrams = plan.proteinGrams
            } else {
                let plan = buildNutritionPlan(currentBodyFatPercent: bf)
                goals.apply(plan: plan)
            }
        }
        return goals
    }

    func completeOnboarding() {
        let bf = onboardingProgressPhoto?.bodyFatPercent ?? transformationPlan?.currentBodyFatPercent
        let goals = makeUserGoals(currentBodyFatPercent: bf)
        AppDataStore.shared.updateUserGoals(goals)
        UserDefaults.standard.set(true, forKey: completedKey)
        hasCompletedOnboarding = true
    }

    func resetOnboarding() {
        UserDefaults.standard.set(false, forKey: completedKey)
        hasCompletedOnboarding = false
        resetForPreview()
    }

    static var previewWithResults: OnboardingStore {
        let store = OnboardingStore.shared
        store.goalRange = .twelveToFifteen
        store.goalWeeks = 10
        store.transformationPlan = TransformationPlan(
            currentBodyFatPercent: 17.8,
            goalBodyFatPercent: 12,
            currentWeightKg: 78,
            goalWeightKg: 72.8,
            calorieTarget: 2_140,
            daysToGoal: 70,
            weeksToGoal: 10,
            proteinGrams: 132,
            weightToLoseKg: 5.2
        )
        store.step = .lockedResults
        return store
    }

    func resetForPreview() {
        UserDefaults.standard.set(false, forKey: completedKey)
        hasCompletedOnboarding = false
        step = .goal
        goalRange = nil
        customGoalPercent = 12
        goalWeeks = 8
        timelineWasSkipped = false
        workoutsPerWeek = 4
        biologicalSex = .male
        age = 30
        heightText = ""
        bodyPhoto = nil
        weightText = ""
        isScanning = false
        scanProgress = 0
        scanError = nil
        transformationPlan = nil
        onboardingProgressPhoto = nil
        selectedPlan = .yearly
    }

}
