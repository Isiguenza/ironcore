import Foundation
import Combine

@MainActor
class AuthViewModel: ObservableObject {
    @Published var isAuthenticated = false
    @Published var currentUserId: String?
    @Published var userProfile: UserProfile?
    @Published var currentUserName: String?
    @Published var isLoading = false
    @Published var errorMessage: String?
    
    private let authService = NeonAuthService.shared
    private let dataAPI = NeonDataAPIClient.shared
    private var tokenRefreshTimer: Timer?
    
    func checkAuthState() {
        print("🔑 [KEYCHAIN] Checking auth state...")
        
        if let token = KeychainStore.shared.getJWT() {
            print("✅ [KEYCHAIN] Token found: \(token.prefix(20))...")
            JWTHelper.printTokenInfo(token)
            
            // Check if token needs refresh
            Task {
                await refreshTokenIfNeeded()
            }
        } else {
            print("❌ [KEYCHAIN] No token found")
        }
        
        if let userId = KeychainStore.shared.getUserId() {
            print("✅ [KEYCHAIN] UserId found: \(userId)")
            
            if let userName = KeychainStore.shared.getUserName() {
                print("✅ [KEYCHAIN] UserName found: \(userName)")
                currentUserName = userName
            }
            
            isAuthenticated = true
            currentUserId = userId
            
            // Start periodic token refresh check
            startTokenRefreshTimer()
            
            Task {
                await loadUserProfile()
            }
        } else {
            print("❌ [KEYCHAIN] No userId found")
        }
    }
    
    private func startTokenRefreshTimer() {
        // Check token every 2 minutes
        tokenRefreshTimer?.invalidate()
        tokenRefreshTimer = Timer.scheduledTimer(withTimeInterval: 120, repeats: true) { [weak self] _ in
            Task { @MainActor in
                await self?.refreshTokenIfNeeded()
            }
        }
    }
    
    private func refreshTokenIfNeeded() async {
        guard authService.shouldRefreshToken() else {
            return
        }
        
        do {
            let newToken = try await authService.refreshToken()
            print("✅ [AUTH] Token auto-refreshed successfully")
            JWTHelper.printTokenInfo(newToken)
        } catch {
            print("❌ [AUTH] Auto-refresh failed: \(error)")
            // If refresh fails, user might need to sign in again
            if case NeonAuthError.sessionFailed = error {
                await MainActor.run {
                    self.signOut()
                }
            }
        }
    }
    
    func signUp(email: String, password: String, name: String, handle: String) async {
        isLoading = true
        errorMessage = nil
        
        do {
            print("👤 [AUTH] Starting sign up...")
            let (token, userId, userName) = try await authService.signUp(email: email, password: password, name: name)
            print("✅ [AUTH] Sign up successful - userId: \(userId)")
            
            try KeychainStore.shared.saveJWT(token)
            try KeychainStore.shared.saveUserId(userId)
            try KeychainStore.shared.saveUserName(userName)
            currentUserId = userId
            currentUserName = userName
            
            print("👤 [PROFILE] Creating profile with handle: \(handle), name: \(name), userId: \(userId)")
            let profileRequest = UserProfileRequest(userId: userId, handle: handle, displayName: name)
            let profiles: [UserProfile] = try await dataAPI.post(table: "profiles", body: profileRequest)
            print("✅ [PROFILE] Profile created successfully, count: \(profiles.count)")
            
            if let profile = profiles.first {
                userProfile = profile
                print("✅ [PROFILE] Profile assigned: \(profile.displayName)")
            } else {
                print("⚠️ [PROFILE] Profile response was empty")
            }
            
            print("⭐ [RATING] Creating default rating for userId: \(userId)")
            let ratingRequest = RatingRequest(userId: userId, mmr: 1000, lp: 0, rank: .untrained, division: 3)
            let ratings: [Rating] = try await dataAPI.post(table: "ratings", body: ratingRequest)
            print("✅ [RATING] Rating created successfully, count: \(ratings.count)")
            
            isAuthenticated = true
        } catch {
            print("❌ [AUTH] Sign up error: \(error)")
            print("❌ [AUTH] Error details: \(error.localizedDescription)")
            errorMessage = error.localizedDescription
        }
        
        isLoading = false
    }
    
