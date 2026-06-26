import SwiftUI

// MARK: - Layout shell

struct OnboardingScreenShell<Content: View, Footer: View>: View {
    let step: Int
    let title: String
    let subtitle: String?
    @ViewBuilder var content: () -> Content
    @ViewBuilder var footer: () -> Footer

    init(
        step: Int,
        title: String,
        subtitle: String? = nil,
        @ViewBuilder content: @escaping () -> Content,
        @ViewBuilder footer: @escaping () -> Footer
    ) {
        self.step = step
        self.title = title
        self.subtitle = subtitle
        self.content = content
        self.footer = footer
    }

    var body: some View {
        ZStack {
            OnboardingBackground()

            VStack(spacing: 0) {
                OnboardingProgressBar(currentStep: step, totalSteps: OnboardingStep.totalSteps)
                    .padding(.horizontal, 24)
                    .padding(.top, 12)

                ScrollView(.vertical, showsIndicators: false) {
                    VStack(alignment: .leading, spacing: 24) {
                        VStack(alignment: .leading, spacing: 10) {
                            Text(title)
                                .font(.system(size: 28, weight: .bold, design: .rounded))
                                .foregroundStyle(.white)
                            if let subtitle {
                                Text(subtitle)
                                    .font(.body)
                                    .foregroundStyle(.white.opacity(0.65))
                            }
                        }
                        .padding(.top, 8)

                        content()
                    }
                    .padding(.horizontal, 24)
                    .padding(.bottom, 24)
                }
                .scrollDismissesKeyboard(.interactively)

                footer()
                    .padding(.horizontal, 24)
                    .padding(.bottom, 28)
            }
        }
    }
}

struct OnboardingBackground: View {
    @State private var animate = false

    var body: some View {
        ZStack {
            OnboardingTheme.backgroundGradient.ignoresSafeArea()

            Circle()
                .fill(OnboardingTheme.accent.opacity(0.22))
                .frame(width: 320, height: 320)
                .blur(radius: 80)
                .offset(x: animate ? 90 : -60, y: animate ? -180 : -120)

            Circle()
                .fill(OnboardingTheme.accentSecondary.opacity(0.15))
                .frame(width: 260, height: 260)
                .blur(radius: 70)
                .offset(x: animate ? -80 : 100, y: animate ? 320 : 260)
        }
        .onAppear {
            withAnimation(.easeInOut(duration: 6).repeatForever(autoreverses: true)) {
                animate = true
            }
        }
    }
}

struct OnboardingProgressBar: View {
    let currentStep: Int
    let totalSteps: Int

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text("Step \(currentStep) of \(totalSteps)")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(.white.opacity(0.5))
                Spacer()
            }
            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    Capsule().fill(Color.white.opacity(0.1))
                    Capsule()
                        .fill(OnboardingTheme.accentGradient)
                        .frame(width: geo.size.width * CGFloat(currentStep) / CGFloat(totalSteps))
                        .animation(.spring(response: 0.5, dampingFraction: 0.85), value: currentStep)
                }
            }
            .frame(height: 5)
        }
    }
}

// MARK: - Cards & buttons

struct OnboardingGlassCard<Content: View>: View {
    var isSelected = false
    @ViewBuilder var content: () -> Content

    var body: some View {
        content()
            .padding(16)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background {
                RoundedRectangle(cornerRadius: 18, style: .continuous)
                    .fill(OnboardingTheme.card.opacity(0.85))
                    .overlay {
                        RoundedRectangle(cornerRadius: 18, style: .continuous)
                            .stroke(
                                isSelected ? OnboardingTheme.accent : OnboardingTheme.glassStroke,
                                lineWidth: isSelected ? 2 : 1
                            )
                    }
                    .shadow(color: isSelected ? OnboardingTheme.accent.opacity(0.35) : .clear, radius: 16)
            }
            .animation(.spring(response: 0.35, dampingFraction: 0.8), value: isSelected)
    }
}

struct OnboardingPrimaryButton: View {
    let title: String
    var enabled = true
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Text(title)
                .font(.headline.weight(.semibold))
                .frame(maxWidth: .infinity)
                .padding(.vertical, 18)
                .foregroundStyle(.white)
                .background {
                    if enabled {
                        OnboardingTheme.accentGradient
                    } else {
                        Color.white.opacity(0.15)
                    }
                }
                .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
                .shadow(color: enabled ? OnboardingTheme.accent.opacity(0.45) : .clear, radius: 20, y: 8)
        }
        .disabled(!enabled)
        .animation(.easeInOut(duration: 0.2), value: enabled)
    }
}

