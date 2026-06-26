import Foundation
import SwiftUI

@MainActor
final class AppDataStore: ObservableObject {
    static let shared = AppDataStore()

    @Published var progressPhotos: [ProgressPhoto] = []
    @Published var weightLogs: [WeightLog] = []
    @Published var userGoals: UserGoals = .default

    private let analysisAPI = BackendAnalysisService()
    private let persistence = PersistenceService()
    private var didLoad = false

    private init() {}

    func loadIfNeeded() {
        guard !didLoad else { return }
        didLoad = true

        if let snapshot = persistence.load() {
            progressPhotos = snapshot.progressPhotos
            weightLogs = snapshot.weightLogs
            if let goals = snapshot.userGoals {
                userGoals = goals
            }
            if !progressPhotos.isEmpty {
                syncGoalsWithRecentBodyFat()
            }
        }

        persist()
    }

    func updateUserGoals(_ goals: UserGoals) {
        userGoals = goals
        persist()
    }

    /// Mean body fat % from progress photos in the last `days` (default 7). Falls back to stored goal value.
    func averageBodyFatPercent(lastDays: Int = 7, asOf date: Date = Date()) -> Double? {
        let calendar = Calendar.current
        guard let cutoff = calendar.date(byAdding: .day, value: -lastDays, to: date) else {
            return userGoals.currentBodyFatPercent
        }
        let recent = progressPhotos.filter { $0.createdAt >= cutoff }
        if recent.isEmpty {
            return userGoals.currentBodyFatPercent
        }
        let sum = recent.reduce(0.0) { $0 + $1.bodyFatPercent }
        return sum / Double(recent.count)
    }

    func syncGoalsWithRecentBodyFat() {
        guard let average = averageBodyFatPercent() else { return }
        var goals = userGoals
        goals.currentBodyFatPercent = average
        let plan = NutritionCalculator.buildPlan(from: goals.nutritionInput(currentBF: average))
        goals.apply(plan: plan)
        userGoals = goals
        persist()
    }

    func recalculatePlan(currentBodyFatPercent: Double? = nil) -> NutritionCalculator.Plan {
        let bf = currentBodyFatPercent ?? averageBodyFatPercent() ?? 17.8
        var goals = userGoals
        let plan = NutritionCalculator.buildPlan(from: goals.nutritionInput(currentBF: bf))
        goals.apply(plan: plan)
        userGoals = goals
        persist()
        return plan
    }

    func analyzeBodyFat(imageData: Data, weight: Double?) async throws -> BodyFatAnalysis {
        try await analysisAPI.analyzeBodyFat(imageData: imageData, weightKg: weight)
    }

    func saveProgressPhoto(_ photo: ProgressPhoto) {
        progressPhotos.insert(photo, at: 0)
        if let weight = photo.weight {
            logWeight(weight, on: photo.createdAt)
        }
        userGoals.weightKg = photo.weight ?? userGoals.weightKg
        syncGoalsWithRecentBodyFat()
    }

    func logWeight(_ weight: Double, on date: Date = Date()) {
        let log = WeightLog(id: UUID(), weight: weight, date: date)
        weightLogs.append(log)
        weightLogs.sort { $0.date < $1.date }
        userGoals.weightKg = weight
        syncGoalsWithRecentBodyFat()
    }

    private func persist() {
        persistence.save(
            AppSnapshot(
                progressPhotos: progressPhotos,
                weightLogs: weightLogs,
                userGoals: userGoals
            )
        )
    }
}

private struct AppSnapshot: Codable {
    var progressPhotos: [ProgressPhoto]
    var weightLogs: [WeightLog]
    var userGoals: UserGoals?
    var exercises: [Exercise]?
    var exerciseLogs: [ExerciseLog]?
}

private struct PersistenceService {
    private var fileURL: URL {
        let base = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask)[0]
            .appendingPathComponent("FitTrackAI", isDirectory: true)
        try? FileManager.default.createDirectory(at: base, withIntermediateDirectories: true)
        return base.appendingPathComponent("app_data.json")
    }

    func load() -> AppSnapshot? {
        guard FileManager.default.fileExists(atPath: fileURL.path) else { return nil }
        guard let data = try? Data(contentsOf: fileURL) else { return nil }
        return try? JSONDecoder().decode(AppSnapshot.self, from: data)
    }

    func save(_ snapshot: AppSnapshot) {
        guard let data = try? JSONEncoder().encode(snapshot) else { return }
        try? data.write(to: fileURL, options: .atomic)
    }
}
