import Foundation

struct WorkoutSession: Codable, Identifiable {
    let id: String
    let userId: String
    let routineId: String?
    let routineName: String?
    let startTime: Date
    let endTime: Date?
    let duration: Int?
    let totalVolume: Double
    let totalSets: Int
    let exercises: [WorkoutExercise]
    let qualityScore: Double?
    
    enum CodingKeys: String, CodingKey {
        case id, duration, exercises
        case userId = "user_id"
        case routineId = "routine_id"
        case routineName = "routine_name"
        case startTime = "start_time"
        case endTime = "end_time"
        case totalVolume = "total_volume"
        case totalSets = "total_sets"
        case qualityScore = "quality_score"
    }
}

struct WorkoutExercise: Codable, Identifiable, Hashable {
    let id: String
    let exerciseId: String
    let exerciseName: String
    let sets: [WorkoutSet]
    let notes: String?
    
    enum CodingKeys: String, CodingKey {
        case id, sets, notes
        case exerciseId = "exercise_id"
        case exerciseName = "exercise_name"
    }
}

struct WorkoutSet: Codable, Identifiable, Hashable {
    let id: String
    let setNumber: Int
    let weight: Double
    let reps: Int
    let setType: SetType
    let rpe: Int?
    let isPersonalRecord: Bool
    let completedAt: Date
    
    enum CodingKeys: String, CodingKey {
        case id, weight, reps, rpe
        case setNumber = "set_number"
        case setType = "set_type"
        case isPersonalRecord = "is_personal_record"
        case completedAt = "completed_at"
    }
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

struct WorkoutSessionRequest: Codable {
    let userId: String
    let routineId: String?
    let routineName: String?
    let startTime: Date
    let endTime: Date?
    let totalVolume: Double
    let totalSets: Int
    let qualityScore: Double?
    
    enum CodingKeys: String, CodingKey {
        case userId = "user_id"
        case routineId = "routine_id"
        case routineName = "routine_name"
        case startTime = "start_time"
        case endTime = "end_time"
        case totalVolume = "total_volume"
        case totalSets = "total_sets"
        case qualityScore = "quality_score"
    }
}
