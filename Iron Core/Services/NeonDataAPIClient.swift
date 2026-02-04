import Foundation

class NeonDataAPIClient {
    static let shared = NeonDataAPIClient()
    let baseURL = Config.dataAPIRestURL
    
    private init() {}
    
    func get<T: Decodable>(table: String, query: [String: String] = [:]) async throws -> [T] {
        var components = URLComponents(string: "\(baseURL)/\(table)")!
        components.queryItems = query.map { URLQueryItem(name: $0.key, value: $0.value) }
        
        guard let url = components.url else {
            throw DataAPIError.invalidURL
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        try addAuthHeaders(to: &request)
        
        do {
            let (data, response) = try await URLSession.shared.data(for: request)
            try handleResponse(response, data: data)
            
            let decoder = JSONDecoder.neonDecoder
            return try decoder.decode([T].self, from: data)
        } catch DataAPIError.unauthorized {
            // Try to refresh token and retry once
            print("🔄 [API] Token expired, attempting refresh...")
            try await NeonAuthService.shared.refreshToken()
            
            // Retry with new token
            request = URLRequest(url: url)
            request.httpMethod = "GET"
            try addAuthHeaders(to: &request)
            
            let (data, response) = try await URLSession.shared.data(for: request)
            try handleResponse(response, data: data)
            
            let decoder = JSONDecoder.neonDecoder
            return try decoder.decode([T].self, from: data)
        }
    }
    
    func post<T: Encodable, R: Decodable>(table: String, body: T, prefer: String = "return=representation") async throws -> [R] {
        guard let url = URL(string: "\(baseURL)/\(table)") else {
            throw DataAPIError.invalidURL
        }
        
        let encoder = JSONEncoder.neonEncoder
        let bodyData = try encoder.encode(body)
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        try addAuthHeaders(to: &request)
        request.setValue(prefer, forHTTPHeaderField: "Prefer")
        request.httpBody = bodyData
        
        do {
            let (data, response) = try await URLSession.shared.data(for: request)
            try handleResponse(response, data: data)
            
            let decoder = JSONDecoder.neonDecoder
            return try decoder.decode([R].self, from: data)
        } catch DataAPIError.unauthorized {
            // Try to refresh token and retry once
            print("🔄 [API] Token expired, attempting refresh...")
            try await NeonAuthService.shared.refreshToken()
            
            // Retry with new token
            request = URLRequest(url: url)
            request.httpMethod = "POST"
            try addAuthHeaders(to: &request)
            request.setValue(prefer, forHTTPHeaderField: "Prefer")
            request.httpBody = bodyData
            
            let (data, response) = try await URLSession.shared.data(for: request)
            try handleResponse(response, data: data)
            
            let decoder = JSONDecoder.neonDecoder
            return try decoder.decode([R].self, from: data)
        }
    }
    
    func patch<T: Encodable, R: Decodable>(table: String, body: T, query: [String: String], prefer: String = "return=representation") async throws -> [R] {
        var components = URLComponents(string: "\(baseURL)/\(table)")!
        components.queryItems = query.map { URLQueryItem(name: $0.key, value: $0.value) }
        
        guard let url = components.url else {
            throw DataAPIError.invalidURL
        }
        
        let encoder = JSONEncoder.neonEncoder
        let bodyData = try encoder.encode(body)
        
        var request = URLRequest(url: url)
        request.httpMethod = "PATCH"
        try addAuthHeaders(to: &request)
        request.setValue(prefer, forHTTPHeaderField: "Prefer")
        request.httpBody = bodyData
        
        do {
            let (data, response) = try await URLSession.shared.data(for: request)
            try handleResponse(response, data: data)
            
            let decoder = JSONDecoder.neonDecoder
            return try decoder.decode([R].self, from: data)
        } catch DataAPIError.unauthorized {
            // Try to refresh token and retry once
            print("🔄 [API] Token expired, attempting refresh...")
            try await NeonAuthService.shared.refreshToken()
            
            // Retry with new token
            request = URLRequest(url: url)
            request.httpMethod = "PATCH"
            try addAuthHeaders(to: &request)
            request.setValue(prefer, forHTTPHeaderField: "Prefer")
            request.httpBody = bodyData
            
            let (data, response) = try await URLSession.shared.data(for: request)
            try handleResponse(response, data: data)
            
            let decoder = JSONDecoder.neonDecoder
            return try decoder.decode([R].self, from: data)
        }
    }
    
    func delete<T: Decodable>(table: String, query: [String: String]) async throws -> [T] {
        var components = URLComponents(string: "\(baseURL)/\(table)")!
        components.queryItems = query.map { URLQueryItem(name: $0.key, value: $0.value) }
        
        guard let url = components.url else {
            throw DataAPIError.invalidURL
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "DELETE"
        try addAuthHeaders(to: &request)
        
        do {
            let (data, response) = try await URLSession.shared.data(for: request)
            try handleResponse(response, data: data)
            return []
        } catch DataAPIError.unauthorized {
            // Try to refresh token and retry once
            print("🔄 [API] Token expired, attempting refresh...")
            try await NeonAuthService.shared.refreshToken()
            
            // Retry with new token
            request = URLRequest(url: url)
            request.httpMethod = "DELETE"
            try addAuthHeaders(to: &request)
            
            let (data, response) = try await URLSession.shared.data(for: request)
            try handleResponse(response, data: data)
            return []
        }
    }
    
    private func addAuthHeaders(to request: inout URLRequest) throws {
        // According to Neon docs: All Data API requests require JWT authentication
        // The JWT must include a 'sub' claim with the user's ID for RLS to work
        guard let jwt = KeychainStore.shared.getJWT() else {
            throw DataAPIError.notAuthenticated
        }
        
        print("🔑 [API] Using JWT token: \(jwt.prefix(30))...")
        request.setValue("Bearer \(jwt)", forHTTPHeaderField: "Authorization")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
    }
    
    private func handleResponse(_ response: URLResponse, data: Data) throws {
        guard let httpResponse = response as? HTTPURLResponse else {
            throw DataAPIError.invalidResponse
        }
        
        print("🌐 [API] Response status: \(httpResponse.statusCode)")
        
        if httpResponse.statusCode == 401 {
            print("❌ [API] Unauthorized - JWT may be invalid or expired")
            // Let the caller handle token refresh and retry
            throw DataAPIError.unauthorized
        }
        
        if httpResponse.statusCode == 400 {
            print("❌ [API] Bad Request - Check RLS policies and schema")
            print("❌ [API] URL: \(httpResponse.url?.absoluteString ?? "unknown")")
            
            // Print the actual error response from Neon
            if let errorString = String(data: data, encoding: .utf8) {
                print("❌ [API] Error response: \(errorString)")
            }
        }
        
        guard (200...299).contains(httpResponse.statusCode) else {
            throw DataAPIError.requestFailed(httpResponse.statusCode)
        }
    }
    
    // MARK: - Exercise Detail Methods
    
    func getExerciseHistory(userId: String, exerciseId: String) async throws -> [WorkoutHistoryItem] {
        // Get workout history grouped by session
        let query = [
            "select": "session_id:ws.id,workout_name:ws.routine_name,date:ws.start_time,set_number:wsets.set_number,weight:wsets.weight,reps:wsets.reps",
            "ws.user_id": "eq.\(userId)",
            "we.exercise_id": "eq.\(exerciseId)",
            "ws.end_time": "not.is.null",
            "order": "ws.start_time.desc,wsets.set_number.asc",
            "limit": "100"
        ]
        
        // This requires a JOIN which PostgREST doesn't support directly
        // We'll need to use a custom RPC or view
        // For now, fetch workout_sessions and workout_sets separately
        
        struct WorkoutSessionData: Codable {
            let id: String
            let routineName: String?
            let startTime: Date
            
            enum CodingKeys: String, CodingKey {
                case id
                case routineName = "routine_name"
                case startTime = "start_time"
            }
        }
        
        // Get sessions where this exercise was performed
        let sessions: [WorkoutSessionData] = try await get(
            table: "workout_sessions",
            query: [
                "user_id": "eq.\(userId)",
                "end_time": "not.is.null",
                "order": "start_time.desc",
                "limit": "20"
            ]
        )
        
        var historyItems: [WorkoutHistoryItem] = []
        
        for session in sessions {
            // Get exercises for this session
            struct WorkoutExerciseData: Codable {
                let id: String
                let exerciseId: String
                
                enum CodingKeys: String, CodingKey {
                    case id
                    case exerciseId = "exercise_id"
                }
            }
            
            let exercises: [WorkoutExerciseData] = try await get(
                table: "workout_exercises",
                query: [
                    "session_id": "eq.\(session.id)",
                    "exercise_id": "eq.\(exerciseId)"
                ]
            )
            
            guard let workoutExercise = exercises.first else { continue }
            
            // Get sets for this exercise
            struct WorkoutSetData: Codable {
                let setNumber: Int
                let weight: Double
                let reps: Int
                
                enum CodingKeys: String, CodingKey {
                    case setNumber = "set_number"
                    case weight
                    case reps
                }
            }
            
            let sets: [WorkoutSetData] = try await get(
                table: "workout_sets",
                query: [
                    "workout_exercise_id": "eq.\(workoutExercise.id)",
                    "order": "set_number.asc"
                ]
            )
            
            if !sets.isEmpty {
                let historyItem = WorkoutHistoryItem(
                    sessionId: session.id,
                    workoutName: session.routineName ?? "Workout",
                    date: session.startTime,
                    sets: sets.map { HistoricalSet(setNumber: $0.setNumber, weight: $0.weight, reps: $0.reps) }
                )
                historyItems.append(historyItem)
            }
        }
        
        return historyItems
    }
    
    func getPersonalRecords(userId: String, exerciseId: String) async throws -> PersonalRecordsData {
        struct PRData: Codable {
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
        
        let records: [PRData] = try await get(
            table: "personal_records",
            query: [
                "user_id": "eq.\(userId)",
                "exercise_id": "eq.\(exerciseId)",
                "order": "weight.desc,volume.desc",
                "limit": "2"
            ]
        )
        
        let maxWeight = records.first.map { PersonalRecord(weight: $0.weight, reps: $0.reps, volume: $0.volume, achievedAt: $0.achievedAt) }
        let best1RM = records.count > 1 ? PersonalRecord(weight: records[1].weight, reps: records[1].reps, volume: records[1].volume, achievedAt: records[1].achievedAt) : nil
        
        return PersonalRecordsData(maxWeight: maxWeight, best1RM: best1RM)
    }
    
    func getExerciseStats(userId: String, exerciseId: String, limit: Int = 365) async throws -> [ExerciseStats] {
        struct StatsData: Codable {
            let date: Date
            let maxWeight: Double?
            let totalVolume: Double?
            let totalSets: Int?
            
            enum CodingKeys: String, CodingKey {
                case date
                case maxWeight = "max_weight"
                case totalVolume = "total_volume"
                case totalSets = "total_sets"
            }
        }
        
        let stats: [StatsData] = try await get(
            table: "exercise_history",
            query: [
                "user_id": "eq.\(userId)",
                "exercise_id": "eq.\(exerciseId)",
                "order": "date.desc",
                "limit": "\(limit)"
            ]
        )
        
        return stats.map { ExerciseStats(date: $0.date, maxWeight: $0.maxWeight ?? 0, totalVolume: $0.totalVolume ?? 0, totalSets: $0.totalSets ?? 0) }
    }
    
    func getLastPerformedWeights(userId: String, exerciseId: String) async throws -> [Int: Double] {
        // Get most recent session with this exercise
        struct SessionData: Codable {
            let id: String
            let startTime: Date
            
            enum CodingKeys: String, CodingKey {
                case id
                case startTime = "start_time"
            }
        }
        
        let sessions: [SessionData] = try await get(
            table: "workout_sessions",
            query: [
                "user_id": "eq.\(userId)",
                "end_time": "not.is.null",
                "order": "start_time.desc",
                "limit": "10"
            ]
        )
        
        for session in sessions {
            struct WorkoutExerciseData: Codable {
                let id: String
                let exerciseId: String
                
                enum CodingKeys: String, CodingKey {
                    case id
                    case exerciseId = "exercise_id"
                }
            }
            
            let exercises: [WorkoutExerciseData] = try await get(
                table: "workout_exercises",
                query: [
                    "session_id": "eq.\(session.id)",
                    "exercise_id": "eq.\(exerciseId)"
                ]
            )
            
            guard let workoutExercise = exercises.first else { continue }
            
            struct WorkoutSetData: Codable {
                let setNumber: Int
                let weight: Double
                
                enum CodingKeys: String, CodingKey {
                    case setNumber = "set_number"
                    case weight
                }
            }
            
            let sets: [WorkoutSetData] = try await get(
                table: "workout_sets",
                query: [
                    "workout_exercise_id": "eq.\(workoutExercise.id)",
                    "order": "set_number.asc"
                ]
            )
            
            if !sets.isEmpty {
                var lastWeights: [Int: Double] = [:]
                for set in sets {
                    lastWeights[set.setNumber] = set.weight
                }
                return lastWeights
            }
        }
        
        return [:]
    }
}

enum DataAPIError: LocalizedError {
    case invalidURL
    case notAuthenticated
    case invalidResponse
    case unauthorized
    case requestFailed(Int)
    
    var errorDescription: String? {
        switch self {
        case .invalidURL:
            return "Invalid URL"
        case .notAuthenticated:
            return "Not authenticated. Please sign in again."
        case .invalidResponse:
            return "Invalid response from server"
        case .unauthorized:
            return "Unauthorized. Your session may have expired."
        case .requestFailed(let code):
            return "Request failed with status code: \(code)"
        }
    }
}
