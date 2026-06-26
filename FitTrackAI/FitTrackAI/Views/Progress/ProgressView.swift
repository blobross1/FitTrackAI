import SwiftUI
import PhotosUI
import UIKit

struct WeightProgressView: View {
    @EnvironmentObject private var store: AppDataStore

    @State private var selectedItem: PhotosPickerItem?
    @State private var previewImage: UIImage?
    @State private var weightText = ""
    @State private var isScanning = false
    @State private var scanningImage: UIImage?
    @State private var scanProgress: Double = 0
    @State private var scanText = ""
    @State private var result: ProgressPhoto?
    @ObservedObject private var subscription = SubscriptionManager.shared
    @State private var showErrorAlert = false
    @State private var errorMessage: String?

    private var lastPhoto: ProgressPhoto? { store.progressPhotos.first }

    var body: some View {
        NavigationStack {
            ZStack {
                PremiumScreenBackground()
                TabScreenScroll {
                    VStack(alignment: .leading, spacing: 20) {
                        header
                        if !isScanning { nutritionPlanCard }
                        photoArea
                        if let result, !isScanning { resultSection(result) }
                        if previewImage != nil, result == nil, !isScanning { optionsSection }
                        if result != nil, !isScanning { anotherPhotoButton }
                        if !store.progressPhotos.isEmpty, !isScanning { previousPhotos }
                    }
                }
            }
            .opacity(isScanning ? 0 : 1)
            .allowsHitTesting(!isScanning)
            .navigationBarHidden(true)
        }
        .fullScreenCover(isPresented: $isScanning, onDismiss: { scanningImage = nil }) {
            Group {
                if let scanningImage {
                    ScanningFullscreenView(
                        uiImage: scanningImage,
                        progress: scanProgress,
                        statusText: scanText
                    )
                } else {
                    ZStack {
                        AppTheme.background.ignoresSafeArea()
                        ProgressView()
                            .tint(AppTheme.accent)
                    }
                }
            }
            .interactiveDismissDisabled()
        }
        .alert("Analysis Failed", isPresented: $showErrorAlert) {
            Button("OK", role: .cancel) {}
        } message: {
            Text(errorMessage ?? "Something went wrong.")
        }
        .onChange(of: selectedItem) { _, newItem in
            Task { await loadImage(from: newItem) }
        }
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text("Body Fat %")
                .font(.largeTitle.bold())
                .foregroundStyle(AppTheme.textPrimary)
            Text("Upload a photo for AI analysis")
                .font(.subheadline)
                .foregroundStyle(AppTheme.textSecondary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    @ViewBuilder
    private var nutritionPlanCard: some View {
        let goals = store.userGoals
        if let calories = goals.dailyCalorieTarget, let days = goals.daysToGoal {
            VStack(alignment: .leading, spacing: 12) {
                Label("Your plan", systemImage: "flame.fill")
                    .font(.headline)
                    .foregroundStyle(AppTheme.accentSecondary)
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("\(calories) kcal / day")
                            .font(.title3.weight(.bold))
                            .foregroundStyle(.white)
                        Text(planSubtitle(goals: goals, days: days))
                            .font(.caption)
                            .foregroundStyle(AppTheme.textSecondary)
                    }
                    Spacer()
                    if let protein = goals.proteinGrams {
                        VStack(alignment: .trailing, spacing: 4) {
                            Text("\(protein)g")
                                .font(.title3.weight(.bold))
                                .foregroundStyle(AppTheme.accent)
                            Text("protein")
                                .font(.caption)
                                .foregroundStyle(AppTheme.textSecondary)
                        }
                    }
                }
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
    }

    private func planSubtitle(goals: UserGoals, days: Int) -> String {
        let bf = goals.goalBodyFatPercent.formatted(.number.precision(.fractionLength(1)))
        if let goalKg = goals.goalWeightKg {
            let kg = goalKg.formatted(.number.precision(.fractionLength(1)))
            return "Goal \(kg) kg · \(bf)% body fat · \(days) days"
        }
        return "Goal \(bf)% body fat · \(days) days"
    }

    private var photoArea: some View {
        PhotoPreviewCard(uiImage: previewImage) {
            HStack(spacing: 12) {
                PhotosPicker(selection: $selectedItem, matching: .images) {
                    pickerButton(icon: "camera.fill", label: "Take Photo")
                }
                PhotosPicker(selection: $selectedItem, matching: .images) {
                    pickerButton(icon: "square.and.arrow.up", label: "Upload")
                }
            }
            .padding(16)
        } overlay: {
            if previewImage != nil, !isScanning {
                Button(action: resetPhoto) {
                    Image(systemName: "xmark")
                        .font(.body.weight(.semibold))
                        .foregroundStyle(.white)
                        .padding(10)
                        .background(.black.opacity(0.5))
                        .clipShape(Circle())
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topTrailing)
                .padding(12)
            }
        }
    }

    private func pickerButton(icon: String, label: String) -> some View {
        VStack(spacing: 8) {
            Image(systemName: icon)
                .font(.system(size: 36))
                .foregroundStyle(AppTheme.accent)
            Text(label)
                .font(.subheadline.weight(.medium))
                .foregroundStyle(.white)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(AppTheme.card)
        .overlay {
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .stroke(AppTheme.glassStroke, lineWidth: 1)
        }
        .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
    }

    private func resultSection(_ photo: ProgressPhoto) -> some View {
        VStack(spacing: 8) {
            VStack(spacing: 4) {
                Text("AI estimate (raw)")
                    .font(.caption)
                    .foregroundStyle(AppTheme.textSecondary)
                Text("\(formatPercent(photo.aiBodyFatLow))–\(formatPercent(photo.aiBodyFatHigh))%")
                    .font(.title3.weight(.semibold))
                    .foregroundStyle(Color(white: 0.75))
            }
            .padding(.bottom, 4)

            Text("Calibrated estimate")
                .font(.subheadline)
                .foregroundStyle(AppTheme.textSecondary)

            HStack(alignment: .firstTextBaseline, spacing: 4) {
                Text(photo.bodyFatPercent, format: .number.precision(.fractionLength(1)))
                    .font(.system(size: 48, weight: .bold))
                    .minimumScaleFactor(0.6)
                    .lineLimit(1)
                Text("%")
                    .font(.title2)
                    .foregroundStyle(.gray)
            }
            .foregroundStyle(.white)

            if let change = bodyFatChange(from: photo) {
                Text("\(change < 0 ? "↓" : "↑") \(abs(change), specifier: "%.1f")% from last")
                    .font(.body.weight(.medium))
                    .foregroundStyle(change < 0 ? .green : Color(red: 1, green: 0.4, blue: 0.4))
            }

            Text(photo.aiFeedback)
                .font(.subheadline)
                .foregroundStyle(Color(white: 0.85))
                .frame(maxWidth: .infinity, alignment: .leading)
                .fixedSize(horizontal: false, vertical: true)
                .padding(16)
                .background(AppTheme.card)
                .clipShape(RoundedRectangle(cornerRadius: 16))
                .padding(.top, 8)
        }
        .multilineTextAlignment(.center)
        .frame(maxWidth: .infinity)
        .padding(.bottom, 20)
    }

    private var optionsSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            VStack(alignment: .leading, spacing: 8) {
                Text("Weight (optional)")
                    .font(.subheadline)
                    .foregroundStyle(AppTheme.textSecondary)
                HStack {
                    TextField("Enter weight", text: $weightText)
                        .keyboardType(.decimalPad)
                        .font(.title3)
                    Text("kg")
                        .foregroundStyle(AppTheme.textSecondary)
                }
                .padding()
                .background(AppTheme.card)
                .clipShape(RoundedRectangle(cornerRadius: 12))
            }

            Button {
                handleAnalyzePhotoTap()
            } label: {
                Text("Analyze Photo")
                    .font(.title3.weight(.semibold))
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 16)
            }
            .buttonStyle(.plain)
            .background(AppTheme.accentGradient)
            .foregroundStyle(.white)
            .clipShape(RoundedRectangle(cornerRadius: 12))
        }
        .frame(maxWidth: .infinity)
        .padding(.bottom, 20)
    }

