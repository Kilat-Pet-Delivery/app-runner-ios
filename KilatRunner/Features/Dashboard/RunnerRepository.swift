import Foundation

protocol RunnerRepositoryProtocol {
    func getMe() async throws -> Runner
    func goOnline(latitude: Double, longitude: Double) async throws
    func goOffline() async throws
    func postLocation(_ waypoint: RunnerLocationWaypoint) async throws
}

final class RunnerRepository: RunnerRepositoryProtocol {
    private let authInterceptor: AuthInterceptor

    init(authInterceptor: AuthInterceptor) {
        self.authInterceptor = authInterceptor
    }

    convenience init(apiClient: APIClient = APIClient(), tokenStore: TokenStore = KeychainStore()) {
        self.init(authInterceptor: AuthInterceptor(apiClient: apiClient, tokenStore: tokenStore))
    }

    func getMe() async throws -> Runner {
        let envelope: APIResponseEnvelope<Runner> = try await authInterceptor.perform(.runnerMe)
        return envelope.data
    }

    func goOnline(latitude: Double, longitude: Double) async throws {
        let _: APIResponseEnvelope<MessageResponse> = try await authInterceptor.perform(
            .runnerOnline,
            body: GoOnlineRequest(latitude: latitude, longitude: longitude)
        )
    }

    func goOffline() async throws {
        let _: APIResponseEnvelope<MessageResponse> = try await authInterceptor.perform(.runnerOffline)
    }

    func postLocation(_ waypoint: RunnerLocationWaypoint) async throws {
        let _: APIResponseEnvelope<MessageResponse> = try await authInterceptor.perform(
            .runnerLocation,
            body: waypoint
        )
    }
}

private struct MessageResponse: Decodable {
    let message: String
}
