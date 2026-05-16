import Foundation

protocol EarningsRepositoryProtocol {
    func list(page: Int, limit: Int) async throws -> EarningsPage
}

final class EarningsRepository: EarningsRepositoryProtocol {
    private let authInterceptor: AuthInterceptor

    init(authInterceptor: AuthInterceptor) {
        self.authInterceptor = authInterceptor
    }

    convenience init(apiClient: APIClient = APIClient(), tokenStore: TokenStore = KeychainStore()) {
        self.init(authInterceptor: AuthInterceptor(apiClient: apiClient, tokenStore: tokenStore))
    }

    func list(page: Int = 1, limit: Int = 20) async throws -> EarningsPage {
        let envelope: PaginatedAPIResponseEnvelope<[Booking]> = try await authInterceptor.perform(
            .earnings(page: page, limit: limit)
        )
        return EarningsPage(
            items: envelope.data.map(Earning.init(booking:)),
            page: envelope.pagination.page,
            limit: envelope.pagination.limit,
            total: envelope.pagination.total
        )
    }
}
