import Foundation

protocol PasswordResetRepositoryProtocol {
    func forgotPassword(email: String) async throws
    func resetPassword(token: String, newPassword: String) async throws
}

final class PasswordResetRepository: PasswordResetRepositoryProtocol {
    private let apiClient: APIClient

    init(apiClient: APIClient = APIClient(encoder: APIClient.makeCamelCaseEncoder())) {
        self.apiClient = apiClient
    }

    func forgotPassword(email: String) async throws {
        let _: EmptyResponse = try await apiClient.request(
            .forgotPassword,
            body: ForgotPasswordRequest(email: email)
        )
    }

    func resetPassword(token: String, newPassword: String) async throws {
        let _: EmptyResponse = try await apiClient.request(
            .resetPassword,
            body: ResetPasswordRequest(token: token, newPassword: newPassword)
        )
    }
}

struct ForgotPasswordRequest: Encodable, Equatable {
    let email: String
}

struct ResetPasswordRequest: Encodable, Equatable {
    let token: String
    let newPassword: String
}
