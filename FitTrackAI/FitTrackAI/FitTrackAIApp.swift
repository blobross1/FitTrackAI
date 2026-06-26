import SwiftUI

@main
struct FitTrackAIApp: App {
    @StateObject private var store = AppDataStore.shared
    @StateObject private var subscription = SubscriptionManager.shared

    init() {
        SubscriptionManager.shared.configure()
    }

    var body: some Scene {
        WindowGroup {
            RootView()
                .environmentObject(store)
                .environmentObject(subscription)
                .preferredColorScheme(.dark)
                .onAppear { store.loadIfNeeded() }
        }
    }
}
