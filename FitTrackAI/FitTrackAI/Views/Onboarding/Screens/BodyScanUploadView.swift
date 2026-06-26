import SwiftUI
import PhotosUI
import UIKit

struct BodyScanUploadView: View {
    @ObservedObject var store: OnboardingStore
    @State private var selectedItem: PhotosPickerItem?
    @FocusState private var focusedField: Field?

    private enum Field {
        case weight, height
    }

    private var cardWidth: CGFloat {
        min(UIScreen.main.bounds.width - 48, 340)
    }

    private var placeholderHeight: CGFloat {
        min(cardWidth * 4 / 3, 240)
    }

    var body: some View {
        Group {
            if store.isScanning, let image = store.bodyPhoto {
                scanningView(image: image)
            } else {
                uploadView
            }
        }
    }

    private var uploadView: some View {
        OnboardingScreenShell(
            step: OnboardingStep.bodyScan.progressIndex,
            title: "Upload your progress photo",
            subtitle: "Add a front-facing photo. Weight and height are optional but improve calorie estimates."
        ) {
            VStack(spacing: 16) {
                photoSection
                statsFields
            }
            .frame(maxWidth: .infinity)
        } footer: {
            VStack(spacing: 8) {
                OnboardingPrimaryButton(
                    title: "Analyze Physique",
                    enabled: store.canContinueFromBodyScan,
                    action: {
                        focusedField = nil
                        Task { await store.runBodyScan() }
                    }
                )
                OnboardingSecondaryButton(title: "Back", action: store.goBack)
            }
        }
        .alert("Analysis Failed", isPresented: Binding(
            get: { store.scanError != nil },
            set: { if !$0 { store.scanError = nil } }
        )) {
            Button("OK", role: .cancel) { store.scanError = nil }
        } message: {
            Text(store.scanError ?? "")
        }
    }

