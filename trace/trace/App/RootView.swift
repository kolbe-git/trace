import SwiftUI

/// 根导航：五个业务一一对应一个 Tab，首次启动弹引导页。
struct RootView: View {
    @AppStorage("hasOnboarded") private var hasOnboarded = false
    @State private var showOnboarding = false

    var body: some View {
        TabView {
            RecordView()
                .tabItem { Label("记录", systemImage: "figure.run") }
            HistoryView()
                .tabItem { Label("历史", systemImage: "list.bullet.rectangle") }
            StatsView()
                .tabItem { Label("统计", systemImage: "chart.bar.xaxis") }
            GoalsView()
                .tabItem { Label("目标", systemImage: "target") }
            ProfileView()
                .tabItem { Label("我的", systemImage: "person.crop.circle") }
        }
        .fullScreenCover(isPresented: $showOnboarding) {
            OnboardingView {
                hasOnboarded = true
                showOnboarding = false
            }
            .interactiveDismissDisabled()
        }
        .onAppear { showOnboarding = !hasOnboarded }
    }
}

#Preview {
    RootView()
}
