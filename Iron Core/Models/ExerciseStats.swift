import Foundation

// MARK: - Exercise History Models

struct WorkoutHistoryItem: Codable, Identifiable {
    let id: String
    let workoutName: String
    let date: Date
    let sets: [HistoricalSet]
    
    init(sessionId: String, workoutName: String, date: Date, sets: [HistoricalSet]) {
        self.id = sessionId
        self.workoutName = workoutName
        self.date = date
        self.sets = sets
    }
}

struct ExerciseHistoryData: Codable {
    let workoutName: String
    let date: Date
    let sets: [HistoricalSet]
    
    enum CodingKeys: String, CodingKey {
        case workoutName = "routine_name"
        case date = "start_time"
        case sets
    }
}

struct HistoricalSet: Codable {
    let setNumber: Int
    let weight: Double
    let reps: Int
    
    enum CodingKeys: String, CodingKey {
        case setNumber = "set_number"
        case weight
        case reps
    }
}

// MARK: - Personal Records

struct PersonalRecord: Codable {
    let weight: Double
    let reps: Int
    let volume: Double
    let achievedAt: Date
    
    enum CodingKeys: String, CodingKey {
        case weight
        case reps
        case volume
        case achievedAt = "achieved_at"
    }
}

struct PersonalRecordsData {
    let maxWeight: PersonalRecord?
    let best1RM: PersonalRecord?
}

// MARK: - Exercise Stats (for charts)

struct ExerciseStats: Codable {
    let date: Date
    let maxWeight: Double
    let totalVolume: Double
    let totalSets: Int
    
    enum CodingKeys: String, CodingKey {
        case date
        case maxWeight = "max_weight"
        case totalVolume = "total_volume"
        case totalSets = "total_sets"
    }
}

// MARK: - API Response Models

struct ExerciseHistoryResponse: Codable {
    let history: [ExerciseHistoryData]
}

struct PersonalRecordsResponse: Codable {
    let maxWeight: PersonalRecord?
    let best1RM: PersonalRecord?
    
    enum CodingKeys: String, CodingKey {
        case maxWeight = "max_weight"
        case best1RM = "best_1rm"
    }
}

struct ExerciseStatsResponse: Codable {
    let stats: [ExerciseStats]
}
