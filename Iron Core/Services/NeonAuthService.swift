import Foundation

class NeonAuthService {
    static let shared = NeonAuthService()
    private let baseURL = Config.neonAuthURL
    
    private let urlSession: URLSession
    private var lastTokenRefresh: Date?
    private var isRefreshing = false
    
    private init() {
        let configuration = URLSessionConfiguration.default
        configuration.httpCookieAcceptPolicy = .always
        configuration.httpCookieStorage = HTTPCookieStorage.shared
        configuration.httpShouldSetCookies = true
        self.urlSession = URLSession(configuration: configuration)
    }
    
    func signUp(email: String, password: String, name: String) async throws -> (token: String, userId: String, userName: String) {
        let url = URL(string: "\(baseURL)/sign-up/email")!
        print("🔵 [AUTH] Sign up URL: \(url.absoluteString)")
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("https://ironcore.app", forHTTPHeaderField: "Origin")
        
        let body = SignUpRequest(email: email, password: password, name: name)
        request.httpBody = try JSONEncoder().encode(body)
        
        print("🔵 [AUTH] Request body: \(String(data: request.httpBody ?? Data(), encoding: .utf8) ?? "nil")")
        
        let (data, response) = try await urlSession.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse else {
            print("🔴 [AUTH] Invalid response type")
            throw NeonAuthError.invalidResponse
        }
        
        print("🔵 [AUTH] Response status: \(httpResponse.statusCode)")
        print("🔵 [AUTH] Response headers: \(httpResponse.allHeaderFields)")
        print("🔵 [AUTH] Response body: \(String(data: data, encoding: .utf8) ?? "nil")")
        
        if httpResponse.statusCode == 200 || httpResponse.statusCode == 201 {
            print("✅ [AUTH] Sign up successful, extracting token...")
            
            if let successResponse = try? JSONDecoder().decode(AuthSuccessResponse.self, from: data) {
                let sessionToken = successResponse.token
                let userId = successResponse.user.id
                let userName = successResponse.user.name ?? successResponse.user.email
                
                print("✅ [AUTH] Session token: \(sessionToken.prefix(20))...")
                print("✅ [AUTH] User ID: \(userId)")
                print("✅ [AUTH] User Name: \(userName)")
                
                // Now get the JWT token from /auth/token endpoint
                print("🔑 [AUTH] Fetching JWT access token...")
                let jwt = try await getAccessToken()
                print("✅ [AUTH] JWT token obtained: \(jwt.prefix(30))...")
                
                return (token: jwt, userId: userId, userName: userName)
            }
            
            print("🔴 [AUTH] Failed to decode success response")
            throw NeonAuthError.signUpFailed
        }
        
        if let errorResponse = try? JSONDecoder().decode(AuthErrorResponse.self, from: data),
           let message = errorResponse.message {
            print("🔴 [AUTH] Server error: \(message)")
            throw NeonAuthError.serverError(message)
        }
        
        print("🔴 [AUTH] Sign up failed with status \(httpResponse.statusCode)")
        throw NeonAuthError.signUpFailed
    }
    
    func signIn(email: String, password: String) async throws -> (token: String, userId: String, userName: String) {
        let url = URL(string: "\(baseURL)/sign-in/email")!
        print("🔵 [AUTH] Sign in URL: \(url.absoluteString)")
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("https://ironcore.app", forHTTPHeaderField: "Origin")
        
        let body = SignInRequest(email: email, password: password)
        request.httpBody = try JSONEncoder().encode(body)
        
        print("🔵 [AUTH] Request body: \(String(data: request.httpBody ?? Data(), encoding: .utf8) ?? "nil")")
        
        let (data, response) = try await urlSession.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse else {
            print("🔴 [AUTH] Invalid response type")
            throw NeonAuthError.invalidResponse
        }
        
        print("🔵 [AUTH] Response status: \(httpResponse.statusCode)")
        print("🔵 [AUTH] Response body: \(String(data: data, encoding: .utf8) ?? "nil")")
        
        if httpResponse.statusCode == 200 {
            print("✅ [AUTH] Sign in successful, extracting token...")
            
            if let successResponse = try? JSONDecoder().decode(AuthSuccessResponse.self, from: data) {
                let sessionToken = successResponse.token
                let userId = successResponse.user.id
                let userName = successResponse.user.name ?? successResponse.user.email
                
                print("✅ [AUTH] Session token: \(sessionToken.prefix(20))...")
                print("✅ [AUTH] User ID: \(userId)")
                print("✅ [AUTH] User Name: \(userName)")
                
                // Now get the JWT token from /auth/token endpoint
                print("🔑 [AUTH] Fetching JWT access token...")
                let jwt = try await getAccessToken()
                print("✅ [AUTH] JWT token obtained: \(jwt.prefix(30))...")
                
                return (token: jwt, userId: userId, userName: userName)
            }
            
            print("🔴 [AUTH] Failed to decode success response")
            throw NeonAuthError.signInFailed
        }
        
        if let errorResponse = try? JSONDecoder().decode(AuthErrorResponse.self, from: data),
           let message = errorResponse.message {
            print("🔴 [AUTH] Server error: \(message)")
            throw NeonAuthError.serverError(message)
        }
        
        print("🔴 [AUTH] Sign in failed with status \(httpResponse.statusCode)")
        throw NeonAuthError.signInFailed
    }
    
