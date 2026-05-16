import Foundation
import XCTest
@testable import KilatRunner

final class TrackingRepositoryTests: XCTestCase {
    private var tokenStore: TrackingRepoInMemoryTokenStore!
    private var repository: TrackingRepository!

    override func setUp() {
        super.setUp()
        MockURLProtocol.reset()
        tokenStore = TrackingRepoInMemoryTokenStore()
        try? tokenStore.saveAccessToken("access-token")

        let configuration = URLSessionConfiguration.ephemeral
        configuration.protocolClasses = [MockURLProtocol.self]
        let session = URLSession(configuration: configuration)
        let apiClient = APIClient(
            baseURL: URL(string: "https://example.test/api/v1")!,
            session: session
        )
        repository = TrackingRepository(
            authInterceptor: AuthInterceptor(apiClient: apiClient, tokenStore: tokenStore)
        )
    }

    override func tearDown() {
        repository = nil
        tokenStore = nil
        MockURLProtocol.reset()
        super.tearDown()
    }

    func test_getHistory_decodesArray() async throws {
        let bookingId = "10000000-0000-4000-8000-000000000001"
        MockURLProtocol.requestHandler = { request in
            XCTAssertEqual(request.url?.path, "/api/v1/bookings/\(bookingId)/tracking")
            XCTAssertEqual(request.httpMethod, "GET")
            let body = #"""
            {"data":[
              {"booking_id":"\#(bookingId)","runner_id":"22222222-2222-4222-8222-222222222222","latitude":3.1626,"longitude":101.7185,"speed_kmh":42.5,"heading_degrees":120.0,"timestamp":"2026-05-16T10:00:00Z"},
              {"booking_id":"\#(bookingId)","runner_id":"22222222-2222-4222-8222-222222222222","latitude":3.1620,"longitude":101.7180,"speed_kmh":41.0,"heading_degrees":118.0,"timestamp":"2026-05-16T10:00:30Z"}
            ],"success":true}
            """#
            return Self.jsonResponse(request: request, body: body)
        }

        let updates = try await repository.getHistory(bookingId: bookingId)

        XCTAssertEqual(updates.count, 2)
        XCTAssertEqual(updates[0].latitude, 3.1626)
        XCTAssertEqual(updates[1].longitude, 101.7180)
    }

    func test_trackingUpdate_decodesFromSnakeCaseJSON() throws {
        let json = #"""
        {
          "booking_id": "10000000-0000-4000-8000-000000000001",
          "runner_id": "22222222-2222-4222-8222-222222222222",
          "latitude": 3.1626,
          "longitude": 101.7185,
          "speed_kmh": 42.5,
          "heading_degrees": 120.0,
          "timestamp": "2026-05-16T10:00:00Z"
        }
        """#.data(using: .utf8)!

        let decoder = JSONDecoder()
        decoder.keyDecodingStrategy = .convertFromSnakeCase
        decoder.dateDecodingStrategy = .iso8601
        let update = try decoder.decode(TrackingUpdate.self, from: json)

        XCTAssertEqual(update.bookingId, "10000000-0000-4000-8000-000000000001")
        XCTAssertEqual(update.runnerId, "22222222-2222-4222-8222-222222222222")
        XCTAssertEqual(update.speedKmh, 42.5)
        XCTAssertEqual(update.headingDegrees, 120.0)
    }

    private static func jsonResponse(request: URLRequest, body: String) -> (HTTPURLResponse, Data?) {
        let response = HTTPURLResponse(url: request.url!, statusCode: 200, httpVersion: nil, headerFields: nil)!
        return (response, body.data(using: .utf8))
    }
}

private final class TrackingRepoInMemoryTokenStore: TokenStore {
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
