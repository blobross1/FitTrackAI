import SwiftUI
import Charts

struct AnalyticsView: View {
    @EnvironmentObject private var store: AppDataStore

    private var weightPoints: [ChartPoint] {
        store.weightLogs
            .sorted { $0.date < $1.date }
            .map { ChartPoint(date: $0.date, value: $0.weight, label: shortDate($0.date)) }
    }

    private var bodyFatPoints: [ChartPoint] {
        store.progressPhotos
            .sorted { $0.createdAt < $1.createdAt }
            .map {
                ChartPoint(
                    date: $0.createdAt,
                    value: $0.bodyFatPercent,
                    label: shortDate($0.createdAt)
                )
            }
    }

    /// Lean body mass (kg) = weight × (1 − body fat % / 100) for dates with both measurements.
    private var leanBodyMassPoints: [ChartPoint] {
        let calendar = Calendar.current
        return store.progressPhotos
            .sorted { $0.createdAt < $1.createdAt }
            .compactMap { photo -> ChartPoint? in
                guard let weight = weightKg(on: photo.createdAt, photoWeight: photo.weight, calendar: calendar) else {
                    return nil
                }
                let leanMass = weight * (1 - photo.bodyFatPercent / 100)
                return ChartPoint(
                    date: photo.createdAt,
                    value: leanMass,
                    label: shortDate(photo.createdAt)
                )
            }
    }

    var body: some View {
        NavigationStack {
            ZStack {
                PremiumScreenBackground()
                TabScreenScroll {
                VStack(alignment: .leading, spacing: 0) {
                    Text("Analytics")
                        .font(.largeTitle.bold())
                        .foregroundStyle(.white)
                    Text("Track your progress over time")
                        .foregroundStyle(AppTheme.textSecondary)
                        .padding(.bottom, 24)

                    chartCard(
                        title: "Weight (kg)",
                        icon: "scalemass.fill",
                        tint: AppTheme.accent,
                        emptyMessage: "No data yet"
                    ) {
                        if weightPoints.isEmpty {
                            emptyChart
                        } else {
                            Chart(weightPoints) { point in
                                LineMark(
                                    x: .value("Date", point.label),
                                    y: .value("Weight", point.value)
                                )
                                .foregroundStyle(AppTheme.accent)
                                .interpolationMethod(.monotone)
                                PointMark(
                                    x: .value("Date", point.label),
                                    y: .value("Weight", point.value)
                                )
                                .foregroundStyle(AppTheme.accent)
                            }
                            .chartYScale(domain: yDomain(for: weightPoints, padding: 2))
                            .frame(height: 200)
                        }
                    }

                    chartCard(
                        title: "Body Fat %",
                        icon: "percent",
                        tint: AppTheme.accentSecondary,
                        emptyMessage: "No data yet"
                    ) {
                        if bodyFatPoints.isEmpty {
                            emptyChart
                        } else {
                            Chart(bodyFatPoints) { point in
                                LineMark(
                                    x: .value("Date", point.label),
                                    y: .value("Body Fat", point.value)
                                )
                                .foregroundStyle(AppTheme.accentSecondary)
                                .interpolationMethod(.monotone)
                                PointMark(
                                    x: .value("Date", point.label),
                                    y: .value("Body Fat", point.value)
                                )
                                .foregroundStyle(AppTheme.accentSecondary)
                            }
                            .chartYScale(domain: yDomain(for: bodyFatPoints, padding: 2))
                            .frame(height: 200)
                        }
                    }

                    chartCard(
                        title: "Lean Body Mass (kg)",
                        icon: "figure.strengthtraining.traditional",
                        tint: AppTheme.legs,
                        emptyMessage: "Add weight and body fat on the same day to see lean mass"
                    ) {
                        if leanBodyMassPoints.isEmpty {
                            emptyChart
                        } else {
                            Chart(leanBodyMassPoints) { point in
                                LineMark(
                                    x: .value("Date", point.label),
                                    y: .value("Lean Mass", point.value)
                                )
                                .foregroundStyle(AppTheme.legs)
                                .interpolationMethod(.monotone)
                                PointMark(
                                    x: .value("Date", point.label),
                                    y: .value("Lean Mass", point.value)
                                )
                                .foregroundStyle(AppTheme.legs)
                            }
                            .chartYScale(domain: yDomain(for: leanBodyMassPoints, padding: 2))
                            .frame(height: 200)
                        }
                    }
                }
                }
            }
            .navigationBarHidden(true)
        }
    }

    @ViewBuilder
    private func chartCard<Content: View>(
        title: String,
        icon: String,
        tint: Color,
        emptyMessage: String,
        @ViewBuilder content: () -> Content
    ) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 12) {
                Image(systemName: icon)
                    .foregroundStyle(tint)
                    .padding(8)
                    .background(tint.opacity(0.2))
                    .clipShape(RoundedRectangle(cornerRadius: 8))
                Text(title)
                    .font(.headline)
                    .foregroundStyle(.white)
            }
            content()
        }
        .padding(16)
        .background(AppTheme.card)
        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .stroke(AppTheme.glassStroke, lineWidth: 1)
        }
        .padding(.bottom, 24)
    }

    private var emptyChart: some View {
        Text("No data yet")
            .foregroundStyle(AppTheme.textSecondary)
            .frame(maxWidth: .infinity, minHeight: 128)
    }

    private func shortDate(_ date: Date) -> String {
        let f = DateFormatter()
        f.dateFormat = "MMM d"
        return f.string(from: date)
    }

    private func weightKg(on date: Date, photoWeight: Double?, calendar: Calendar) -> Double? {
        if let photoWeight { return photoWeight }
        return store.weightLogs
            .first { calendar.isDate($0.date, inSameDayAs: date) }
            .map(\.weight)
    }

    private func yDomain(for points: [ChartPoint], padding: Double) -> ClosedRange<Double> {
        let values = points.map(\.value)
        let minV = (values.min() ?? 0) - padding
        let maxV = (values.max() ?? 100) + padding
        return minV...maxV
    }
}

private struct ChartPoint: Identifiable {
    let id = UUID()
    let date: Date
    let value: Double
    let label: String
}

#Preview {
    AnalyticsView()
        .environmentObject(AppDataStore.shared)
}
