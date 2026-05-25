import XCTest
@testable import KilatRunner

final class JobAcceptedViewTests: XCTestCase {
    func test_rendersJobSummary() {
        let booking = Self.makeBooking(petType: "cat")
        let view = JobAcceptedView(booking: booking)

        XCTAssertEqual(view.booking.bookingNumber, "BK-AB12CD")
        XCTAssertEqual(view.booking.pickupAddress.city, "Kuala Lumpur")
        XCTAssertEqual(view.booking.dropoffAddress.city, "Petaling Jaya")
    }

    func test_livePet_showsBanner() {
        XCTAssertTrue(Self.makeBooking(petType: "cat").isLivePet)
    }

    func test_nonLivePet_hidesBanner() {
        XCTAssertFalse(Self.makeBooking(petType: "supplies").isLivePet)
    }

    func test_livePet_routesToPreTripChecklist() {
        let view = JobAcceptedView(booking: Self.makeBooking(petType: "cat"))

        XCTAssertEqual(view.startDestination, .preTripChecklist)
    }

    func test_nonLivePet_routesDirectlyToActiveDelivery() {
        let view = JobAcceptedView(booking: Self.makeBooking(petType: "supplies"))

        XCTAssertEqual(view.startDestination, .activeDelivery)
    }

    private static func makeBooking(petType: String) -> Booking {
        let json = """
        {
          "id": "10000000-0000-4000-8000-000000000001",
          "booking_number": "BK-AB12CD",
          "owner_id": "20000000-0000-4000-8000-000000000001",
          "runner_id": null,
          "status": "accepted",
          "pet_spec": {
            "pet_type": "\(petType)",
            "breed": "Persian",
            "name": "Milo",
            "weight_kg": 4.5,
            "special_needs": "",
            "photo_url": ""
          },
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
        let decoder = JSONDecoder()
        decoder.keyDecodingStrategy = .convertFromSnakeCase
        decoder.dateDecodingStrategy = .iso8601
        return try! decoder.decode(Booking.self, from: json.data(using: .utf8)!)
    }
}
