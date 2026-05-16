import Foundation

protocol AuthRepositoryProtocol {
    func login(email: String, password: String) async throws -> AuthenticatedUser
}

final class AuthRepository: AuthRepositoryProtocol {
    private let authInterceptor: AuthInterceptor
    private let tokenStore: TokenStore

    init(authInterceptor: AuthInterceptor, tokenStore: TokenStore) {
        self.authInterceptor = authInterceptor
        self.tokenStore = tokenStore
    }

    convenience init(apiClient: APIClient = APIClient(), tokenStore: TokenStore = KeychainStore()) {
        self.init(
            authInterceptor: AuthInterceptor(apiClient: apiClient, tokenStore: tokenStore),
            tokenStore: tokenStore
        )
    }

    func login(email: String, password: String) async throws -> AuthenticatedUser {
        let envelope: APIResponseEnvelope<LoginResponse> = try await authInterceptor.perform(
            .login,
            body: LoginRequest(email: email, password: password)
        )

        try tokenStore.saveAccessToken(envelope.data.accessToken)
        try tokenStore.saveRefreshToken(envelope.data.refreshToken)

        return envelope.data.user
    }
}
