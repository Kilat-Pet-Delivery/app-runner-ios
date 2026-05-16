import Foundation

final class AuthInterceptor {
    private let apiClient: APIClient
    private let tokenStore: TokenStore
    private let refreshLock = NSLock()
    private var refreshTask: Task<AuthTokenPair, Error>?
    private var refreshTaskID: UUID?

    init(apiClient: APIClient, tokenStore: TokenStore) {
        self.apiClient = apiClient
        self.tokenStore = tokenStore
    }

    func perform<Response: Decodable>(_ endpoint: APIEndpoint) async throws -> Response {
        try await perform(endpoint, body: Optional<EmptyRequest>.none)
    }

    func perform<Body: Encodable, Response: Decodable>(
        _ endpoint: APIEndpoint,
        body: Body?
    ) async throws -> Response {
        do {
            return try await apiClient.request(endpoint, body: body, token: token(for: endpoint))
        } catch NetworkError.unauthorized where endpoint.requiresAuth {
            let tokenPair = try await refreshTokens()
            return try await apiClient.request(endpoint, body: body, token: tokenPair.accessToken)
        }
    }

    private func token(for endpoint: APIEndpoint) -> String? {
        endpoint.requiresAuth ? tokenStore.accessToken() : nil
    }

    private func refreshTokens() async throws -> AuthTokenPair {
        let (task, ownedTaskID): (Task<AuthTokenPair, Error>, UUID?) = refreshLock.withLock {
            if let existing = refreshTask {
                return (existing, nil)
            }

            let newID = UUID()
            let task = Task { [apiClient, tokenStore] in
                guard let refreshToken = tokenStore.refreshToken() else {
                    tokenStore.clear()
                    throw NetworkError.unauthorized
                }

                do {
                    let response: APIResponseEnvelope<AuthTokenPair> = try await apiClient.request(
                        .refresh,
                        body: RefreshTokenRequest(refreshToken: refreshToken)
                    )
                    try tokenStore.saveAccessToken(response.data.accessToken)
                    try tokenStore.saveRefreshToken(response.data.refreshToken)
                    return response.data
                } catch {
                    tokenStore.clear()
                    throw NetworkError.unauthorized
                }
            }

            refreshTask = task
            refreshTaskID = newID
            return (task, newID)
        }

        defer {
            if let ownedTaskID {
                refreshLock.withLock {
                    if refreshTaskID == ownedTaskID {
                        refreshTask = nil
                        refreshTaskID = nil
                    }
                }
            }
        }

        return try await task.value
    }
}

struct RefreshTokenRequest: Encodable {
    let refreshToken: String
}

struct AuthTokenPair: Decodable, Equatable {
    let accessToken: String
    let refreshToken: String
}

struct APIResponseEnvelope<Payload: Decodable>: Decodable {
    let data: Payload
    let success: Bool?
}

private extension NSLock {
    func withLock<T>(_ operation: () throws -> T) rethrows -> T {
        lock()
        defer { unlock() }
        return try operation()
    }
}
