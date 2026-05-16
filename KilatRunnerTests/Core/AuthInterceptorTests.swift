import Foundation
import XCTest
@testable import KilatRunner

final class AuthInterceptorTests: XCTestCase {
    private var tokenStore: InMemoryTokenStore!
    private var interceptor: AuthInterceptor!

    override func setUp() {
        super.setUp()
        MockURLProtocol.reset()
        tokenStore = InMemoryTokenStore(accessToken: "old-access", refreshToken: "old-refresh")

        let configuration = URLSessionConfiguration.ephemeral
        configuration.protocolClasses = [MockURLProtocol.self]
        let session = URLSession(configuration: configuration)
        let apiClient = APIClient(
            baseURL: URL(string: "https://example.test/api/v1")!,
            session: session
        )
        interceptor = AuthInterceptor(apiClient: apiClient, tokenStore: tokenStore)
    }

    override func tearDown() {
        interceptor = nil
        tokenStore = nil
        MockURLProtocol.reset()
        super.tearDown()
    }

    func test_perform_addsCurrentTokenAndSucceeds() async throws {
        MockURLProtocol.requestHandler = { request in
            XCTAssertEqual(request.value(forHTTPHeaderField: "Authorization"), "Bearer old-access")
            return Self.jsonResponse(request: request, body: #"{"name":"Kilat"}"#)
        }

        let payload: TestPayload = try await interceptor.perform(.profile)

        XCTAssertEqual(payload.name, "Kilat")
    }

    func test_perform_on401_refreshesTokenAndRetries() async throws {
        var profileCallCount = 0
        MockURLProtocol.requestHandler = { request in
            if request.url?.path == "/api/v1/auth/refresh" {
                return Self.jsonResponse(
                    request: request,
                    body: #"{"success":true,"data":{"access_token":"new-access","refresh_token":"new-refresh"}}"#
                )
            }

            profileCallCount += 1
            if profileCallCount == 1 {
                return Self.emptyResponse(request: request, statusCode: 401)
            }

            XCTAssertEqual(request.value(forHTTPHeaderField: "Authorization"), "Bearer new-access")
            return Self.jsonResponse(request: request, body: #"{"name":"Kilat"}"#)
        }

        let payload: TestPayload = try await interceptor.perform(.profile)

        XCTAssertEqual(payload.name, "Kilat")
        XCTAssertEqual(tokenStore.accessToken(), "new-access")
        XCTAssertEqual(tokenStore.refreshToken(), "new-refresh")
    }

    func test_perform_refreshFails_throwsUnauthorizedAndClears() async {
        MockURLProtocol.requestHandler = { request in
            if request.url?.path == "/api/v1/auth/refresh" {
                return Self.emptyResponse(request: request, statusCode: 401)
            }
            return Self.emptyResponse(request: request, statusCode: 401)
        }

        await XCTAssertThrowsNetworkError(.unauthorized) {
            let _: TestPayload = try await interceptor.perform(.profile)
        }
        XCTAssertNil(tokenStore.accessToken())
        XCTAssertNil(tokenStore.refreshToken())
    }

    func test_perform_concurrentRequests_refreshOnce() async throws {
        let lock = NSLock()
        var refreshCallCount = 0
        var profileCallCount = 0

        MockURLProtocol.requestHandler = { request in
            if request.url?.path == "/api/v1/auth/refresh" {
                lock.withLock { refreshCallCount += 1 }
                return Self.jsonResponse(
                    request: request,
                    body: #"{"success":true,"data":{"access_token":"new-access","refresh_token":"new-refresh"}}"#
                )
            }

            let call = lock.withLock {
                profileCallCount += 1
                return profileCallCount
            }
            if call <= 2 {
                return Self.emptyResponse(request: request, statusCode: 401)
            }
            return Self.jsonResponse(request: request, body: #"{"name":"Kilat"}"#)
        }

        async let first: TestPayload = interceptor.perform(.profile)
        async let second: TestPayload = interceptor.perform(.profile)
        _ = try await [first, second]

        XCTAssertEqual(refreshCallCount, 1)
    }

    private static func jsonResponse(request: URLRequest, body: String) -> (HTTPURLResponse, Data?) {
        let response = HTTPURLResponse(url: request.url!, statusCode: 200, httpVersion: nil, headerFields: nil)!
        return (response, body.data(using: .utf8))
    }

    private static func emptyResponse(request: URLRequest, statusCode: Int) -> (HTTPURLResponse, Data?) {
        let response = HTTPURLResponse(url: request.url!, statusCode: statusCode, httpVersion: nil, headerFields: nil)!
        return (response, Data())
    }
}

private struct TestPayload: Decodable {
    let name: String
}

private final class InMemoryTokenStore: TokenStore {
    private var storedAccessToken: String?
    private var storedRefreshToken: String?

    init(accessToken: String? = nil, refreshToken: String? = nil) {
        storedAccessToken = accessToken
        storedRefreshToken = refreshToken
    }

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

private extension NSLock {
    func withLock<T>(_ operation: () throws -> T) rethrows -> T {
        lock()
        defer { unlock() }
        return try operation()
    }
}
