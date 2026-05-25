import XCTest
@testable import KilatRunner

@MainActor
final class VetPickupDetailViewModelTests: XCTestCase {
    func test_vetKindBooking_routesToVetPickupView() {
        let booking = Self.makeVetBooking()
        let jobViewModel = JobDetailViewModel(
            booking: booking,
            repository: VetPickupMockBookingRepository()
        )
        let viewModel = VetPickupDetailViewModel(jobDetailViewModel: jobViewModel)

        XCTAssertTrue(viewModel.routesToVetPickupView)
        XCTAssertEqual(viewModel.medications.first?.name, "Antibiotic")
        XCTAssertTrue(viewModel.requiresColdChain)
    }

    private static func makeVetBooking() -> Booking {
        let json = """
        {
          "id": "10000000-0000-4000-8000-000000000010",
          "booking_number": "BK-VET01",
          "owner_id": "20000000-0000-4000-8000-000000000001",
          "runner_id": null,
          "status": "requested",
          "kind": "vet",
          "pet_spec": {
            "pet_type": "dog",
            "breed": "Beagle",
            "name": "Bobo",
            "weight_kg": 10.4,
            "special_needs": "Post-op",
            "photo_url": ""
          },
          "vet_spec": {
            "condition": "Post-op observation",
            "medications": [
              {
                "id": "med-1",
                "name": "Antibiotic",
                "dosage": "5 ml every 8 hours",
                "requires_cold_chain": true
              }
            ],
            "handling_instructions": "Keep calm and avoid stairs.",
            "vet_name": "Happy Vet Clinic",
            "vet_phone": "+60312345678",
            "requires_cold_chain": true
          },
          "pickup_address": {
            "line1": "Happy Vet Clinic",
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
          "estimated_price_cents": 3800,
          "currency": "MYR",
          "version": 1,
          "created_at": "2026-05-16T10:00:00Z",
          "updated_at": "2026-05-16T10:00:00Z"
        }
        """
        let decoder = JSONDecoder()
        decoder.keyDecodingStrategy = .convertFromSnakeCase
        decoder.dateDecodingStrategy = .iso8601
        return try! decoder.decode(Booking.self, from: Data(json.utf8))
    }
}

private final class VetPickupMockBookingRepository: BookingRepositoryProtocol {
    func listAvailable() async throws -> [Booking] { [] }
    func get(id: String) async throws -> Booking { throw NetworkError.notFound }
    func accept(id: String) async throws -> Booking { throw NetworkError.notFound }
    func markPickup(id: String) async throws -> Booking { throw NetworkError.notFound }
    func markDelivered(id: String) async throws -> Booking { throw NetworkError.notFound }
}
