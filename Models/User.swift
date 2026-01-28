import Foundation

struct UserProfile: Codable, Identifiable {
    let userId: String
    let handle: String
    let displayName: String
    let createdAt: Date
    
    var id: String { userId }
    
    enum CodingKeys: String, CodingKey {
        case userId = "user_id"
        case handle
        case displayName = "display_name"
        case createdAt = "created_at"
    }
}

struct Rating: Codable {
    let userId: String
    var mmr: Int
    var lp: Int
    var rank: Rank
    var division: Int?
    let updatedAt: Date
    
    enum CodingKeys: String, CodingKey {
        case userId = "user_id"
        case mmr
        case lp
        case rank
        case division
        case updatedAt = "updated_at"
    }
}

enum Rank: String, Codable, CaseIterable {
    case untrained = "UNTRAINED"
    case conditioned = "CONDITIONED"
    case strong = "STRONG"
    case athletic = "ATHLETIC"
    case elite = "ELITE"
    case forged = "FORGED"
    
    var color: String {
        switch self {
        case .untrained: return "bronze"
        case .conditioned: return "green"
        case .strong: return "blue"
        case .athletic: return "yellow"
        case .elite: return "orange"
        case .forged: return "red"
        }
    }
    
    var lpThreshold: Int {
        switch self {
        case .untrained: return 0
        case .conditioned: return 500
        case .strong: return 1000
        case .athletic: return 1500
        case .elite: return 2000
        case .forged: return 2500
        }
    }
}
