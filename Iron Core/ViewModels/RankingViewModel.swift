import Foundation
import Combine
import HealthKit

@MainActor
class RankingViewModel: ObservableObject {
    @Published var currentRating: Rating?
    @Published var currentWeekScore: ScoreComponents?
    @Published var isLoading = false
    @Published var errorMessage: String?
    @Published var isSubmitting = false
    
    private let dataAPI = NeonDataAPIClient.shared
    private let healthKitManager = HealthKitManager.shared
    private let scoreCalculator = ScoreCalculator.shared
    
    func loadCurrentRating() async {
        guard let userId = KeychainStore.shared.getUserId() else {
            print("❌ [RANK] No userId found in keychain")
            return
        }
        
        print("📊 [RANK] Loading rating for userId: \(userId)")
        
        do {
            let ratings: [Rating] = try await dataAPI.get(table: "ratings", query: ["user_id": "eq.\(userId)"])
            print("📊 [RANK] Found \(ratings.count) ratings")
            
            if let rating = ratings.first {
                currentRating = rating
                print("✅ [RANK] Current rating: \(rating.rank.rawValue) - \(rating.lp) LP")
            } else {
                print("⚠️ [RANK] No rating found for user, creating default rating...")
                await createDefaultRating(userId: userId)
            }
        } catch {
            print("❌ [RANK] Error loading rating: \(error.localizedDescription)")
            errorMessage = error.localizedDescription
        }
    }
    
    private func createDefaultRating(userId: String) async {
        do {
            let defaultRating = RatingRequest(
                userId: userId,
                mmr: 0,
                lp: 0,
                rank: .untrained,
                division: 3
            )
            
            let ratings: [Rating] = try await dataAPI.post(table: "ratings", body: defaultRating)
            if let rating = ratings.first {
                currentRating = rating
                print("✅ [RANK] Created default rating: \(rating.rank.rawValue) - \(rating.lp) LP")
            }
        } catch {
            print("❌ [RANK] Error creating default rating: \(error.localizedDescription)")
        }
    }
    
    func calculateCurrentWeekScore() async {
        isLoading = true
        errorMessage = nil
        
        do {
            let weekStart = Date().startOfWeek()
            let weekEnd = Calendar.current.date(byAdding: .day, value: 7, to: weekStart) ?? Date()
            
            print("🏋️ [HEALTH] Fetching data from \(weekStart) to \(weekEnd)")
            
            let workouts = try await healthKitManager.fetchWeeklyWorkouts(startDate: weekStart)
            print("🏋️ [HEALTH] Found \(workouts.count) workouts")
            
            for (index, workout) in workouts.enumerated() {
                print("🏋️ [HEALTH] Workout \(index + 1): \(workout.workoutActivityType.name) - \(workout.duration/60) min - \(workout.startDate)")
            }
            
            let sleepSamples = try await healthKitManager.fetchWeeklySleep(startDate: weekStart)
            print("🏋️ [HEALTH] Found \(sleepSamples.count) sleep samples")
            
            currentWeekScore = await scoreCalculator.calculateWeeklyScore(workouts: workouts, sleepSamples: sleepSamples)
            
            print("🏋️ [HEALTH] Score calculated - Total: \(currentWeekScore?.total ?? 0)")
            print("🏋️ [HEALTH] Consistency: \(currentWeekScore?.consistency ?? 0)")
            print("🏋️ [HEALTH] Volume: \(currentWeekScore?.volume ?? 0)")
            print("🏋️ [HEALTH] Intensity: \(currentWeekScore?.intensity ?? 0)")
            print("🏋️ [HEALTH] Recovery: \(currentWeekScore?.recovery ?? 0)")
        } catch {
            print("🔴 [HEALTH] Error: \(error.localizedDescription)")
            errorMessage = error.localizedDescription
        }
        
        isLoading = false
    }
    
    func submitWeeklyScore() async {
        guard let components = currentWeekScore else { return }
        guard let userId = KeychainStore.shared.getUserId() else { return }
        
        isSubmitting = true
        errorMessage = nil
        
        do {
            let weekStart = Date().startOfWeek().toDateString()
            let scoreRequest = WeeklyScoreRequest(
                userId: nil,
                weekStart: weekStart,
                score: components.total,
                components: components
            )
            
            let _: [WeeklyScore] = try await dataAPI.post(table: "weekly_scores", body: scoreRequest)
            
            if let rating = currentRating {
                let newRating = calculateNewRating(currentRating: rating, score: components.total)
                await updateRating(newRating)
            }
            
            await loadCurrentRating()
        } catch {
            errorMessage = error.localizedDescription
        }
        
        isSubmitting = false
    }
    
    private func calculateNewRating(currentRating: Rating, score: Int) -> Rating {
        let expectedScore = calculateExpectedScore(mmr: currentRating.mmr)
        let deltaLP = calculateDeltaLP(score: score, expectedScore: expectedScore, currentLP: currentRating.lp)
        
        let newLP = max(0, currentRating.lp + deltaLP)
        let newMMR = currentRating.mmr + (deltaLP / 2)
        
        let (rank, division) = calculateRankAndDivision(lp: newLP)
        
        return Rating(
            userId: currentRating.userId,
            mmr: newMMR,
            lp: newLP,
            rank: rank,
            division: division,
            updatedAt: Date()
        )
    }
    
    private func calculateExpectedScore(mmr: Int) -> Double {
        let expected = 50.0 + Double(mmr - 1000) / 20.0
        return max(20.0, min(85.0, expected))
    }
    
    private func calculateDeltaLP(score: Int, expectedScore: Double, currentLP: Int) -> Int {
        let difference = Double(score) - expectedScore
        let factor = getFactorForLP(lp: currentLP)
        return Int(difference * factor)
    }
    
    private func getFactorForLP(lp: Int) -> Double {
        switch lp {
        case 0..<300: return 1.2
        case 300..<1000: return 1.0
        case 1000..<2100: return 0.8
        case 2100..<3600: return 0.7
        default: return 0.6
        }
    }
    
    private func calculateRankAndDivision(lp: Int) -> (Rank, Int?) {
        let ranks = Rank.allCases
        
        for i in (0..<ranks.count).reversed() {
            let rank = ranks[i]
            if lp >= rank.lpThreshold {
                if rank == .forged {
                    return (rank, nil)
                }
                
                let nextThreshold = i < ranks.count - 1 ? ranks[i + 1].lpThreshold : Int.max
                let lpRange = nextThreshold - rank.lpThreshold
                let lpIntoRank = lp - rank.lpThreshold
                
                if lpIntoRank < lpRange / 3 {
                    return (rank, 3)
                } else if lpIntoRank < (lpRange * 2) / 3 {
                    return (rank, 2)
                } else {
                    return (rank, 1)
                }
            }
        }
        
        return (.untrained, 3)
    }
    
    private func updateRating(_ rating: Rating) async {
        do {
            let updateRequest = RatingUpdateRequest(
                mmr: rating.mmr,
                lp: rating.lp,
                rank: rating.rank.rawValue,
                division: rating.division
            )
            
            let _: [Rating] = try await dataAPI.patch(
                table: "ratings",
                body: updateRequest,
                query: ["user_id": "eq.\(rating.userId)"]
            )
        } catch {
            errorMessage = error.localizedDescription
        }
    }
}

struct RatingUpdateRequest: Codable {
    let mmr: Int
    let lp: Int
    let rank: String
    let division: Int?
}
