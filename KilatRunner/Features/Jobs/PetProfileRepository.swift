import Foundation

protocol PetProfileRepositoryProtocol {
    func fetchPet(bookingID: String) async throws -> PetProfile
}

final class PetProfileRepository: PetProfileRepositoryProtocol {
    private let authInterceptor: AuthInterceptor

    init(authInterceptor: AuthInterceptor) {
        self.authInterceptor = authInterceptor
    }

    convenience init(apiClient: APIClient = APIClient(), tokenStore: TokenStore = KeychainStore()) {
        self.init(authInterceptor: AuthInterceptor(apiClient: apiClient, tokenStore: tokenStore))
    }

    func fetchPet(bookingID: String) async throws -> PetProfile {
        let envelope: APIResponseEnvelope<PetProfile> = try await authInterceptor.perform(.bookingPet(id: bookingID))
        return envelope.data
    }
}
