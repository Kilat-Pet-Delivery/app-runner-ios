import Foundation
import XCTest
@testable import KilatRunner

final class AuthRepositoryTests: XCTestCase {
    private var tokenStore: AuthRepositoryInMemoryTokenStore!
    private var repository: AuthRepository!

    override func setUp() {
        super.setUp()
        MockURLProtocol.reset()
        tokenStore = AuthRepositoryInMemoryTokenStore()

        let configuration = URLSessionConfiguration.ephemeral
        configuration.protocolClasses = [MockURLProtocol.self]
        let session = URLSession(configuration: configuration)
        let apiClient = APIClient(
            baseURL: URL(string: "https://example.test/api/v1")!,
            session: session
        )
        repository = AuthRepository(apiClient: apiClient, tokenStore: tokenStore)
    }

    override func tearDown() {
        repository = nil
        tokenStore = nil
        MockURLProtocol.reset()
        super.tearDown()
    }

    func test_login_success_savesTokensToKeychain() async throws {
        MockURLProtocol.requestHandler = { request in
            XCTAssertEqual(request.url?.path, "/api/v1/auth/login")
            XCTAssertEqual(request.httpMethod, "POST")
            return Self.jsonResponse(
                request: request,
                statusCode: 200,
                body: """
                {
                  "success": true,
                  "data": {
                    "access_token": "access-token",
                    "refresh_token": "refresh-token",
                    "user": {
                      "id": "11111111-1111-4111-8111-111111111111",
                      "email": "runner.test@kilat.my",
                      "phone": "+60123456780",
                      "full_name": "Test Runner",
                      "role": "runner",
                      "is_verified": true,
                      "created_at": "2026-05-16T10:45:49Z"
                    }
                  }
                }
                """
            )
        }

        let user = try await repository.login(email: "runner.test@kilat.my", password: "TestRunner123!")

        XCTAssertEqual(user.email, "runner.test@kilat.my")
        XCTAssertEqual(user.fullName, "Test Runner")
        XCTAssertEqual(user.role, "runner")
        XCTAssertEqual(tokenStore.accessToken(), "access-token")
        XCTAssertEqual(tokenStore.refreshToken(), "refresh-token")
    }

    func test_login_wrongPassword_throwsUnauthorized_keychainUntouched() async {
        MockURLProtocol.requestHandler = { request in
            Self.jsonResponse(request: request, statusCode: 401, body: #"{"success":false}"#)
        }

        await XCTAssertThrowsNetworkError(.unauthorized) {
            _ = try await repository.login(email: "runner.test@kilat.my", password: "wrong")
        }
        XCTAssertNil(tokenStore.accessToken())
        XCTAssertNil(tokenStore.refreshToken())
    }

    func test_login_serverError_throwsServerError_keychainUntouched() async {
        MockURLProtocol.requestHandler = { request in
            Self.jsonResponse(request: request, statusCode: 500, body: #"{"success":false}"#)
        }

        await XCTAssertThrowsNetworkError(.serverError(500)) {
            _ = try await repository.login(email: "runner.test@kilat.my", password: "TestRunner123!")
        }
        XCTAssertNil(tokenStore.accessToken())
        XCTAssertNil(tokenStore.refreshToken())
    }

    private static func jsonResponse(request: URLRequest, statusCode: Int, body: String) -> (HTTPURLResponse, Data?) {
        let response = HTTPURLResponse(url: request.url!, statusCode: statusCode, httpVersion: nil, headerFields: nil)!
        return (response, body.data(using: .utf8))
    }
}

private final class AuthRepositoryInMemoryTokenStore: TokenStore {
    private var storedAccessToken: String?
    private var storedRefreshToken: String?

    func saveAccessToken(_ token: String) throws {
        storedAccessToken = token
    }

    func accessToken() -> String? {
        storedAccessToken
    }

    func saveRefreshToken(_ token: String) throws {
        storedRefreshToken = token
    }

    func refreshToken() -> String? {
        storedRefreshToken
    }

    func clear() {
        storedAccessToken = nil
        storedRefreshToken = nil
    }
}

private func XCTAssertThrowsNetworkError(
    _ expectedError: NetworkError,
    operation: () async throws -> Void,
    file: StaticString = #filePath,
    line: UInt = #line
) async {
    do {
        try await operation()
        XCTFail("Expected \(expectedError)", file: file, line: line)
    } catch let error as NetworkError {
        XCTAssertEqual(error, expectedError, file: file, line: line)
    } catch {
        XCTFail("Expected \(expectedError), got \(error)", file: file, line: line)
    }
}
