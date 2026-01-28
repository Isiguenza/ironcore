import Foundation
import SwiftUI
import HealthKit

extension HKWorkoutActivityType {
    var name: String {
        switch self {
        case .running: return "Running"
        case .cycling: return "Cycling"
        case .walking: return "Walking"
        case .swimming: return "Swimming"
        case .yoga: return "Yoga"
        case .functionalStrengthTraining: return "Strength Training"
        case .traditionalStrengthTraining: return "Weight Training"
        case .coreTraining: return "Core Training"
        case .flexibility: return "Flexibility"
        case .highIntensityIntervalTraining: return "HIIT"
        case .crossTraining: return "Cross Training"
        case .elliptical: return "Elliptical"
        case .rowing: return "Rowing"
        case .stairs: return "Stairs"
        case .stepTraining: return "Step Training"
        case .dance: return "Dance"
        case .barre: return "Barre"
        case .soccer: return "Soccer"
        case .basketball: return "Basketball"
        case .tennis: return "Tennis"
        default: return "Other Workout"
        }
    }
}

extension Date {
    func startOfWeek() -> Date {
        let calendar = Calendar.current
        let components = calendar.dateComponents([.yearForWeekOfYear, .weekOfYear], from: self)
        return calendar.date(from: components) ?? self
    }
    
    func toISOString() -> String {
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        return formatter.string(from: self)
    }
    
    func toDateString() -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        return formatter.string(from: self)
    }
}

extension Color {
    static let neonGreen = Color(red: 0.8, green: 1.0, blue: 0.2)
    static let neonYellow = Color(red: 1.0, green: 1.0, blue: 0.2)
    static let neonOrange = Color(red: 1.0, green: 0.6, blue: 0.2)
    static let neonPink = Color(red: 1.0, green: 0.2, blue: 0.6)
    static let neonCyan = Color(red: 0.2, green: 0.8, blue: 1.0)
    static let neonPurple = Color(red: 0.6, green: 0.2, blue: 1.0)
    
    static let cardBackground = Color(white: 0.12)
    static let secondaryBackground = Color(white: 0.08)
}

extension JSONDecoder {
    static let neonDecoder: JSONDecoder = {
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .custom { decoder in
            let container = try decoder.singleValueContainer()
            let dateString = try container.decode(String.self)
            
            if let date = ISO8601DateFormatter().date(from: dateString) {
                return date
            }
            
            let dateFormatters = [
                "yyyy-MM-dd'T'HH:mm:ss.SSSSSSZ",
                "yyyy-MM-dd'T'HH:mm:ssZ",
                "yyyy-MM-dd'T'HH:mm:ss.SSSZ",
                "yyyy-MM-dd"
            ]
            
            for format in dateFormatters {
                let formatter = DateFormatter()
                formatter.dateFormat = format
                formatter.locale = Locale(identifier: "en_US_POSIX")
                formatter.timeZone = TimeZone(secondsFromGMT: 0)
                if let date = formatter.date(from: dateString) {
                    return date
                }
            }
            
            throw DecodingError.dataCorruptedError(in: container, debugDescription: "Cannot decode date string \(dateString)")
        }
        return decoder
    }()
}

extension JSONEncoder {
    static let neonEncoder: JSONEncoder = {
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .custom { date, encoder in
            var container = encoder.singleValueContainer()
            try container.encode(date.toISOString())
        }
        return encoder
    }()
}
