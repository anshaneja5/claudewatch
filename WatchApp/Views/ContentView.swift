import SwiftUI

struct ContentView: View {
    var body: some View {
        TabView {
            DashboardView()
            SessionListView()
            RateLimitsView()
            TrendsView()
        }
        .tabViewStyle(.verticalPage)
    }
}
