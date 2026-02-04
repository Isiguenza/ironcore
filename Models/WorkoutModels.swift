import Foundation

// MARK: - Active Workout Models (Shared between iOS and watchOS)

struct ActiveWorkout {
    let userId: String
    let routineId: String?
    let routineName: String?
    let routineDescription: String?
    let startTime: Date
    var endTime: Date?
    var exercises: [ActiveWorkoutExercise]
}

struct ActiveWorkoutExercise: Identifiable {
    let id = UUID()
    let exercise: Exercise
    let targetSets: Int
    let targetReps: Int?
    let targetWeight: Double?
    var restTime: Int
    var completedSets: [CompletedSet]
    
    // Convenience properties
    var exerciseId: String { exercise.id }
    var exerciseName: String { exercise.name }
}

struct CompletedSet: Identifiable {
    let id = UUID()
    let setNumber: Int
    let weight: Double
    let reps: Int
    let setType: SetType
    let rpe: Int?
    let completedAt: Date
}

enum SetType: String, Codable, CaseIterable {
    case warmup = "warmup"
    case working = "working"
    case dropset = "dropset"
    case failure = "failure"
    
    var displayName: String {
        switch self {
        case .warmup: return "Warm Up"
        case .working: return "Working"
        case .dropset: return "Drop Set"
        case .failure: return "To Failure"
        }
    }
}
