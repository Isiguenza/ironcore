import Foundation

struct Exercise: Codable, Identifiable, Hashable {
    let id: String
    let name: String
    let category: ExerciseCategory
    let muscleGroup: MuscleGroup
    let equipment: Equipment
    let instructions: String?
    let videoUrl: String?
    
    enum CodingKeys: String, CodingKey {
        case id, name, category, instructions
        case muscleGroup = "muscle_group"
        case equipment
        case videoUrl = "video_url"
    }
}

enum ExerciseCategory: String, Codable, CaseIterable {
    case strength = "strength"
    case cardio = "cardio"
    case flexibility = "flexibility"
    case custom = "custom"
}

enum MuscleGroup: String, Codable, CaseIterable {
    case chest = "chest"
    case back = "back"
    case shoulders = "shoulders"
    case biceps = "biceps"
    case triceps = "triceps"
    case legs = "legs"
    case core = "core"
    case glutes = "glutes"
    case cardio = "cardio"
    case fullBody = "full_body"
    
    var displayName: String {
        switch self {
        case .chest: return "Chest"
        case .back: return "Back"
        case .shoulders: return "Shoulders"
        case .biceps: return "Biceps"
        case .triceps: return "Triceps"
        case .legs: return "Legs"
        case .core: return "Core"
        case .glutes: return "Glutes"
        case .cardio: return "Cardio"
        case .fullBody: return "Full Body"
        }
    }
}

enum Equipment: String, Codable, CaseIterable {
    case barbell = "barbell"
    case dumbbell = "dumbbell"
    case machine = "machine"
    case bodyweight = "bodyweight"
    case cable = "cable"
    case kettlebell = "kettlebell"
    case band = "band"
    case other = "other"
    
    var displayName: String {
        switch self {
        case .barbell: return "Barbell"
        case .dumbbell: return "Dumbbell"
        case .machine: return "Machine"
        case .bodyweight: return "Bodyweight"
        case .cable: return "Cable"
        case .kettlebell: return "Kettlebell"
        case .band: return "Band"
        case .other: return "Other"
        }
    }
}
