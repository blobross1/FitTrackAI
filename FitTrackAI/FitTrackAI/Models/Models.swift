import Foundation
import SwiftUI

struct ProgressPhoto: Identifiable, Codable {
    let id: UUID
    var photoData: Data?
    /// Raw LLM range before normalization
    var aiBodyFatLow: Double
    var aiBodyFatHigh: Double
    /// Normalized estimate: -1.67 + 0.765 * avg + 0.0406 * avg² (avg = mean of LLM low/high)
    var bodyFatPercent: Double
    var weight: Double?
    var aiFeedback: String
    var createdAt: Date
}

struct WeightLog: Identifiable, Codable {
    let id: UUID
    var weight: Double
    var date: Date
}

struct Exercise: Identifiable, Codable {
    let id: UUID
    var name: String
    var category: ExerciseCategory
    var lastWeight: Double?
    var lastReps: Int?
    var isBodyweight: Bool
    var bestOneRM: Double?
    var order: Int

    enum ExerciseCategory: String, Codable, CaseIterable {
        case push = "Push"
        case pull = "Pull"
        case legs = "Legs"
        case core = "Core"
        case other = "Other"

        var color: Color {
            switch self {
            case .push: return AppTheme.push
            case .pull: return AppTheme.pull
            case .legs: return AppTheme.legs
            case .core: return .yellow
            case .other: return .gray
            }
        }
    }
}

struct ExerciseLog: Identifiable, Codable {
    let id: UUID
    var exerciseId: UUID
    var exerciseName: String
    var weight: Double?
    var reps: Int
    var oneRM: Double
    var date: Date
}

struct BodyFatAnalysis {
    var bodyFatLow: Double
    var bodyFatHigh: Double
    var feedback: String
}

struct StrengthInfo {
    var level: String
    var nextLevel: String
    var needed: Double?
}