    private var anotherPhotoButton: some View {
        Button(action: resetPhoto) {
            Text("Take Another Photo")
                .font(.title3.weight(.semibold))
                .frame(maxWidth: .infinity)
                .padding(.vertical, 16)
        }
        .buttonStyle(.plain)
        .background(AppTheme.card)
        .foregroundStyle(.white)
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .padding(.bottom, 20)
    }

    private var previousPhotos: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Previous Photos")
                .font(.subheadline.weight(.medium))
                .foregroundStyle(AppTheme.textSecondary)

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 12) {
                    ForEach(store.progressPhotos) { photo in
                        VStack(spacing: 8) {
                            RoundedRectangle(cornerRadius: 12)
                                .fill(Color(white: 0.15))
                                .frame(width: 88, height: 118)
                                .overlay {
                                    if let data = photo.photoData, let ui = UIImage(data: data) {
                                        Image(uiImage: ui)
                                            .resizable()
                                            .scaledToFill()
                                            .frame(width: 88, height: 118)
                                            .clipped()
                                    } else {
                                        Image(systemName: "person.fill")
                                            .font(.title)
                                            .foregroundStyle(.gray)
                                    }
                                }
                                .clipShape(RoundedRectangle(cornerRadius: 12))

                            Text("\(photo.bodyFatPercent, specifier: "%.1f")%")
                                .font(.caption.weight(.medium))
                                .foregroundStyle(.white)
                            if let w = photo.weight {
                                Text("\(w, specifier: "%.1f") kg")
                                    .font(.caption2)
                                    .foregroundStyle(AppTheme.textSecondary)
                            }
                        }
                    }
                }
                .padding(.vertical, 4)
            }
        }
    }

    private func bodyFatChange(from current: ProgressPhoto) -> Double? {
        let previous = store.progressPhotos.filter { $0.id != current.id }
        guard let last = previous.first else { return nil }
        let diff = current.bodyFatPercent - last.bodyFatPercent
        return abs(diff) < 0.5 ? nil : diff
    }

    private func loadImage(from item: PhotosPickerItem?) async {
        guard let item,
              let data = try? await item.loadTransferable(type: Data.self),
              let image = UIImage(data: data) else { return }
        previewImage = image
        result = nil
    }

    private func handleAnalyzePhotoTap() {
        guard previewImage != nil else {
            errorMessage = "Add a photo before analyzing."
            showErrorAlert = true
            return
        }

        switch subscription.requestBodyFatScan(onAccess: { Task { await analyzePhoto() } }) {
        case .allowed:
            break
        case .paywall:
            break
        case .blocked:
            errorMessage = """
            Analysis is not configured. In FitTrackAI/Secrets.xcconfig set FITTRACK_API_URL and FITTRACK_API_SECRET, then clean build. For testing without subscribing, set BYPASS_PAYWALL = 1.
            """
            showErrorAlert = true
        }
    }

    private func analyzePhoto() async {
        guard let previewImage else { return }

        guard AppConfig.hasValidBackend else {
            await MainActor.run {
                errorMessage = "Analysis server is not configured. Add FITTRACK_API_URL and FITTRACK_API_SECRET to FitTrackAI/Secrets.xcconfig (the file linked in Xcode), then Product → Clean Build Folder."
                showErrorAlert = true
            }
            return
        }

        guard let imageData = ImagePreprocessor.jpegForAPI(from: previewImage) else {
            await MainActor.run {
                errorMessage = "Could not prepare this photo for upload. Try another image or re-select from your library."
                showErrorAlert = true
            }
            return
        }

        await MainActor.run {
            scanningImage = previewImage
            scanProgress = 0
            result = nil
            isScanning = true
        }

        let texts = [
            "Analyzing physique...",
            "Measuring proportions...",
            "Estimating body composition...",
            "Calculating fat distribution...",
            "Finalizing estimate..."
        ]

        let progressTask = Task { @MainActor in
            for i in 0..<50 {
                try? await Task.sleep(nanoseconds: 100_000_000)
                scanProgress = min(Double(i + 1) * 2, 95)
                scanText = texts[min(i / 10, texts.count - 1)]
            }
        }

        let trimmedWeight = weightText.trimmingCharacters(in: .whitespaces)
        let weight = trimmedWeight.isEmpty ? nil : Double(trimmedWeight.replacingOccurrences(of: ",", with: "."))

        do {
            let analysis = try await store.analyzeBodyFat(imageData: imageData, weight: weight)
            let bodyFatPercent = BodyFatNormalizer.normalizedEstimate(
                rawLow: analysis.bodyFatLow,
                rawHigh: analysis.bodyFatHigh
            )

            progressTask.cancel()
            await MainActor.run { scanProgress = 100 }

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

            store.saveProgressPhoto(photo)
            if let weight { store.logWeight(weight) }

            await MainActor.run { result = photo }
        } catch {
            progressTask.cancel()
            await MainActor.run {
                errorMessage = error.localizedDescription
                showErrorAlert = true
            }
        }

        await MainActor.run { isScanning = false }
    }

    private func resetPhoto() {
        previewImage = nil
        scanningImage = nil
        selectedItem = nil
        result = nil
        weightText = ""
        isScanning = false
    }

    private func formatPercent(_ value: Double) -> String {
        value.truncatingRemainder(dividingBy: 1) == 0
            ? String(format: "%.0f", value)
            : String(format: "%.1f", value)
    }
}

