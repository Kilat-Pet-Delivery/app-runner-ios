import Foundation

protocol PerformanceRepositoryProtocol {
    func fetchTier() async throws -> TierSnapshot
}

final class PerformanceRepository: PerformanceRepositoryProtocol {
    private let identityRepository: IdentityRepositoryProtocol

    init(identityRepository: IdentityRepositoryProtocol = IdentityRepository()) {
        self.identityRepository = identityRepository
    }

    func fetchTier() async throws -> TierSnapshot {
        try await identityRepository.fetchTier()
    }
}
