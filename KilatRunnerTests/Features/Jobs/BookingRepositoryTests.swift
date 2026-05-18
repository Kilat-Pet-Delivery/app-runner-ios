import Foundation
import XCTest
@testable import KilatRunner

final class BookingRepositoryTests: XCTestCase {
    private var tokenStore: BookingRepoInMemoryTokenStore!
    private var repository: BookingRepository!

    override func setUp() {
        super.setUp()
        MockURLProtocol.reset()
        tokenStore = BookingRepoInMemoryTokenStore()
        try? tokenStore.saveAccessToken("access-token")

        let configuration = URLSessionConfiguration.ephemeral
        configuration.protocolClasses = [MockURLProtocol.self]
        let session = URLSession(configuration: configuration)
        let apiClient = APIClient(
            baseURL: URL(string: "https://example.test/api/v1")!,
            session: session
        )
        repository = BookingRepository(
            authInterceptor: AuthInterceptor(apiClient: apiClient, tokenStore: tokenStore)
        )
    }

    override func tearDown() {
        repository = nil
        tokenStore = nil
        MockURLProtocol.reset()
        super.tearDown()
    }

    func test_listAvailable_decodesArray() async throws {
        MockURLProtocol.requestHandler = { request in
            XCTAssertEqual(request.url?.path, "/api/v1/bookings")
            let query = request.url?.query ?? ""
            XCTAssertTrue(query.contains("status=requested"), "missing status=requested in \(query)")
            XCTAssertEqual(request.httpMethod, "GET")
            return Self.jsonResponse(request: request, statusCode: 200, body: Self.paginatedTwoBookings)
        }

        let bookings = try await repository.listAvailable()

        XCTAssertEqual(bookings.count, 2)
        XCTAssertEqual(bookings[0].id, "10000000-0000-4000-8000-000000000001")
        XCTAssertEqual(bookings[0].status, .requested)
        XCTAssertEqual(bookings[1].bookingNumber, "BK-ABCXYZ")
    }

    func test_listAvailable_emptyArray_returnsEmpty() async throws {
        MockURLProtocol.requestHandler = { request in
            return Self.jsonResponse(
                request: request,
                statusCode: 200,
                body: #"{"data":[],"pagination":{"limit":20,"page":1,"total":0,"total_pages":0},"success":true}"#
            )
        }

        let bookings = try await repository.listAvailable()
        XCTAssertEqual(bookings, [])
    }

    func test_get_decodesSingleBooking() async throws {
        let bookingId = "10000000-0000-4000-8000-000000000001"
        MockURLProtocol.requestHandler = { request in
            XCTAssertEqual(request.url?.path, "/api/v1/bookings/\(bookingId)")
            XCTAssertEqual(request.httpMethod, "GET")
            return Self.jsonResponse(request: request, statusCode: 200, body: Self.envelope(Self.requestedBookingJSON))
        }

        let booking = try await repository.get(id: bookingId)

        XCTAssertEqual(booking.id, bookingId)
        XCTAssertEqual(booking.petSpec.name, "Milo")
        XCTAssertEqual(booking.pickupAddress.city, "Kuala Lumpur")
        XCTAssertEqual(booking.dropoffAddress.city, "Petaling Jaya")
        XCTAssertEqual(booking.estimatedPriceCents, 2500)
        XCTAssertEqual(booking.currency, "MYR")
    }

