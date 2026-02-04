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
    let exercises: [WorkoutExercise]?
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
    let sets: [WorkoutSet]?
    let notes: String?
    
    enum CodingKeys: String, CodingKey {
        case id, sets, notes
        case exerciseId = "exercise_id"
        case exerciseName = "exercise_name"
    }
}

struct WorkoutSet: Codable, Hashable, Identifiable {
    let id: String
    let exerciseId: String
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
        case exerciseId = "exercise_id"
        case setType = "set_type"
        case isPersonalRecord = "is_personal_record"
        case completedAt = "completed_at"
    }
}

// SetType is now defined in WorkoutModels.swift

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

struct WorkoutExerciseRequest: Codable {
    let sessionId: String
    let exerciseId: String
    let exerciseName: String
    let notes: String?
    
    enum CodingKeys: String, CodingKey {
        case sessionId = "session_id"
        case exerciseId = "exercise_id"
        case exerciseName = "exercise_name"
        case notes
    }
}

struct WorkoutSetRequest: Codable {
    let workoutExerciseId: String
    let setNumber: Int
    let weight: Double
    let reps: Int
    let setType: String
    let rpe: Int?
    let isPersonalRecord: Bool
    let completedAt: Date
    
    enum CodingKeys: String, CodingKey {
        case workoutExerciseId = "workout_exercise_id"
        case setNumber = "set_number"
        case weight, reps
        case setType = "set_type"
        case rpe
        case isPersonalRecord = "is_personal_record"
        case completedAt = "completed_at"
    }
}