    private var statsFields: some View {
        VStack(spacing: 14) {
            HStack(spacing: 12) {
                statField(title: "Weight (kg, optional)", text: $store.weightText, field: .weight)
                statField(title: "Height (cm, optional)", text: $store.heightText, field: .height)
            }

            VStack(alignment: .leading, spacing: 8) {
                Text("Biological sex")
                    .font(.subheadline.weight(.medium))
                    .foregroundStyle(.white.opacity(0.65))

                Picker("Sex", selection: $store.biologicalSex) {
                    ForEach(NutritionCalculator.BiologicalSex.allCases) { sex in
                        Text(sex.displayName).tag(sex)
                    }
                }
                .pickerStyle(.segmented)
            }

            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Text("Age")
                        .font(.subheadline.weight(.medium))
                        .foregroundStyle(.white.opacity(0.65))
                    Spacer()
                    Text("\(store.age)")
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(OnboardingTheme.accentSecondary)
                }

                Slider(
                    value: Binding(
                        get: { Double(store.age) },
                        set: { store.age = Int($0.rounded()) }
                    ),
                    in: 16...75,
                    step: 1
                )
                .tint(OnboardingTheme.accent)
            }
        }
    }

    private func statField(title: String, text: Binding<String>, field: Field) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title)
                .font(.subheadline.weight(.medium))
                .foregroundStyle(.white.opacity(0.65))

            TextField("—", text: text)
                .keyboardType(.decimalPad)
                .font(.title3.weight(.semibold))
                .foregroundStyle(.white)
                .focused($focusedField, equals: field)
                .padding()
                .frame(maxWidth: .infinity)
                .background(OnboardingTheme.card)
                .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
                .overlay {
                    RoundedRectangle(cornerRadius: 14, style: .continuous)
                        .stroke(OnboardingTheme.glassStroke, lineWidth: 1)
                }
        }
    }

    private var photoSection: some View {
        VStack(spacing: 12) {
            photoCard
                .frame(maxWidth: .infinity)

            HStack(spacing: 12) {
                PhotosPicker(selection: $selectedItem, matching: .images) {
                    pickerLabel(icon: "camera.fill", text: "Take Photo")
                }
                PhotosPicker(selection: $selectedItem, matching: .images) {
                    pickerLabel(icon: "photo.on.rectangle", text: "Upload")
                }
            }
        }
        .onChange(of: selectedItem) { _, item in
            Task {
                guard let item,
                      let data = try? await item.loadTransferable(type: Data.self),
                      let image = UIImage(data: data) else { return }
                await MainActor.run {
                    store.bodyPhoto = normalizedImage(image)
                }
            }
        }
    }

    @ViewBuilder
    private var photoCard: some View {
        ZStack(alignment: .topTrailing) {
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .fill(OnboardingTheme.card)

            if let image = store.bodyPhoto {
                let height = fittedHeight(for: image)

                Image(uiImage: image)
                    .resizable()
                    .scaledToFit()
                    .frame(width: cardWidth, height: height)
                    .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))

                Button {
                    store.bodyPhoto = nil
                    selectedItem = nil
                } label: {
                    Image(systemName: "xmark.circle.fill")
                        .font(.title2)
                        .symbolRenderingMode(.palette)
                        .foregroundStyle(.white, .black.opacity(0.5))
                }
                .padding(10)
            } else {
                VStack(spacing: 12) {
                    Spacer(minLength: 0)
                    Image(systemName: "camera.viewfinder")
                        .font(.system(size: 40))
                        .foregroundStyle(OnboardingTheme.accent)
                    Text("Add a front-facing photo")
                        .font(.subheadline)
                        .foregroundStyle(.white.opacity(0.6))
                    Spacer(minLength: 0)
                }
                .frame(width: cardWidth, height: placeholderHeight)
            }
        }
        .frame(width: cardWidth)
        .frame(maxWidth: .infinity)
    }

    private func scanningView(image: UIImage) -> some View {
        let height = fittedHeight(for: image, maxHeight: 360)
        return ZStack {
            OnboardingBackground()
            VStack(spacing: 24) {
                Text("Analyzing your physique")
                    .font(.title2.weight(.bold))
                    .foregroundStyle(.white)
                    .padding(.top, 48)

                ZStack {
                    Image(uiImage: image)
                        .resizable()
                        .scaledToFit()
                        .frame(width: cardWidth, height: height)

                    OnboardingScanOverlay()
                        .frame(width: cardWidth, height: height)

                    OnboardingScanStatusBar(
                        progress: store.scanProgress,
                        statusText: store.scanStatusText
                    )
                    .frame(width: cardWidth, height: height, alignment: .bottom)
                }
                .frame(width: cardWidth, height: height)
                .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
                .shadow(color: OnboardingTheme.accent.opacity(0.3), radius: 24)

                Spacer()
            }
        }
        .ignoresSafeArea()
    }

    private func fittedHeight(for image: UIImage, maxHeight: CGFloat = 520) -> CGFloat {
        let width = max(image.size.width, 1)
        let aspect = image.size.height / width
        let raw = cardWidth * aspect
        return min(max(raw, cardWidth * 0.55), maxHeight)
    }

    private func pickerLabel(icon: String, text: String) -> some View {
        HStack(spacing: 8) {
            Image(systemName: icon)
            Text(text)
                .font(.subheadline.weight(.semibold))
                .lineLimit(1)
                .minimumScaleFactor(0.8)
        }
        .foregroundStyle(.white)
        .frame(maxWidth: .infinity)
        .padding(.vertical, 14)
        .background(OnboardingTheme.accent.opacity(0.85))
        .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
    }

    private func normalizedImage(_ image: UIImage) -> UIImage {
        let maxSide: CGFloat = 1280
        let size = image.size
        let longest = max(size.width, size.height)
        guard longest > maxSide else { return image }

        let scale = maxSide / longest
        let newSize = CGSize(width: size.width * scale, height: size.height * scale)
        let renderer = UIGraphicsImageRenderer(size: newSize)
        return renderer.image { _ in
            image.draw(in: CGRect(origin: .zero, size: newSize))
        }
    }
}

#Preview("Upload") {
    BodyScanUploadView(store: OnboardingStore.shared)
}
