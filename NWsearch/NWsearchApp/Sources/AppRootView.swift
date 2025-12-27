import SwiftUI

struct AppRootView: View {
    var body: some View {
        TabView {
            NavigationStack {
                HomeView()
            }
            .tabItem {
                Label("ホーム", systemImage: "house")
            }

            NavigationStack {
                HistoryView()
            }
            .tabItem {
                Label("履歴", systemImage: "clock")
            }

            NavigationStack {
                GuideListView(recommendedCodes: [])
            }
            .tabItem {
                Label("ガイド", systemImage: "lightbulb")
            }

            NavigationStack {
                SettingsView()
            }
            .tabItem {
                Label("設定", systemImage: "gearshape")
            }
        }
    }
}
