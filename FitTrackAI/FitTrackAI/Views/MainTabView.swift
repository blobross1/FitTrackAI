import SwiftUI

enum AppTab: String, CaseIterable {
    case progress = "Weight %"
    case analytics = "Analytics"
    case account = "Account"

    var icon: String {
        switch self {
        case .progress: return "camera.fill"
        case .analytics: return "chart.bar.fill"
        case .account: return "person.crop.circle.fill"
        }
    }
}

struct MainTabView: View {
    @State private var selectedTab: AppTab = .progress

    var body: some View {
        TabView(selection: $selectedTab) {
            WeightProgressView()
                .tabItem { Label(AppTab.progress.rawValue, systemImage: AppTab.progress.icon) }
                .tag(AppTab.progress)
            AnalyticsView()
                .tabItem { Label(AppTab.analytics.rawValue, systemImage: AppTab.analytics.icon) }
                .tag(AppTab.analytics)
            AccountView()
                .tabItem { Label(AppTab.account.rawValue, systemImage: AppTab.account.icon) }
                .tag(AppTab.account)
        }
        .tint(AppTheme.accent)
        .toolbarBackground(.ultraThinMaterial, for: .tabBar)
        .toolbarBackground(.visible, for: .tabBar)
        .onAppear { AppDataStore.shared.loadIfNeeded() }
    }
}

#Preview {
    MainTabView()
        .environmentObject(AppDataStore.shared)
}
