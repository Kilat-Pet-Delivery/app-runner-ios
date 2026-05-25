import Foundation

protocol LoyaltyRepositoryProtocol {
    func fetchQuests() async throws -> QuestListResponse
    func redeemQuest(id: String) async throws -> RunnerQuest
    func fetchTier() async throws -> TierSnapshot
    func fetchReferrals() async throws -> [String]
    func createReferralCode() async throws -> String
    func redeemReferral(id: String) async throws
}

extension LoyaltyRepositoryProtocol {
    func fetchTier() async throws -> TierSnapshot { throw NetworkError.invalidResponse }
    func fetchReferrals() async throws -> [String] { [] }
    func createReferralCode() async throws -> String { throw NetworkError.invalidResponse }
    func redeemReferral(id: String) async throws { throw NetworkError.invalidResponse }
}

final class LoyaltyRepository: LoyaltyRepositoryProtocol {
    private let authInterceptor: AuthInterceptor

    init(authInterceptor: AuthInterceptor) {
        self.authInterceptor = authInterceptor
    }

    convenience init(apiClient: APIClient = APIClient(), tokenStore: TokenStore = KeychainStore()) {
        self.init(authInterceptor: AuthInterceptor(apiClient: apiClient, tokenStore: tokenStore))
    }

    func fetchQuests() async throws -> QuestListResponse {
        try await authInterceptor.perform(.quests)
    }

    func redeemQuest(id: String) async throws -> RunnerQuest {
        let envelope: APIResponseEnvelope<RunnerQuest> = try await authInterceptor.perform(.redeemQuest(id: id))
        return envelope.data
    }

    func fetchTier() async throws -> TierSnapshot {
        let identityRepository = IdentityRepository(authInterceptor: authInterceptor)
        return try await identityRepository.fetchTier()
    }
}
