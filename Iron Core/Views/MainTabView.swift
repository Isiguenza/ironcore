import SwiftUI

struct MainTabView: View {
    @State private var selectedTab = 0
    
    var body: some View {
        TabView(selection: $selectedTab) {
            HomeView()
                .tabItem {
                    Image(systemName: "house.fill")
                    Text("Home")
                }
                .tag(0)
            
            ExerciseTab()
                .tabItem {
                    Image(systemName: "dumbbell.fill")
                    Text("Exercise")
                }
                .tag(1)
            
            LeaderboardView()
                .tabItem {
                    Image(systemName: "chart.bar.fill")
                    Text("Leaderboard")
                }
                .tag(2)
            
            FriendsView()
                .tabItem {
                    Image(systemName: "person.2.fill")
                    Text("Friends")
                }
                .tag(3)
            
            HistoryView()
                .tabItem {
                    Image(systemName: "clock.fill")
                    Text("History")
                }
                .tag(4)
            
            SettingsView()
                .tabItem {
                    Image(systemName: "gearshape.fill")
                    Text("Settings")
                }
                .tag(5)
        }
        //.accentColor(.neonGreen)
    }
}
