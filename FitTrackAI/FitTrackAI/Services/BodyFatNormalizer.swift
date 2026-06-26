import Foundation

enum BodyFatNormalizer {
    static func analysisPrompt(weightKg: Double?) -> String {
        let weightLine = weightKg.map { "\n\nThe person weighs \($0) kg." } ?? ""
        return """
            Analyze this progress photo and estimate body fat percentage. Be honest and give a realistic range.\(weightLine)

            Consider visible muscle definition, fat distribution, and overall physique. Give a realistic body fat percentage range (low and high estimate, typically 2-3% apart).

            Also provide brief, constructive feedback about their current physique - what looks good and what could be improved. Be supportive but honest.
            """
    }

    /// Averages LLM low/high, then applies calibration: estimate = -1.67 + 0.765×avg + 0.0406×avg²
    /// Example: raw 16.5–19.1% (avg 17.8) → **24.8%** displayed. Compare "AI estimate (raw)" in results.
    static func normalizedEstimate(rawLow: Double, rawHigh: Double) -> Double {
        let avg = (rawLow + rawHigh) / 2
        let estimate = -1.67 + 0.765 * avg + 0.0406 * avg * avg
        return round1(estimate)
    }

    private static func round1(_ value: Double) -> Double {
        (value * 10).rounded() / 10
    }
}
