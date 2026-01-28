import SwiftUI

@main
struct Iron_CoreApp: App {
    @StateObject private var authViewModel = AuthViewModel()
    @StateObject private var healthKitViewModel = HealthKitViewModel()
    @StateObject private var rankingViewModel = RankingViewModel()
    @StateObject private var friendsViewModel = FriendsViewModel()
    @StateObject private var leaderboardViewModel = LeaderboardViewModel()
    @StateObject private var historyViewModel = HistoryViewModel()
    
    var body: some Scene {
        WindowGroup {
            RootView()
                .environmentObject(authViewModel)
                .environmentObject(healthKitViewModel)
                .environmentObject(rankingViewModel)
                .environmentObject(friendsViewModel)
                .environmentObject(leaderboardViewModel)
                .environmentObject(historyViewModel)
                .preferredColorScheme(.dark)
        }
    }
}
