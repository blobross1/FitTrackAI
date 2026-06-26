import SwiftUI

struct OnboardingFlowView: View {
    @ObservedObject var store: OnboardingStore

    var body: some View {
        ZStack {
            switch store.step {
            case .goal:
                GoalSelectionView(store: store)
                    .transition(.asymmetric(insertion: .move(edge: .trailing).combined(with: .opacity), removal: .move(edge: .leading).combined(with: .opacity)))
            case .timeline:
                GoalTimelineView(store: store)
                    .transition(.asymmetric(insertion: .move(edge: .trailing).combined(with: .opacity), removal: .move(edge: .leading).combined(with: .opacity)))
            case .frequency:
                WorkoutFrequencyView(store: store)
                    .transition(.asymmetric(insertion: .move(edge: .trailing).combined(with: .opacity), removal: .move(edge: .leading).combined(with: .opacity)))
            case .bodyScan:
                BodyScanUploadView(store: store)
                    .transition(.opacity)
            case .lockedResults:
                LockedResultsView(store: store)
                    .transition(.asymmetric(insertion: .move(edge: .trailing).combined(with: .opacity), removal: .opacity))
            case .paywall:
                SuperwallPaywallView(onboarding: store)
                    .transition(.move(edge: .bottom).combined(with: .opacity))
            }
        }
        .animation(.spring(response: 0.45, dampingFraction: 0.86), value: store.step)
    }
}

#Preview("Full flow") {
    OnboardingFlowView(store: OnboardingStore.shared)
        .onAppear { OnboardingStore.shared.resetForPreview() }
}
