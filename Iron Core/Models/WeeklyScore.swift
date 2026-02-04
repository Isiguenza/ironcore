import Foundation

struct WeeklyScore: Codable, Identifiable {
    let id: Int64
    let userId: String
    let weekStart: Date
    let score: Int
    let components: ScoreComponents
    let createdAt: Date
    
    enum CodingKeys: String, CodingKey {
        case id
        case userId = "user_id"
        case weekStart = "week_start"
        case score
        case components
        case createdAt = "created_at"
    }
}

struct ScoreComponents: Codable {
    let consistency: Int
    let volume: Int
    let intensity: Int
    let recovery: Int
    
    var total: Int {
        consistency + volume + intensity + recovery
    }
}

struct WeeklyScoreRequest: Codable {
    let userId: String?
    let weekStart: String
    let score: Int
    let components: ScoreComponents
    
    enum CodingKeys: String, CodingKey {
        case userId = "user_id"
        case weekStart = "week_start"
        case score
        case components
    }
}
