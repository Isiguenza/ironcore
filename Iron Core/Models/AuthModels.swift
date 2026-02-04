import Foundation

struct SignUpRequest: Codable {
    let email: String
    let password: String
    let name: String
}

struct SignInRequest: Codable {
    let email: String
    let password: String
}

struct AuthSuccessResponse: Codable {
    let token: String
    let user: AuthUser
    let redirect: Bool?
}

struct AuthUser: Codable {
    let id: String
    let name: String?
    let email: String
    let emailVerified: Bool
    let image: String?
    let createdAt: String?
    let updatedAt: String?
    let role: String?
    let banned: Bool?
    let banReason: String?
    let banExpires: String?
}

struct AuthErrorResponse: Codable {
    let message: String?
    let code: String?
    let error: String?
}
