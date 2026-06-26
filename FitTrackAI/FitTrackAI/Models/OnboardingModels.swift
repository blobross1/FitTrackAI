import Foundation

enum OnboardingStep: Int, CaseIterable {
    case goal = 0
    case timeline = 1
    case frequency = 2
    case bodyScan = 3
    case lockedResults = 4
    case paywall = 5

    var progressIndex: Int { rawValue + 1 }
    static var totalSteps: Int { 5 }
}

enum BodyFatGoalRange: String, CaseIterable, Identifiable {
    case eightToTen = "8–10%"
    case tenToTwelve = "10–12%"
    case twelveToFifteen = "12–15%"
    case fifteenToEighteen = "15–18%"
    case custom = "Custom"

    var id: String { rawValue }

    var midpointPercent: Double {
        switch self {
        case .eightToTen: return 9
        case .tenToTwelve: return 11
        case .twelveToFifteen: return 13.5
        case .fifteenToEighteen: return 16.5
        case .custom: return 12
        }
    }

    var subtitle: String {
        switch self {
        case .eightToTen: return "Competition lean"
        case .tenToTwelve: return "Athletic & defined"
        case .twelveToFifteen: return "Lean & sustainable"
        case .fifteenToEighteen: return "Healthy recomp"
        case .custom: return "Set your own target"
        }
    }
}

enum SubscriptionPlan: String, CaseIterable, Identifiable {
    case monthly
    case yearly

    var id: String { rawValue }

    var title: String {
        switch self {
        case .monthly: return "Monthly"
        case .yearly: return "Yearly"
        }
    }

    var price: String {
        switch self {
        case .monthly: return "$9.99"
        case .yearly: return "$59.99"
        }
    }

    var period: String {
        switch self {
        case .monthly: return "/ month"
        case .yearly: return "/ year"
        }
    }

    var savingsBadge: String? {
        switch self {
        case .monthly: return nil
        case .yearly: return "Best Value"
        }
    }

    var perMonthEquivalent: String? {
        switch self {
        case .monthly: return nil
        case .yearly: return "$4.99/mo"
        }
    }
}

struct TransformationPlan {
    let currentBodyFatPercent: Double
    let goalBodyFatPercent: Double
    let currentWeightKg: Double
    let goalWeightKg: Double
    let calorieTarget: Int
    let daysToGoal: Int
    let weeksToGoal: Int
    let proteinGrams: Int
    let weightToLoseKg: Double
}