/// Covers the entire screen during analysis so the upload card cannot sit on top of the photo.
private struct ScanningFullscreenView: View {
    let uiImage: UIImage
    let progress: Double
    let statusText: String

    private var cardSize: CGSize {
        let width = ScreenLayout.screenSize.width - ScreenLayout.horizontalPadding * 2
        let maxHeight = ScreenLayout.screenSize.height * 0.62
        let aspectHeight = width * 4 / 3
        return CGSize(width: width, height: min(aspectHeight, maxHeight))
    }

    var body: some View {
        ZStack {
            AppTheme.background
                .ignoresSafeArea()

            VStack(spacing: 0) {
                Spacer(minLength: 0)

                ZStack {
                    Image(uiImage: uiImage)
                        .resizable()
                        .scaledToFill()
                        .frame(width: cardSize.width, height: cardSize.height)
                        .clipped()

                    ScanOverlay(progress: progress)
                        .frame(width: cardSize.width, height: cardSize.height)

                    ScanningStatusBar(progress: progress, statusText: statusText)
                        .frame(width: cardSize.width, height: cardSize.height, alignment: .bottom)
                }
                .frame(width: cardSize.width, height: cardSize.height)
                .clipShape(RoundedRectangle(cornerRadius: 16))

                Spacer(minLength: 0)
            }
            .padding(.horizontal, ScreenLayout.horizontalPadding)
        }
        .ignoresSafeArea()
        .accessibilityElement(children: .contain)
        .accessibilityLabel("Analyzing photo")
    }
}

