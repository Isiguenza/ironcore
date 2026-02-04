import Foundation
import Combine

@MainActor
class ExerciseDetailViewModel: ObservableObject {
    @Published var history: [WorkoutHistoryItem] = []
    @Published var personalRecords: PersonalRecordsData?
    @Published var stats: [ExerciseStats] = []
    @Published var exercise: Exercise?
    @Published var isLoading = false
    @Published var error: String?
    
    private let exerciseId: String
    private let apiClient = NeonDataAPIClient.shared
    
    init(exerciseId: String) {
        self.exerciseId = exerciseId
        Task {
            await loadData()
        }
    }
    
    func loadData() async {
        isLoading = true
        error = nil
        
        async let exerciseTask = loadExercise()
        async let historyTask = loadHistory()
        async let recordsTask = loadPersonalRecords()
        async let statsTask = loadStats()
        
        await exerciseTask
        await historyTask
        await recordsTask
        await statsTask
        
        isLoading = false
    }
    
    private func loadExercise() async {
        do {
            let exercises: [Exercise] = try await apiClient.get(
                table: "exercises",
                query: ["id": "eq.\(exerciseId)"]
            )
            exercise = exercises.first
            print("🏋️ [ExerciseDetail] Loaded exercise details")
        } catch {
            print("❌ [ExerciseDetail] Failed to load exercise: \(error.localizedDescription)")
            self.error = error.localizedDescription
        }
    }
    
    private func loadHistory() async {
        guard let userId = KeychainStore.shared.getUserId() else { return }
        
        do {
            history = try await apiClient.getExerciseHistory(userId: userId, exerciseId: exerciseId)
            print("📊 [ExerciseDetail] Loaded \(history.count) workout sessions")
        } catch {
            print("❌ [ExerciseDetail] Failed to load history: \(error.localizedDescription)")
            self.error = error.localizedDescription
        }
    }
    
    private func loadPersonalRecords() async {
        guard let userId = KeychainStore.shared.getUserId() else { return }
        
        do {
            personalRecords = try await apiClient.getPersonalRecords(userId: userId, exerciseId: exerciseId)
            print("🏆 [ExerciseDetail] Loaded personal records")
        } catch {
            print("❌ [ExerciseDetail] Failed to load records: \(error.localizedDescription)")
            self.error = error.localizedDescription
        }
    }
    
    private func loadStats() async {
        guard let userId = KeychainStore.shared.getUserId() else { return }
        
        do {
            stats = try await apiClient.getExerciseStats(userId: userId, exerciseId: exerciseId)
            print("📈 [ExerciseDetail] Loaded \(stats.count) stat entries")
        } catch {
            print("❌ [ExerciseDetail] Failed to load stats: \(error.localizedDescription)")
            self.error = error.localizedDescription
        }
    }
    
    // Helper to format chart data
    var chartData: [(date: String, weight: Double)] {
        if stats.isEmpty {
            // Sample data for UI preview
            return [
                ("Jul 11", 100),
                ("Jul 24", 100),
                ("Aug 21", 120),
                ("Sep 15", 110),
                ("Jan 20", 130)
            ]
        }
        
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "MMM dd"
        
        return stats.map { stat in
            (dateFormatter.string(from: stat.date), stat.maxWeight)
        }
    }
}
