import Foundation

/// Mifflin–St Jeor BMR + LBM-based fat loss pacing (~7,700 kcal per kg body fat).
enum NutritionCalculator {
    /// ~7,700 kcal per kg of adipose tissue (≈3,500 kcal/lb).
    static let kcalPerKgFat: Double = 7_700

    enum BiologicalSex: String, CaseIterable, Codable, Identifiable {
        case male
        case female

        var id: String { rawValue }

        var displayName: String {
            switch self {
            case .male: return "Male"
            case .female: return "Female"
            }
        }
    }

    struct Input {
        var sex: BiologicalSex
        var age: Int
        var heightCm: Double
        var weightKg: Double
        var currentBodyFatPercent: Double
        var goalBodyFatPercent: Double
        var goalWeeks: Int
        var workoutsPerWeek: Int
    }

    struct Plan {
        var currentBodyFatPercent: Double
        var goalBodyFatPercent: Double
        var leanBodyMassKg: Double
        var currentWeightKg: Double
        var targetWeightKg: Double
        var weightToLoseKg: Double
        var bmr: Int
        var tdee: Int
        var dailyCalorieTarget: Int
        var dailyDeficit: Int
        var daysToGoal: Int
        var weeksToGoal: Int
        var proteinGrams: Int
    }

    static func buildPlan(from input: Input) -> Plan {
        let lbm = input.weightKg * (1 - input.currentBodyFatPercent / 100)
        let goalBF = min(max(input.goalBodyFatPercent, 4), 40)
        let targetWeight = lbm / max(1 - goalBF / 100, 0.01)
        let weightToLose = max(0, input.weightKg - targetWeight)

        let weeks = min(max(input.goalWeeks, 1), 52)
        let days = weeks * 7

        let bmrValue = mifflinStJeorBMR(
            sex: input.sex,
            weightKg: input.weightKg,
            heightCm: input.heightCm,
            age: input.age
        )
        let activity = activityMultiplier(workoutsPerWeek: input.workoutsPerWeek)
        let tdeeValue = bmrValue * activity

        let dailyDeficit: Double
        if weightToLose > 0.1 {
            let totalDeficit = weightToLose * kcalPerKgFat
            dailyDeficit = totalDeficit / Double(days)
        } else {
            dailyDeficit = 0
        }

        let dailyTarget = Int((tdeeValue - dailyDeficit).rounded())

        let protein = Int((lbm * 2.2).rounded())

        return Plan(
            currentBodyFatPercent: input.currentBodyFatPercent,
            goalBodyFatPercent: goalBF,
            leanBodyMassKg: round1(lbm),
            currentWeightKg: round1(input.weightKg),
            targetWeightKg: round1(targetWeight),
            weightToLoseKg: round1(weightToLose),
            bmr: Int(bmrValue.rounded()),
            tdee: Int(tdeeValue.rounded()),
            dailyCalorieTarget: dailyTarget,
            dailyDeficit: Int(dailyDeficit.rounded()),
            daysToGoal: days,
            weeksToGoal: weeks,
            proteinGrams: protein
        )
    }

    /// Mifflin–St Jeor (1990) — widely used for modern BMR estimates.
    static func mifflinStJeorBMR(sex: BiologicalSex, weightKg: Double, heightCm: Double, age: Int) -> Double {
        let base = 10 * weightKg + 6.25 * heightCm - 5 * Double(age)
        switch sex {
        case .male: return base + 5
        case .female: return base - 161
        }
    }

    static func activityMultiplier(workoutsPerWeek: Int) -> Double {
        switch workoutsPerWeek {
        case 0: return 1.2
        case 1, 2: return 1.375
        case 3, 4: return 1.55
        case 5, 6: return 1.725
        default: return 1.9
        }
    }

    private static func round1(_ value: Double) -> Double {
        (value * 10).rounded() / 10
    }
}
