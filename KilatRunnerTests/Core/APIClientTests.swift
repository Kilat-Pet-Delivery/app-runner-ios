import XCTest
@testable import KilatRunner

final class APIClientTests: XCTestCase {
    private var client: APIClient!

    override func setUp() {
        super.setUp()
        MockURLProtocol.reset()

        let configuration = URLSessionConfiguration.ephemeral
        configuration.protocolClasses = [MockURLProtocol.self]
        let session = URLSession(configuration: configuration)

        client = APIClient(
            baseURL: URL(string: "https://example.test/api/v1")!,
            session: session
        )
    }

    override func tearDown() {
        client = nil
        MockURLProtocol.reset()
        super.tearDown()
    }

    func test_get_success_decodesPayload() async throws {
        MockURLProtocol.requestHandler = { request in
            let response = HTTPURLResponse(
                url: request.url!,
                statusCode: 200,
                httpVersion: nil,
                headerFields: nil
            )!
            return (response, #"{"name":"Kilat"}"#.data(using: .utf8))
        }

        let payload: TestPayload = try await client.request(.profile, token: "token")

        XCTAssertEqual(payload.name, "Kilat")
    }

    func test_get_returnsUnauthorized_on401() async {
        MockURLProtocol.requestHandler = { request in
            let response = HTTPURLResponse(url: request.url!, statusCode: 401, httpVersion: nil, headerFields: nil)!
            return (response, Data())
        }

        await XCTAssertThrowsNetworkError(.unauthorized) {
            let _: TestPayload = try await client.request(.profile, token: "token")
        }
    }

    func test_get_returnsServerError_on500() async {
        MockURLProtocol.requestHandler = { request in
            let response = HTTPURLResponse(url: request.url!, statusCode: 500, httpVersion: nil, headerFields: nil)!
            return (response, Data())
        }

        await XCTAssertThrowsNetworkError(.serverError(500)) {
            let _: TestPayload = try await client.request(.profile, token: "token")
        }
    }

    func test_request_addsBearerToken_whenProvided() async throws {
        MockURLProtocol.requestHandler = { request in
            let response = HTTPURLResponse(url: request.url!, statusCode: 200, httpVersion: nil, headerFields: nil)!
            return (response, #"{"name":"Kilat"}"#.data(using: .utf8))
        }

        let _: TestPayload = try await client.request(.profile, token: "access-token")

        XCTAssertEqual(MockURLProtocol.capturedRequests.first?.value(forHTTPHeaderField: "Authorization"), "Bearer access-token")
    }

    func test_request_omitsBearer_whenNoToken() async throws {
        MockURLProtocol.requestHandler = { request in
            let response = HTTPURLResponse(url: request.url!, statusCode: 200, httpVersion: nil, headerFields: nil)!
            return (response, #"{"name":"Kilat"}"#.data(using: .utf8))
        }

        let _: TestPayload = try await client.request(.profile)

        XCTAssertNil(MockURLProtocol.capturedRequests.first?.value(forHTTPHeaderField: "Authorization"))
    }

    func test_request_encodesBodySnakeCase() async throws {
        MockURLProtocol.requestHandler = { request in
            let body = try XCTUnwrap(request.httpBody)
            let json = try XCTUnwrap(String(data: body, encoding: .utf8))
            XCTAssertTrue(json.contains(#""camel_case_field":"value""#))

            let response = HTTPURLResponse(url: request.url!, statusCode: 200, httpVersion: nil, headerFields: nil)!
            return (response, #"{"name":"Kilat"}"#.data(using: .utf8))
        }

        let _: TestPayload = try await client.request(
            .login,
            body: TestRequest(camelCaseField: "value")
        )
    }

    func test_request_decodesSnakeCaseResponse() async throws {
        MockURLProtocol.requestHandler = { request in
            let response = HTTPURLResponse(url: request.url!, statusCode: 200, httpVersion: nil, headerFields: nil)!
            return (response, #"{"access_token":"abc"}"#.data(using: .utf8))
        }

        let payload: TokenPayload = try await client.request(.login)

        XCTAssertEqual(payload.accessToken, "abc")
    }
}

private struct TestPayload: Decodable {
    let name: String
}

private struct TestRequest: Encodable {
    let camelCaseField: String
}

private struct TokenPayload: Decodable {
    let accessToken: String
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
