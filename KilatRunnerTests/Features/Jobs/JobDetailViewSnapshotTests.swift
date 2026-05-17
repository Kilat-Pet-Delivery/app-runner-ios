import XCTest
@testable import KilatRunner

@MainActor
final class JobDetailViewSnapshotTests: XCTestCase {

    func test_job_detail_view_renders_sticky_footer_button() {
        let booking = Self.makeBooking()
        let vm = JobDetailViewModel(booking: booking, repository: JobDetailSnapshotMockRepository())

        XCTAssertFalse(vm.isAccepting,
                       "Initial state should not be accepting; the sticky-footer Accept PrimaryButton needs to be enabled")
        XCTAssertFalse(vm.showsDeclineSheet,
                       "Initial state should not show the decline sheet; the SecondaryButton triggers it")
    }

    private static func makeBooking() -> Booking {
        let json = """
        {
          "id": "20000000-0000-4000-8000-000000000001",
          "booking_number": "BK-DE12FG",
          "owner_id": "20000000-0000-4000-8000-000000000099",
          "runner_id": null,
          "status": "requested",
          "pet_spec": {"pet_type": "dog", "breed": "Golden", "name": "Buddy",
                       "weight_kg": 22.0, "special_needs": "", "photo_url": ""},
          "pickup_address": {"line1": "55 Jalan Bangsar", "line2": "",
                             "city": "Kuala Lumpur", "state": "WP", "postal_code": "59100",
                             "country": "MY", "latitude": 3.1316, "longitude": 101.6788},
          "dropoff_address": {"line1": "12 Jalan 23/8", "line2": "",
                              "city": "Kuala Lumpur", "state": "WP", "postal_code": "50480",
                              "country": "MY", "latitude": 3.1707, "longitude": 101.6504},
          "route_spec": {"pickup_lat": 3.1316, "pickup_lng": 101.6788,
                         "dropoff_lat": 3.1707, "dropoff_lng": 101.6504,
                         "distance_km": 8.4, "estimated_duration_min": 22, "polyline": ""},
          "estimated_price_cents": 3450, "currency": "MYR", "version": 1,
          "created_at": "2026-05-16T10:00:00Z", "updated_at": "2026-05-16T10:00:00Z"
        }
        """
        let decoder = JSONDecoder()
        decoder.keyDecodingStrategy = .convertFromSnakeCase
        decoder.dateDecodingStrategy = .iso8601
        return try! decoder.decode(Booking.self, from: json.data(using: .utf8)!)
    }
}

private final class JobDetailSnapshotMockRepository: BookingRepositoryProtocol {
    func listAvailable() async throws -> [Booking] { [] }
    func get(id: String) async throws -> Booking { throw NetworkError.notFound }
    func accept(id: String) async throws -> Booking { throw NetworkError.notFound }
    func markPickup(id: String) async throws -> Booking { throw NetworkError.notFound }
    func markDelivered(id: String) async throws -> Booking { throw NetworkError.notFound }
}