struct OnboardingSecondaryButton: View {
    let title: String
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Text(title)
                .font(.subheadline.weight(.medium))
                .foregroundStyle(.white.opacity(0.7))
        }
        .frame(maxWidth: .infinity)
        .padding(.top, 4)
    }
}

struct BlurredMetricValue: View {
    let label: String
    let icon: String
    var tint: Color = OnboardingTheme.accent

    var body: some View {
        OnboardingGlassCard {
            HStack(spacing: 14) {
                Image(systemName: icon)
                    .font(.title3)
                    .foregroundStyle(tint)
                    .frame(width: 44, height: 44)
                    .background(tint.opacity(0.15))
                    .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))

                VStack(alignment: .leading, spacing: 6) {
                    Text(label)
                        .font(.caption.weight(.medium))
                        .foregroundStyle(.white.opacity(0.55))
                    Text("██.██")
                        .font(.title2.weight(.bold))
                        .foregroundStyle(.white)
                        .blur(radius: 14)
                        .overlay {
                            RoundedRectangle(cornerRadius: 6)
                                .fill(Color.white.opacity(0.08))
                                .frame(height: 28)
                        }
                }
                Spacer()
                Image(systemName: "lock.fill")
                    .foregroundStyle(.white.opacity(0.35))
            }
        }
    }
}

// MARK: - Scan UI

struct OnboardingScanOverlay: View {
    var body: some View {
        GeometryReader { geo in
            let w = geo.size.width
            let h = geo.size.height

            TimelineView(.animation(minimumInterval: 1 / 60)) { timeline in
                let cycle = 2.4
                let phase = timeline.date.timeIntervalSinceReferenceDate
                    .truncatingRemainder(dividingBy: cycle) / cycle
                let lineY = max(0, min(h - 2, h * phase))

                ZStack(alignment: .topLeading) {
                    cornerBrackets
                    Rectangle()
                        .fill(
                            LinearGradient(
                                colors: [.clear, OnboardingTheme.accent, OnboardingTheme.accentSecondary, .clear],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .frame(width: w, height: 2)
                        .shadow(color: OnboardingTheme.accent.opacity(0.8), radius: 6)
                        .offset(y: lineY)
                }
            }
        }
        .allowsHitTesting(false)
    }

    private var cornerBrackets: some View {
        VStack {
            HStack {
                OnboardingScanBracket()
                Spacer(minLength: 0)
                OnboardingScanBracket().rotationEffect(.degrees(90))
            }
            Spacer(minLength: 0)
            HStack {
                OnboardingScanBracket().rotationEffect(.degrees(-90))
                Spacer(minLength: 0)
                OnboardingScanBracket().rotationEffect(.degrees(180))
            }
        }
        .padding(14)
    }
}

private struct OnboardingScanBracket: View {
    private let size: CGFloat = 36

    var body: some View {
        Path { path in
            path.move(to: CGPoint(x: 0, y: size))
            path.addLine(to: .zero)
            path.addLine(to: CGPoint(x: size, y: 0))
        }
        .stroke(OnboardingTheme.accent, lineWidth: 2)
        .frame(width: size, height: size)
    }
}

struct OnboardingScanStatusBar: View {
    let progress: Double
    let statusText: String

    var body: some View {
        VStack(spacing: 8) {
            HStack(spacing: 10) {
                SwiftUI.ProgressView()
                    .tint(OnboardingTheme.accent)
                Text(statusText)
                    .font(.caption.weight(.medium))
                    .foregroundStyle(.white)
                    .frame(maxWidth: .infinity, alignment: .leading)
            }
            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    Capsule().fill(Color.white.opacity(0.2))
                    Capsule()
                        .fill(OnboardingTheme.accentGradient)
                        .frame(width: max(0, geo.size.width * progress / 100))
                        .animation(.linear(duration: 0.12), value: progress)
                }
            }
            .frame(height: 6)
        }
        .padding(14)
        .background(.black.opacity(0.55))
    }
}

#Preview("Components") {
    OnboardingScreenShell(step: 1, title: "Preview", subtitle: "Subtitle") {
        OnboardingGlassCard(isSelected: true) {
            Text("Card content")
                .foregroundStyle(.white)
        }
    } footer: {
        OnboardingPrimaryButton(title: "Continue", action: {})
    }
}
