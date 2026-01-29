import Foundation

class ExerciseDBAPIClient {
    static let shared = ExerciseDBAPIClient()
    private let baseURL = "https://www.ascendapi.com/api/v1"
    
    private init() {}
    
    func getExercises(offset: Int = 0, limit: Int = 50, sortBy: String? = nil, sortOrder: String? = nil) async throws -> ExerciseListResponse {
        var components = URLComponents(string: "\(baseURL)/exercises")!
        var queryItems: [URLQueryItem] = [
            URLQueryItem(name: "offset", value: "\(offset)"),
            URLQueryItem(name: "limit", value: "\(limit)")
        ]
        
        if let sortBy = sortBy {
            queryItems.append(URLQueryItem(name: "sortBy", value: sortBy))
        }
        
        if let sortOrder = sortOrder {
            queryItems.append(URLQueryItem(name: "sortOrder", value: sortOrder))
        }
        
        components.queryItems = queryItems
        
        guard let url = components.url else {
            throw ExerciseDBError.invalidURL
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        
        let (data, response) = try await URLSession.shared.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse else {
            throw ExerciseDBError.invalidResponse
        }
        
        guard (200...299).contains(httpResponse.statusCode) else {
            throw ExerciseDBError.requestFailed(httpResponse.statusCode)
        }
        
        let decoder = JSONDecoder()
        decoder.keyDecodingStrategy = .convertFromSnakeCase
        return try decoder.decode(ExerciseListResponse.self, from: data)
    }
    
    func searchExercisesByName(name: String) async throws -> [ExerciseDBItem] {
        var components = URLComponents(string: "\(baseURL)/exercises")!
        components.queryItems = [
            URLQueryItem(name: "limit", value: "10"),
            URLQueryItem(name: "offset", value: "0")
        ]
        
        guard let url = components.url else {
            throw ExerciseDBError.invalidURL
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        
        let (data, response) = try await URLSession.shared.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse else {
            throw ExerciseDBError.invalidResponse
        }
        
        guard (200...299).contains(httpResponse.statusCode) else {
            throw ExerciseDBError.requestFailed(httpResponse.statusCode)
        }
        
        let decoder = JSONDecoder()
        decoder.keyDecodingStrategy = .convertFromSnakeCase
        let apiResponse = try decoder.decode(ExerciseListResponse.self, from: data)
        
        // Filter by name similarity
        let searchName = name.lowercased().trimmingCharacters(in: .whitespaces)
        return apiResponse.data.filter { exercise in
            exercise.name.lowercased().contains(searchName) ||
            searchName.contains(exercise.name.lowercased())
        }
    }
    
    func getExerciseDetails(exerciseId: String) async throws -> ExerciseDetail {
        guard let url = URL(string: "\(baseURL)/exercises/\(exerciseId)") else {
            throw ExerciseDBError.invalidURL
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        
        let (data, response) = try await URLSession.shared.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse else {
            throw ExerciseDBError.invalidResponse
        }
        
        guard (200...299).contains(httpResponse.statusCode) else {
            throw ExerciseDBError.requestFailed(httpResponse.statusCode)
        }
        
        let decoder = JSONDecoder()
        decoder.keyDecodingStrategy = .convertFromSnakeCase
        let wrapper = try decoder.decode(ExerciseDetailResponse.self, from: data)
        return wrapper.data
    }
}

// MARK: - Response Models

struct ExerciseListResponse: Codable {
    let success: Bool
    let metadata: ExerciseMetadata
    let data: [ExerciseDBItem]
}

struct ExerciseMetadata: Codable {
    let totalPages: Int
    let totalExercises: Int
    let currentPage: Int
    let previousPage: String?
    let nextPage: String?
}

struct ExerciseDBItem: Codable, Identifiable {
    let exerciseId: String
    let name: String
    let gifUrl: String
    let targetMuscles: [String]
    let bodyParts: [String]
    let equipments: [String]
    let secondaryMuscles: [String]
    let instructions: [String]
    
    var id: String { exerciseId }
}

struct ExerciseDetailResponse: Codable {
    let success: Bool
    let data: ExerciseDetail
}

struct ExerciseDetail: Codable {
    let exerciseId: String
    let name: String
    let gifUrl: String
    let targetMuscles: [String]
    let bodyParts: [String]
    let equipments: [String]
    let secondaryMuscles: [String]
    let instructions: [String]
}

enum ExerciseDBError: LocalizedError {
    case invalidURL
    case invalidResponse
    case requestFailed(Int)
    
    var errorDescription: String? {
        switch self {
        case .invalidURL:
            return "Invalid URL"
        case .invalidResponse:
            return "Invalid response from server"
        case .requestFailed(let code):
            return "Request failed with status code: \(code)"
        }
    }
}
