import Foundation

struct UserGoals: Codable, Equatable {
    var sex: NutritionCalculator.BiologicalSex
    var age: Int
    var heightCm: Double
    var weightKg: Double
    var goalBodyFatPercent: Double
    var goalWeeks: Int
    var timelineWasSkipped: Bool
    var workoutsPerWeek: Int
    var currentBodyFatPercent: Double?
    var goalWeightKg: Double?
    var dailyCalorieTarget: Int?
    var daysToGoal: Int?
    var proteinGrams: Int?

    static let `default` = UserGoals(
        sex: .male,
        age: 30,
        heightCm: 175,
        weightKg: 75,
        goalBodyFatPercent: 12,
        goalWeeks: 8,
        timelineWasSkipped: false,
        workoutsPerWeek: 4,
        currentBodyFatPercent: nil,
        goalWeightKg: nil,
        dailyCalorieTarget: nil,
        daysToGoal: nil,
        proteinGrams: nil
    )

    func nutritionInput(currentBF: Double) -> NutritionCalculator.Input {
        NutritionCalculator.Input(
            sex: sex,
            age: age,
            heightCm: heightCm,
            weightKg: weightKg,
            currentBodyFatPercent: currentBF,
            goalBodyFatPercent: goalBodyFatPercent,
            goalWeeks: goalWeeks,
            workoutsPerWeek: workoutsPerWeek
        )
    }

    mutating func apply(plan: NutritionCalculator.Plan) {
        currentBodyFatPercent = plan.currentBodyFatPercent
        goalWeightKg = plan.targetWeightKg
        weightKg = plan.currentWeightKg
        dailyCalorieTarget = plan.dailyCalorieTarget
        daysToGoal = plan.daysToGoal
        proteinGrams = plan.proteinGrams
        goalBodyFatPercent = plan.goalBodyFatPercent
        goalWeeks = plan.weeksToGoal
    }
}
