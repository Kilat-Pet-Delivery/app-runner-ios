import Foundation

struct LoginRequest: Encodable, Equatable {
    let email: String
    let password: String
}

struct LoginResponse: Decodable, Equatable {
    let accessToken: String
    let refreshToken: String
    let user: AuthenticatedUser
}

struct AuthenticatedUser: Decodable, Equatable, Identifiable {
    let id: String
    let email: String
    let phone: String?
    let fullName: String
    let role: String
    let isVerified: Bool
    let avatarURL: String?
    let createdAt: Date?
}
