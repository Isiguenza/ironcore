import Foundation

struct Friendship: Codable, Identifiable {
    let id: Int64
    let requesterId: String
    let addresseeId: String
    let status: FriendshipStatus
    let createdAt: Date
    
    enum CodingKeys: String, CodingKey {
        case id
        case requesterId = "requester_id"
        case addresseeId = "addressee_id"
        case status
        case createdAt = "created_at"
    }
}

enum FriendshipStatus: String, Codable {
    case pending = "pending"
    case accepted = "accepted"
    case rejected = "rejected"
}

struct FriendRequest: Codable {
    let requesterId: String?
    let addresseeId: String
    let status: String
    
    enum CodingKeys: String, CodingKey {
        case requesterId = "requester_id"
        case addresseeId = "addressee_id"
        case status
    }
}

struct FriendWithScore: Identifiable {
    let id: String
    let profile: UserProfile
    let weeklyScore: WeeklyScore?
    let rating: Rating?
    
    var displayScore: Int {
        weeklyScore?.score ?? 0
    }
}
