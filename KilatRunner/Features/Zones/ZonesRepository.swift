import Foundation

protocol ZonesRepositoryProtocol {
    func fetchActiveZones() async throws -> [HotZone]
    func lookupZoneAt(lat: Double, lon: Double) async throws -> HotZone?
}

final class ZonesRepository: ZonesRepositoryProtocol {
    private let authInterceptor: AuthInterceptor

    init(authInterceptor: AuthInterceptor) {
        self.authInterceptor = authInterceptor
    }

    convenience init(apiClient: APIClient = APIClient(), tokenStore: TokenStore = KeychainStore()) {
        self.init(authInterceptor: AuthInterceptor(apiClient: apiClient, tokenStore: tokenStore))
    }

    func fetchActiveZones() async throws -> [HotZone] {
        try await authInterceptor.perform(.zones)
    }

    func lookupZoneAt(lat: Double, lon: Double) async throws -> HotZone? {
        let envelope: APIResponseEnvelope<HotZone?> = try await authInterceptor.perform(.zoneAt(lat: lat, lon: lon))
        return envelope.data
    }
}