private struct ScanningStatusBar: View {
    let progress: Double
    let statusText: String

    var body: some View {
        VStack(spacing: 8) {
            HStack(spacing: 10) {
                SwiftUI.ProgressView()
                    .tint(AppTheme.accent)
                    .scaleEffect(0.9)
                Text(statusText)
                    .font(.caption.weight(.medium))
                    .foregroundStyle(.white)
                    .lineLimit(2)
                    .multilineTextAlignment(.leading)
                    .frame(maxWidth: .infinity, alignment: .leading)
            }
            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    Capsule().fill(Color.white.opacity(0.25))
                    Capsule()
                        .fill(AppTheme.accentGradient)
                        .frame(width: max(0, geo.size.width * progress / 100))
                }
            }
            .frame(height: 6)
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 12)
        .frame(maxWidth: .infinity)
        .background(.black.opacity(0.55))
    }
}

private struct ScanOverlay: View {
    let progress: Double

    var body: some View {
        GeometryReader { geo in
            let w = geo.size.width
            let h = geo.size.height
            let lineY = min(max(h * progress / 100, 0), max(h - 2, 0))

            ZStack(alignment: .topLeading) {
                cornerBrackets

                Rectangle()
                    .fill(
                        LinearGradient(
                            colors: [.clear, AppTheme.accent, .clear],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .frame(width: w, height: 2)
                    .offset(y: lineY)
            }
        }
        .allowsHitTesting(false)
    }

    private var cornerBrackets: some View {
        VStack {
            HStack {
                ScanCornerBracket()
                Spacer(minLength: 0)
                ScanCornerBracket()
                    .rotationEffect(.degrees(90))
            }
            Spacer(minLength: 0)
            HStack {
                ScanCornerBracket()
                    .rotationEffect(.degrees(-90))
                Spacer(minLength: 0)
                ScanCornerBracket()
                    .rotationEffect(.degrees(180))
            }
        }
        .padding(12)
    }
}

private struct ScanCornerBracket: View {
    private let size: CGFloat = 40

    var body: some View {
        Path { path in
            path.move(to: CGPoint(x: 0, y: size))
            path.addLine(to: .zero)
            path.addLine(to: CGPoint(x: size, y: 0))
        }
        .stroke(AppTheme.accent, lineWidth: 2)
        .frame(width: size, height: size)
    }
}

#Preview {
    WeightProgressView()
        .environmentObject(AppDataStore.shared)
}
