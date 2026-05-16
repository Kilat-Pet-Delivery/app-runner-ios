import Foundation
import XCTest
@testable import KilatRunner

final class RunnerRepositoryTests: XCTestCase {
    private var tokenStore: RunnerRepositoryInMemoryTokenStore!
    private var repository: RunnerRepository!

    override func setUp() {
        super.setUp()
        MockURLProtocol.reset()
        tokenStore = RunnerRepositoryInMemoryTokenStore()
        try? tokenStore.saveAccessToken("access-token")

        let configuration = URLSessionConfiguration.ephemeral
        configuration.protocolClasses = [MockURLProtocol.self]
        let session = URLSession(configuration: configuration)
        let apiClient = APIClient(
            baseURL: URL(string: "https://example.test/api/v1")!,
            session: session
        )
        repository = RunnerRepository(
            authInterceptor: AuthInterceptor(apiClient: apiClient, tokenStore: tokenStore)
        )
    }

    override func tearDown() {
        repository = nil
        tokenStore = nil
        MockURLProtocol.reset()
        super.tearDown()
    }

    func test_getMe_returnsRunner() async throws {
        MockURLProtocol.requestHandler = { request in
            XCTAssertEqual(request.url?.path, "/api/v1/runners/me")
            XCTAssertEqual(request.httpMethod, "GET")
            return Self.jsonResponse(request: request, statusCode: 200, body: Self.runnerEnvelope)
        }

        let runner = try await repository.getMe()

        XCTAssertEqual(runner.id, "22222222-2222-4222-8222-222222222222")
        XCTAssertEqual(runner.fullName, "Test Runner")
        XCTAssertEqual(runner.vehicleType, "car")
        XCTAssertTrue(runner.isOnline)
        XCTAssertEqual(runner.maxCrateCapacityKg, 25)
    }

    func test_goOnline_postsToCorrectEndpoint() async throws {
        MockURLProtocol.requestHandler = { request in
            XCTAssertEqual(request.url?.path, "/api/v1/runners/me/online")
            XCTAssertEqual(request.httpMethod, "POST")
            return Self.jsonResponse(request: request, statusCode: 200, body: Self.messageEnvelope)
        }

        try await repository.goOnline(latitude: 3.139, longitude: 101.6869)

        XCTAssertEqual(MockURLProtocol.capturedRequests.count, 1)
    }

    func test_goOffline_postsToCorrectEndpoint() async throws {
        MockURLProtocol.requestHandler = { request in
            XCTAssertEqual(request.url?.path, "/api/v1/runners/me/offline")
            XCTAssertEqual(request.httpMethod, "POST")
            return Self.jsonResponse(request: request, statusCode: 200, body: Self.messageEnvelope)
        }

        try await repository.goOffline()

        XCTAssertEqual(MockURLProtocol.capturedRequests.count, 1)
    }

    func test_postLocation_sendsLatLngHeadingSpeed() async throws {
        MockURLProtocol.requestHandler = { request in
            XCTAssertEqual(request.url?.path, "/api/v1/runners/me/location")
            XCTAssertEqual(request.httpMethod, "POST")
            let body = try XCTUnwrap(request.httpBody)
            let json = try XCTUnwrap(JSONSerialization.jsonObject(with: body) as? [String: Any])
            XCTAssertEqual(json["latitude"] as? Double, 3.139)
            XCTAssertEqual(json["longitude"] as? Double, 101.6869)
            XCTAssertEqual(json["speed_kmh"] as? Double, 32.5)
            XCTAssertEqual(json["heading_degrees"] as? Double, 180)
            return Self.jsonResponse(request: request, statusCode: 200, body: Self.messageEnvelope)
        }

        try await repository.postLocation(
            RunnerLocationWaypoint(
                latitude: 3.139,
                longitude: 101.6869,
                speedKmh: 32.5,
                headingDegrees: 180
            )
        )
    }

    private static let runnerEnvelope = """
    {
      "success": true,
      "data": {
        "id": "22222222-2222-4222-8222-222222222222",
        "user_id": "11111111-1111-4111-8111-111111111111",
        "full_name": "Test Runner",
        "phone": "+60123456780",
        "vehicle_type": "car",
        "vehicle_plate": "KILAT1",
        "vehicle_model": "Myvi",
        "air_conditioned": true,
        "session_status": "active",
        "rating": 4.9,
        "total_trips": 12,
        "crate_specs": [
          {
            "id": "33333333-3333-4333-8333-333333333333",
            "size": "medium",
            "pet_types": ["cat", "dog"],
            "max_weight_kg": 25,
            "width_cm": 50,
            "height_cm": 45,
            "depth_cm": 70,
            "ventilated": true,
            "temperature_controlled": false
          }
        ],
        "created_at": "2026-05-16T10:45:49Z"
      }
    }
    """

    private static let messageEnvelope = """
    {
      "success": true,
      "data": {
        "message": "ok"
      }
    }
    """

    private static func jsonResponse(request: URLRequest, statusCode: Int, body: String) -> (HTTPURLResponse, Data?) {
        let response = HTTPURLResponse(url: request.url!, statusCode: statusCode, httpVersion: nil, headerFields: nil)!
        return (response, body.data(using: .utf8))
    }
}

private final class RunnerRepositoryInMemoryTokenStore: TokenStore {
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
