/**
 * Builds the LLM prompt for progress photo body fat analysis.
 */
export function buildBodyFatAnalysisPrompt(weightKg) {
    const weightLine = weightKg
        ? `\n\nThe person weighs ${weightKg} kg.`
        : '';

    return `Analyze this progress photo and estimate body fat percentage. Be honest and give a realistic range.${weightLine}

Consider visible muscle definition, fat distribution, and overall physique. Give a realistic body fat percentage range (low and high estimate, typically 2-3% apart).

Also provide brief, constructive feedback about their current physique - what looks good and what could be improved. Be supportive but honest.`;
}

/**
 * Averages the LLM low/high range, then normalizes:
 *   avg = (rawLow + rawHigh) / 2
 *   estimate = -1.67 + 0.765 * avg + 0.0406 * avg²
 */
export function normalizeBodyFatEstimate(rawLow, rawHigh) {
    const avg = (rawLow + rawHigh) / 2;
    const estimate = -1.67 + 0.765 * avg + 0.0406 * avg * avg;
    return Math.round(estimate * 10) / 10;
}
