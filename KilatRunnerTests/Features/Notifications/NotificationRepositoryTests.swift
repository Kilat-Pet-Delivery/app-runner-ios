import Foundation
import XCTest
@testable import KilatRunner

final class NotificationRepositoryTests: XCTestCase {
    override func setUp() {
        super.setUp()
        MockURLProtocol.reset()
    }

    override func tearDown() {
        MockURLProtocol.reset()
        super.tearDown()
    }

    func test_list_hitsCorrectEndpoint_withCursor() async throws {
        let tokenStore = NotificationRepoInMemoryTokenStore()
        try tokenStore.saveAccessToken("access-token")

        let configuration = URLSessionConfiguration.ephemeral
        configuration.protocolClasses = [MockURLProtocol.self]
        let session = URLSession(configuration: configuration)
        let apiClient = APIClient(
            baseURL: URL(string: "https://example.test/api/v1")!,
            session: session
        )
        let repository = NotificationRepository(
            authInterceptor: AuthInterceptor(apiClient: apiClient, tokenStore: tokenStore)
        )

        MockURLProtocol.requestHandler = { request in
            XCTAssertEqual(request.url?.path, "/api/v1/notifications")
            XCTAssertEqual(request.httpMethod, "GET")
            XCTAssertEqual(request.value(forHTTPHeaderField: "Authorization"), "Bearer access-token")
            let query = request.url?.query ?? ""
            XCTAssertTrue(query.contains("cursor=cursor-2"), "missing cursor in \(query)")
            XCTAssertTrue(query.contains("limit=20"), "missing limit in \(query)")
            return Self.jsonResponse(
                request: request,
                statusCode: 200,
                body: """
                {
                  "items": [
                    {
                      "id": "n1",
                      "type": "booking",
                      "title": "New job",
                      "body": "A job is nearby.",
                      "createdAt": "2026-05-16T10:00:00Z",
                      "readAt": null
                    }
                  ],
                  "nextCursor": ""
                }
                """
            )
        }

        let response = try await repository.list(cursor: "cursor-2", limit: 20)
        XCTAssertEqual(response.items.first?.id, "n1")
        XCTAssertEqual(response.nextCursor, "")
    }

    private static func jsonResponse(request: URLRequest, statusCode: Int, body: String) -> (HTTPURLResponse, Data?) {
        let response = HTTPURLResponse(url: request.url!, statusCode: statusCode, httpVersion: nil, headerFields: nil)!
        return (response, body.data(using: .utf8))
    }
}

private final class NotificationRepoInMemoryTokenStore: TokenStore {
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
