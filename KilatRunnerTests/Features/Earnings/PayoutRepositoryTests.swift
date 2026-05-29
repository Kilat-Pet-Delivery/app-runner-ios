import Foundation
import XCTest
@testable import KilatRunner

final class PayoutRepositoryTests: XCTestCase {
    override func setUp() {
        super.setUp()
        MockURLProtocol.reset()
    }

    override func tearDown() {
        MockURLProtocol.reset()
        super.tearDown()
    }

    func test_cashOut_hitsCorrectEndpoint() async throws {
        let tokenStore = PayoutRepoInMemoryTokenStore()
        try tokenStore.saveAccessToken("access-token")

        let configuration = URLSessionConfiguration.ephemeral
        configuration.protocolClasses = [MockURLProtocol.self]
        let session = URLSession(configuration: configuration)
        let apiClient = APIClient(
            baseURL: URL(string: "https://example.test/api/v1")!,
            session: session,
            encoder: APIClient.makeCamelCaseEncoder()
        )
        let repository = PayoutRepository(
            authInterceptor: AuthInterceptor(apiClient: apiClient, tokenStore: tokenStore)
        )

        MockURLProtocol.requestHandler = { request in
            XCTAssertEqual(request.url?.path, "/api/v1/payouts/cash-out")
            XCTAssertEqual(request.httpMethod, "POST")
            XCTAssertEqual(request.value(forHTTPHeaderField: "Authorization"), "Bearer access-token")
            let body = try XCTUnwrap(request.httpBody)
            let json = try JSONSerialization.jsonObject(with: body) as? [String: Any]
            XCTAssertEqual(json?["amountMyrCents"] as? Int, 23_400)
            XCTAssertEqual(json?["destinationId"] as? String, "dest-1")
            return Self.jsonResponse(
                request: request,
                statusCode: 202,
                body: #"{"cashOutId":"KR-CO-08274","etaMinutes":30}"#
            )
        }

        let response = try await repository.cashOut(amountMyrCents: 23_400, destinationID: "dest-1")
        XCTAssertEqual(response.cashOutID, "KR-CO-08274")
    }

    private static func jsonResponse(request: URLRequest, statusCode: Int, body: String) -> (HTTPURLResponse, Data?) {
        let response = HTTPURLResponse(url: request.url!, statusCode: statusCode, httpVersion: nil, headerFields: nil)!
        return (response, body.data(using: .utf8))
    }
}

private final class PayoutRepoInMemoryTokenStore: TokenStore {
    private var storedAccessToken: String?
    private var storedRefreshToken: String?

    func saveAccessToken(_ token: String) throws { storedAccessToken = token }
    func accessToken() -> String? { storedAccessToken }
    func saveRefreshToken(_ token: String) throws { storedRefreshToken = token }
    func refreshToken() -> String? { storedRefreshToken }
    func clear() {
        storedAccessToken = nil
        storedRefreshToken = nil
    }
}