    func getAccessToken() async throws -> String {
        let url = URL(string: "\(baseURL)/token")!
        print("🔵 [AUTH] Get access token URL: \(url.absoluteString)")
        
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.setValue("https://ironcore.app", forHTTPHeaderField: "Origin")
        
        let (data, response) = try await urlSession.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse else {
            print("🔴 [AUTH] Invalid response type")
            throw NeonAuthError.invalidResponse
        }
        
        print("🔵 [AUTH] Token response status: \(httpResponse.statusCode)")
        print("🔵 [AUTH] Token response body: \(String(data: data, encoding: .utf8) ?? "nil")")
        
        guard httpResponse.statusCode == 200 else {
            print("🔴 [AUTH] Token fetch failed with status \(httpResponse.statusCode)")
            throw NeonAuthError.sessionFailed
        }
        
        // Try to parse the JWT token from response
        if let tokenResponse = try? JSONDecoder().decode([String: String].self, from: data),
           let accessToken = tokenResponse["access_token"] ?? tokenResponse["token"] {
            print("✅ [AUTH] Access token found in response body")
            lastTokenRefresh = Date()
            return accessToken
        }
        
        print("🔴 [AUTH] Access token not found in response")
        throw NeonAuthError.jwtNotFound
    }
    
    /// Refresh the access token using the existing session cookie
    func refreshToken() async throws -> String {
        // Prevent concurrent refresh attempts
        guard !isRefreshing else {
            print("⏳ [AUTH] Token refresh already in progress, waiting...")
            try await Task.sleep(nanoseconds: 1_000_000_000) // Wait 1 second
            
            // Check if we have a fresh token now
            if let token = KeychainStore.shared.getJWT(),
               let decoded = JWTHelper.decode(token),
               !decoded.isExpired {
                print("✅ [AUTH] Fresh token available after waiting")
                return token
            }
            
            throw NeonAuthError.refreshInProgress
        }
        
        // Check if we refreshed recently (within last 10 seconds) to avoid loops
        if let lastRefresh = lastTokenRefresh,
           Date().timeIntervalSince(lastRefresh) < 10 {
            print("⏳ [AUTH] Token was just refreshed, skipping")
            if let token = KeychainStore.shared.getJWT() {
                return token
            }
        }
        
        isRefreshing = true
        defer { isRefreshing = false }
        
        print("🔄 [AUTH] Refreshing access token...")
        
        do {
            let newToken = try await getAccessToken()
            
            // Save the new token
            try KeychainStore.shared.saveJWT(newToken)
            print("✅ [AUTH] Token refreshed and saved")
            
            // Print token info
            JWTHelper.printTokenInfo(newToken)
            
            return newToken
        } catch {
            print("❌ [AUTH] Token refresh failed: \(error)")
            throw error
        }
    }
    
    /// Check if the current token needs refresh
    func shouldRefreshToken() -> Bool {
        guard let token = KeychainStore.shared.getJWT(),
              let decoded = JWTHelper.decode(token) else {
            print("⚠️ [AUTH] No valid token found")
            return false
        }
        
        if decoded.isExpired {
            print("⚠️ [AUTH] Token is expired")
            return true
        }
        
        if decoded.isExpiringSoon {
            print("⚠️ [AUTH] Token expiring soon")
            return true
        }
        
        return false
    }
}

enum NeonAuthError: LocalizedError {
    case invalidResponse
    case signUpFailed
    case signInFailed
    case sessionFailed
    case jwtNotFound
    case serverError(String)
    case refreshInProgress
    
    var errorDescription: String? {
        switch self {
        case .invalidResponse:
            return "Invalid response from server"
        case .signUpFailed:
            return "Sign up failed"
        case .signInFailed:
            return "Sign in failed. Please check your credentials."
        case .sessionFailed:
            return "Failed to get session"
        case .jwtNotFound:
            return "JWT not found in response"
        case .serverError(let message):
            return message
        case .refreshInProgress:
            return "Token refresh already in progress"
        }
    }
}