    func test_accept_postsToAcceptEndpoint_returnsAcceptedBooking() async throws {
        let bookingId = "10000000-0000-4000-8000-000000000001"
        MockURLProtocol.requestHandler = { request in
            XCTAssertEqual(request.url?.path, "/api/v1/bookings/\(bookingId)/accept")
            XCTAssertEqual(request.httpMethod, "POST")
            return Self.jsonResponse(
                request: request,
                statusCode: 200,
                body: Self.envelope(Self.requestedBookingJSON.replacingOccurrences(of: #""status": "requested""#, with: #""status": "accepted""#))
            )
        }

        let booking = try await repository.accept(id: bookingId)
        XCTAssertEqual(booking.status, .accepted)
    }

    func test_decline_postsReasonToEndpoint() async throws {
        let bookingId = "10000000-0000-4000-8000-000000000001"
        MockURLProtocol.requestHandler = { request in
            XCTAssertEqual(request.url?.path, "/api/v1/bookings/\(bookingId)/decline")
            XCTAssertEqual(request.httpMethod, "POST")
            let body = try XCTUnwrap(request.httpBody)
            let json = try JSONSerialization.jsonObject(with: body) as? [String: String]
            XCTAssertEqual(json?["reason"], "too_far")
            return Self.jsonResponse(request: request, statusCode: 202, body: "{}")
        }

        try await repository.decline(id: bookingId, reason: .tooFar)
    }

    func test_markPickup_postsToPickupEndpoint_returnsInProgressBooking() async throws {
        let bookingId = "10000000-0000-4000-8000-000000000001"
        MockURLProtocol.requestHandler = { request in
            XCTAssertEqual(request.url?.path, "/api/v1/bookings/\(bookingId)/pickup")
            XCTAssertEqual(request.httpMethod, "POST")
            return Self.jsonResponse(
                request: request,
                statusCode: 200,
                body: Self.envelope(Self.requestedBookingJSON.replacingOccurrences(of: #""status": "requested""#, with: #""status": "in_progress""#))
            )
        }

        let booking = try await repository.markPickup(id: bookingId)
        XCTAssertEqual(booking.status, .inProgress)
    }

    func test_markDelivered_postsToDeliverEndpoint_returnsDeliveredBooking() async throws {
        let bookingId = "10000000-0000-4000-8000-000000000001"
        MockURLProtocol.requestHandler = { request in
            XCTAssertEqual(request.url?.path, "/api/v1/bookings/\(bookingId)/deliver")
            XCTAssertEqual(request.httpMethod, "POST")
            return Self.jsonResponse(
                request: request,
                statusCode: 200,
                body: Self.envelope(Self.requestedBookingJSON.replacingOccurrences(of: #""status": "requested""#, with: #""status": "delivered""#))
            )
        }

        let booking = try await repository.markDelivered(id: bookingId)
        XCTAssertEqual(booking.status, .delivered)
    }

    func test_bookingStatus_decodesAllCases() throws {
        let cases: [(json: String, expected: BookingStatus)] = [
            ("requested", .requested),
            ("accepted", .accepted),
            ("in_progress", .inProgress),
            ("delivered", .delivered),
            ("completed", .completed),
            ("cancelled", .cancelled)
        ]
        let decoder = JSONDecoder()
        for (raw, expected) in cases {
            let json = "\"\(raw)\"".data(using: .utf8)!
            let decoded = try decoder.decode(BookingStatus.self, from: json)
            XCTAssertEqual(decoded, expected, "Expected \(raw) -> \(expected)")
        }
    }

    // MARK: - Fixtures

    private static func envelope(_ inner: String) -> String {
        #"{"data":\#(inner),"success":true}"#
    }

    private static let requestedBookingJSON = """
    {
      "id": "10000000-0000-4000-8000-000000000001",
      "booking_number": "BK-AB12CD",
      "owner_id": "20000000-0000-4000-8000-000000000001",
      "runner_id": null,
      "status": "requested",
      "pet_spec": {
        "pet_type": "cat",
        "breed": "Persian",
        "name": "Milo",
        "weight_kg": 4.5,
        "age_months": 24,
        "vaccinations": [],
        "special_needs": "",
        "photo_url": ""
      },
      "crate_requirement": {"size": "medium", "ventilated": true, "temperature_controlled": false},
      "pickup_address": {
        "line1": "123 Jalan Ampang",
        "line2": "",
        "city": "Kuala Lumpur",
        "state": "WP",
        "postal_code": "50450",
        "country": "MY",
        "latitude": 3.1626,
        "longitude": 101.7185
      },
      "dropoff_address": {
        "line1": "1 Jalan SS2/24",
        "line2": "",
        "city": "Petaling Jaya",
        "state": "Selangor",
        "postal_code": "47300",
        "country": "MY",
        "latitude": 3.1170,
        "longitude": 101.6190
      },
      "route_spec": {
        "pickup_lat": 3.1626,
        "pickup_lng": 101.7185,
        "dropoff_lat": 3.1170,
        "dropoff_lng": 101.6190,
        "distance_km": 12.4,
        "estimated_duration_min": 28,
        "polyline": ""
      },
      "estimated_price_cents": 2500,
      "currency": "MYR",
      "version": 1,
      "created_at": "2026-05-16T10:00:00Z",
      "updated_at": "2026-05-16T10:00:00Z"
    }
    """

    private static let paginatedTwoBookings: String = {
        let second = requestedBookingJSON
            .replacingOccurrences(of: "10000000-0000-4000-8000-000000000001", with: "10000000-0000-4000-8000-000000000002")
            .replacingOccurrences(of: "BK-AB12CD", with: "BK-ABCXYZ")
        return #"{"data":[\#(requestedBookingJSON),\#(second)],"pagination":{"limit":20,"page":1,"total":2,"total_pages":1},"success":true}"#
    }()

    private static func jsonResponse(request: URLRequest, statusCode: Int, body: String) -> (HTTPURLResponse, Data?) {
        let response = HTTPURLResponse(url: request.url!, statusCode: statusCode, httpVersion: nil, headerFields: nil)!
        return (response, body.data(using: .utf8))
    }
}

private final class BookingRepoInMemoryTokenStore: TokenStore {
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