    func signIn(email: String, password: String) async {
        isLoading = true
        errorMessage = nil
        
        do {
            print("👤 [AUTH] Starting sign in...")
            let (token, userId, userName) = try await authService.signIn(email: email, password: password)
            print("✅ [AUTH] Sign in successful - userId: \(userId)")
            
            print("🔑 [KEYCHAIN] Saving token: \(token.prefix(20))...")
            try KeychainStore.shared.saveJWT(token)
            print("✅ [KEYCHAIN] Token saved")
            
            print("🔑 [KEYCHAIN] Saving userId: \(userId)")
            try KeychainStore.shared.saveUserId(userId)
            print("✅ [KEYCHAIN] UserId saved")
            
            print("🔑 [KEYCHAIN] Saving userName: \(userName)")
            try KeychainStore.shared.saveUserName(userName)
            print("✅ [KEYCHAIN] UserName saved")
            
            currentUserId = userId
            currentUserName = userName
            
            print("👤 [PROFILE] Loading user profile...")
            await loadUserProfile()
            
            isAuthenticated = true
        } catch {
            print("❌ [AUTH] Sign in error: \(error)")
            print("❌ [AUTH] Error details: \(error.localizedDescription)")
            errorMessage = error.localizedDescription
        }
        
        isLoading = false
    }
    
    func signOut() {
        tokenRefreshTimer?.invalidate()
        tokenRefreshTimer = nil
        
        try? KeychainStore.shared.clearAll()
        isAuthenticated = false
        currentUserId = nil
        userProfile = nil
        currentUserName = nil
    }
    
    func loadUserProfile() async {
        guard let userId = currentUserId else {
            print("❌ [PROFILE] No userId available")
            return
        }
        
        print("👤 [PROFILE] Loading profile for userId: \(userId)")
        
        do {
            let profiles: [UserProfile] = try await dataAPI.get(table: "profiles", query: ["user_id": "eq.\(userId)"])
            if let profile = profiles.first {
                userProfile = profile
                print("✅ [PROFILE] Profile loaded: \(profile.displayName ?? "No name")")
            } else {
                print("⚠️ [PROFILE] No profile found, creating default profile...")
                await createDefaultProfileIfNeeded()
            }
        } catch {
            print("❌ [PROFILE] Failed to load user profile: \(error)")
            print("⚠️ [PROFILE] Attempting to create default profile...")
            await createDefaultProfileIfNeeded()
        }
    }
    
    private func createDefaultProfileIfNeeded() async {
        guard let userId = currentUserId else { return }
        
        let defaultHandle = "user_\(userId.prefix(8))"
        let defaultName = currentUserName ?? "Athlete"
        
        do {
            print("👤 [PROFILE] Creating default profile for userId: \(userId)")
            let profileRequest = UserProfileRequest(userId: userId, handle: defaultHandle, displayName: defaultName)
            let profiles: [UserProfile] = try await dataAPI.post(table: "profiles", body: profileRequest)
            
            if let profile = profiles.first {
                userProfile = profile
                print("✅ [PROFILE] Default profile created: \(profile.displayName ?? "No name")")
            }
            
            // Also create default rating
            print("⭐ [RATING] Creating default rating for userId: \(userId)")
            let ratingRequest = RatingRequest(userId: userId, mmr: 1000, lp: 0, rank: .untrained, division: 3)
            let _: [Rating] = try await dataAPI.post(table: "ratings", body: ratingRequest)
            print("✅ [PROFILE] Default rating created")
        } catch {
            print("❌ [PROFILE] Failed to create default profile: \(error)")
        }
    }
    
    private func extractUserIdFromJWT(_ jwt: String) throws -> String {
        let segments = jwt.components(separatedBy: ".")
        guard segments.count > 1 else {
            throw AuthError.invalidJWT
        }
        
        var base64 = segments[1]
        let remainder = base64.count % 4
        if remainder > 0 {
            base64 += String(repeating: "=", count: 4 - remainder)
        }
        
        guard let data = Data(base64Encoded: base64),
              let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
              let userId = json["sub"] as? String else {
            throw AuthError.invalidJWT
        }
        
        return userId
    }
}

struct UserProfileRequest: Codable {
    let userId: String
    let handle: String
    let displayName: String
    
    enum CodingKeys: String, CodingKey {
        case userId = "user_id"
        case handle
        case displayName = "display_name"
    }
}

struct RatingRequest: Codable {
    let userId: String
    let mmr: Int
    let lp: Int
    let rank: Rank
    let division: Int
    
    enum CodingKeys: String, CodingKey {
        case userId = "user_id"
        case mmr
        case lp
        case rank
        case division
    }
}

enum AuthError: LocalizedError {
    case invalidJWT
    
    var errorDescription: String? {
        switch self {
        case .invalidJWT:
            return "Invalid JWT token"
        }
    }
}
