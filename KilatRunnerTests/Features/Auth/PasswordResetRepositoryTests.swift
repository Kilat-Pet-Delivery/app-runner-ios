import Foundation
import XCTest
@testable import KilatRunner

final class PasswordResetRepositoryTests: XCTestCase {
    override func setUp() {
        super.setUp()
        MockURLProtocol.reset()
    }

    override func tearDown() {
        MockURLProtocol.reset()
        super.tearDown()
    }

    func test_forgotPassword_hitsCorrectEndpoint() async throws {
        let repository = makeRepository()

        MockURLProtocol.requestHandler = { request in
            XCTAssertEqual(request.url?.path, "/api/v1/auth/forgot-password")
            XCTAssertEqual(request.httpMethod, "POST")
            let body = try XCTUnwrap(request.httpBody)
            let json = try JSONSerialization.jsonObject(with: body) as? [String: String]
            XCTAssertEqual(json?["email"], "runner.test@kilat.my")
            return Self.jsonResponse(request: request, statusCode: 202, body: "{}")
        }

        try await repository.forgotPassword(email: "runner.test@kilat.my")
    }

    private func makeRepository() -> PasswordResetRepository {
        let configuration = URLSessionConfiguration.ephemeral
        configuration.protocolClasses = [MockURLProtocol.self]
        let session = URLSession(configuration: configuration)
        let apiClient = APIClient(
            baseURL: URL(string: "https://example.test/api/v1")!,
            session: session,
            encoder: APIClient.makeCamelCaseEncoder()
        )
        return PasswordResetRepository(apiClient: apiClient)
    }

    private static func jsonResponse(request: URLRequest, statusCode: Int, body: String) -> (HTTPURLResponse, Data?) {
        let response = HTTPURLResponse(url: request.url!, statusCode: statusCode, httpVersion: nil, headerFields: nil)!
        return (response, body.data(using: .utf8))
    }
}
