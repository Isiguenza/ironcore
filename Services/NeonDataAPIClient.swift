import Foundation

class NeonDataAPIClient {
    static let shared = NeonDataAPIClient()
    private let baseURL = Config.dataAPIRestURL
    
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
        
        let (data, response) = try await URLSession.shared.data(for: request)
        
        try handleResponse(response, data: data)
        
        let decoder = JSONDecoder.neonDecoder
        return try decoder.decode([T].self, from: data)
    }
    
    func post<T: Encodable, R: Decodable>(table: String, body: T, prefer: String = "return=representation") async throws -> [R] {
        guard let url = URL(string: "\(baseURL)/\(table)") else {
            throw DataAPIError.invalidURL
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        try addAuthHeaders(to: &request)
        request.setValue(prefer, forHTTPHeaderField: "Prefer")
        
        let encoder = JSONEncoder.neonEncoder
        request.httpBody = try encoder.encode(body)
        
        let (data, response) = try await URLSession.shared.data(for: request)
        
        try handleResponse(response, data: data)
        
        let decoder = JSONDecoder.neonDecoder
        return try decoder.decode([R].self, from: data)
    }
    
    func patch<T: Encodable, R: Decodable>(table: String, body: T, query: [String: String], prefer: String = "return=representation") async throws -> [R] {
        var components = URLComponents(string: "\(baseURL)/\(table)")!
        components.queryItems = query.map { URLQueryItem(name: $0.key, value: $0.value) }
        
        guard let url = components.url else {
            throw DataAPIError.invalidURL
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "PATCH"
        try addAuthHeaders(to: &request)
        request.setValue(prefer, forHTTPHeaderField: "Prefer")
        
        let encoder = JSONEncoder.neonEncoder
        request.httpBody = try encoder.encode(body)
        
        let (data, response) = try await URLSession.shared.data(for: request)
        
        try handleResponse(response, data: data)
        
        let decoder = JSONDecoder.neonDecoder
        return try decoder.decode([R].self, from: data)
    }
    
    func delete(table: String, query: [String: String]) async throws {
        var components = URLComponents(string: "\(baseURL)/\(table)")!
        components.queryItems = query.map { URLQueryItem(name: $0.key, value: $0.value) }
        
        guard let url = components.url else {
            throw DataAPIError.invalidURL
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "DELETE"
        try addAuthHeaders(to: &request)
        
        let (data, response) = try await URLSession.shared.data(for: request)
        
        try handleResponse(response, data: data)
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
