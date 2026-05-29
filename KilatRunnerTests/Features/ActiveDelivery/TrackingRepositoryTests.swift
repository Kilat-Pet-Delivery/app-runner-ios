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

    func test_arrivePickup_hitsCorrectEndpointAndAuthHeader() async throws {
        let bookingId = "10000000-0000-4000-8000-000000000001"
        MockURLProtocol.requestHandler = { request in
            XCTAssertEqual(request.url?.path, "/api/v1/bookings/\(bookingId)/arrive-pickup")
            XCTAssertEqual(request.httpMethod, "POST")
            XCTAssertEqual(request.value(forHTTPHeaderField: "Authorization"), "Bearer access-token")
            return Self.jsonResponse(request: request, body: Self.bookingEnvelope(status: "in_progress"))
        }

        let booking = try await repository.arriveAtPickup(bookingId: bookingId)

        XCTAssertEqual(booking.id, bookingId)
        XCTAssertEqual(booking.status, .inProgress)
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

    private static func bookingEnvelope(status: String) -> String {
        #"""
        {"data":{
          "id":"10000000-0000-4000-8000-000000000001",
          "booking_number":"BK-AB12CD",
          "owner_id":"20000000-0000-4000-8000-000000000001",
          "runner_id":"22222222-2222-4222-8222-222222222222",
          "status":"\#(status)",
          "pet_spec":{"pet_type":"cat","breed":"Persian","name":"Milo","weight_kg":4.5,"special_needs":"","photo_url":""},
          "pickup_address":{"line1":"123 Jalan Ampang","line2":"","city":"Kuala Lumpur","state":"WP","postal_code":"50450","country":"MY","latitude":3.1626,"longitude":101.7185},
          "dropoff_address":{"line1":"1 Jalan SS2/24","line2":"","city":"Petaling Jaya","state":"Selangor","postal_code":"47300","country":"MY","latitude":3.1170,"longitude":101.6190},
          "route_spec":{"pickup_lat":3.1626,"pickup_lng":101.7185,"dropoff_lat":3.1170,"dropoff_lng":101.6190,"distance_km":12.4,"estimated_duration_min":28,"polyline":""},
          "estimated_price_cents":2500,
          "currency":"MYR",
          "version":1,
          "created_at":"2026-05-16T10:00:00Z",
          "updated_at":"2026-05-16T10:00:00Z"
        },"success":true}
        """#
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
