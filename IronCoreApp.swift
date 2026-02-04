import SwiftUI

@main
struct Iron_CoreApp: App {
    @StateObject private var authViewModel = AuthViewModel()
    @StateObject private var healthKitViewModel = HealthKitViewModel()
    @StateObject private var workoutViewModel = WorkoutViewModel()
    @StateObject private var watchConnectivity = WatchConnectivityManager.shared
    @StateObject private var rankingViewModel = RankingViewModel()
    @StateObject private var friendsViewModel = FriendsViewModel()
    @StateObject private var leaderboardViewModel = LeaderboardViewModel()
    @StateObject private var historyViewModel = HistoryViewModel()
    
    var body: some Scene {
        WindowGroup {
            RootView()
                .environmentObject(authViewModel)
                .environmentObject(healthKitViewModel)
                .environmentObject(workoutViewModel)
                .environmentObject(watchConnectivity)
                .environmentObject(rankingViewModel)
                .environmentObject(friendsViewModel)
                .environmentObject(leaderboardViewModel)
                .environmentObject(historyViewModel)
                .preferredColorScheme(.dark)
                .onAppear {
                    // Setup Watch Connectivity message handlers
                    setupWatchConnectivityHandlers()
                }
        }
    }
    
    private func setupWatchConnectivityHandlers() {
        // Listen for routine requests from Watch
        NotificationCenter.default.addObserver(
            forName: NSNotification.Name("WatchRequestedRoutines"),
            object: nil,
            queue: .main
        ) { _ in
            Task {
                await workoutViewModel.loadRoutines()
                watchConnectivity.sendRoutines(workoutViewModel.routines)
            }
        }
    }
}
