import Foundation

protocol TrackingRepositoryProtocol {
    func getHistory(bookingId: String) async throws -> [TrackingUpdate]
}

final class TrackingRepository: TrackingRepositoryProtocol {
    private let authInterceptor: AuthInterceptor

    init(authInterceptor: AuthInterceptor) {
        self.authInterceptor = authInterceptor
    }

    convenience init(apiClient: APIClient = APIClient(), tokenStore: TokenStore = KeychainStore()) {
        self.init(authInterceptor: AuthInterceptor(apiClient: apiClient, tokenStore: tokenStore))
    }

    func getHistory(bookingId: String) async throws -> [TrackingUpdate] {
        let envelope: APIResponseEnvelope<[TrackingUpdate]> = try await authInterceptor.perform(.trackingHistory(bookingId: bookingId))
        return envelope.data
    }
}
