import Foundation

protocol PayoutRepositoryProtocol {
    func cashOut(amountMyrCents: Int64, destinationID: String) async throws -> CashOutResponse
}

final class PayoutRepository: PayoutRepositoryProtocol {
    private let authInterceptor: AuthInterceptor

    init(authInterceptor: AuthInterceptor) {
        self.authInterceptor = authInterceptor
    }

    convenience init(
        apiClient: APIClient = APIClient(encoder: APIClient.makeCamelCaseEncoder()),
        tokenStore: TokenStore = KeychainStore()
    ) {
        self.init(authInterceptor: AuthInterceptor(apiClient: apiClient, tokenStore: tokenStore))
    }

    func cashOut(amountMyrCents: Int64, destinationID: String) async throws -> CashOutResponse {
        try await authInterceptor.perform(
            .cashOut,
            body: CashOutRequest(amountMyrCents: amountMyrCents, destinationID: destinationID)
        )
    }
}

struct CashOutRequest: Encodable, Equatable {
    let amountMyrCents: Int64
    let destinationID: String

    private enum CodingKeys: String, CodingKey {
        case amountMyrCents
        case destinationID = "destinationId"
    }
}

struct CashOutResponse: Decodable, Equatable {
    let cashOutID: String
    let etaMinutes: Int

    private enum CodingKeys: String, CodingKey {
        case cashOutID = "cashOutId"
        case etaMinutes
    }
}
