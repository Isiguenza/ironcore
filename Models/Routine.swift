import Foundation

struct Routine: Codable, Identifiable {
    let id: String
    let userId: String
    let name: String
    let description: String?
    var exercises: [RoutineExercise]
    let createdAt: Date
    let updatedAt: Date
    
    enum CodingKeys: String, CodingKey {
        case id, name, description, exercises
        case userId = "user_id"
        case createdAt = "created_at"
        case updatedAt = "updated_at"
    }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(String.self, forKey: .id)
        userId = try container.decode(String.self, forKey: .userId)
        name = try container.decode(String.self, forKey: .name)
        description = try container.decodeIfPresent(String.self, forKey: .description)
        exercises = try container.decodeIfPresent([RoutineExercise].self, forKey: .exercises) ?? []
        createdAt = try container.decode(Date.self, forKey: .createdAt)
        updatedAt = try container.decode(Date.self, forKey: .updatedAt)
    }
}

struct RoutineExercise: Codable, Identifiable, Hashable {
    let id: String
    let exerciseId: String
    let exerciseName: String
    let exerciseOrder: Int
    let targetSets: Int
    let targetReps: String
    let targetWeight: Double?
    let restSeconds: Int
    let notes: String?
    
    enum CodingKeys: String, CodingKey {
        case id, notes
        case exerciseId = "exercise_id"
        case exerciseName = "exercise_name"
        case exerciseOrder = "exercise_order"
        case targetSets = "target_sets"
        case targetReps = "target_reps"
        case targetWeight = "target_weight"
        case restSeconds = "rest_seconds"
    }
}

struct RoutineRequest: Codable {
    let userId: String
    let name: String
    let description: String?
    
    enum CodingKeys: String, CodingKey {
        case name, description
        case userId = "user_id"
    }
}

struct RoutineExerciseRequest: Codable {
    let routineId: String
    let exerciseId: String
    let exerciseName: String
    let exerciseOrder: Int
    let targetSets: Int
    let targetReps: String
    let targetWeight: Double?
    let restSeconds: Int
    let notes: String?
    
    enum CodingKeys: String, CodingKey {
        case routineId = "routine_id"
        case exerciseId = "exercise_id"
        case exerciseName = "exercise_name"
        case exerciseOrder = "exercise_order"
        case targetSets = "target_sets"
        case targetReps = "target_reps"
        case targetWeight = "target_weight"
        case restSeconds = "rest_seconds"
        case notes
    }
}
