import Foundation
import Combine

@MainActor
class HistoryViewModel: ObservableObject {
    @Published var weeklyScores: [WeeklyScore] = []
    @Published var isLoading = false
    @Published var errorMessage: String?
    
    private let dataAPI = NeonDataAPIClient.shared
    
    func loadHistory() async {
        guard let userId = KeychainStore.shared.getUserId() else { return }
        
        isLoading = true
        errorMessage = nil
        
        do {
            let scores: [WeeklyScore] = try await dataAPI.get(
                table: "weekly_scores",
                query: [
                    "user_id": "eq.\(userId)",
                    "order": "week_start.desc",
                    "limit": "10"
                ]
            )
            weeklyScores = scores
        } catch {
            errorMessage = error.localizedDescription
        }
        
        isLoading = false
    }
}
