import Foundation
import Combine

@MainActor
class LeaderboardViewModel: ObservableObject {
    @Published var leaderboard: [FriendWithScore] = []
    @Published var isLoading = false
    @Published var errorMessage: String?
    
    private let dataAPI = NeonDataAPIClient.shared
    
    func loadWeeklyLeaderboard(friends: [UserProfile]) async {
        guard let userId = KeychainStore.shared.getUserId() else { return }
        
        isLoading = true
        errorMessage = nil
        
        do {
            var allUserIds = friends.map { $0.userId }
            if !allUserIds.contains(userId) {
                allUserIds.append(userId)
            }
            
            let weekStart = Date().startOfWeek().toDateString()
            
            let scores: [WeeklyScore] = try await dataAPI.get(
                table: "weekly_scores",
                query: [
                    "user_id": "in.(\(allUserIds.joined(separator: ",")))",
                    "week_start": "eq.\(weekStart)"
                ]
            )
            
            let ratings: [Rating] = try await dataAPI.get(
                table: "ratings",
                query: ["user_id": "in.(\(allUserIds.joined(separator: ",")))"]
            )
            
            let profiles: [UserProfile] = try await dataAPI.get(
                table: "profiles",
                query: ["user_id": "in.(\(allUserIds.joined(separator: ",")))"]
            )
            
            var friendsWithScores: [FriendWithScore] = []
            
            for profile in profiles {
                let score = scores.first { $0.userId == profile.userId }
                let rating = ratings.first { $0.userId == profile.userId }
                
                let friendWithScore = FriendWithScore(
                    id: profile.userId,
                    profile: profile,
                    weeklyScore: score,
                    rating: rating
                )
                friendsWithScores.append(friendWithScore)
            }
            
            leaderboard = friendsWithScores.sorted { $0.displayScore > $1.displayScore }
        } catch {
            errorMessage = error.localizedDescription
        }
        
        isLoading = false
    }
}
