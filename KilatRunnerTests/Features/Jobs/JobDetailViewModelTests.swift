import XCTest
@testable import KilatRunner

@MainActor
final class JobDetailViewModelTests: XCTestCase {
    func test_accept_success_setsAcceptedBookingId() async {
        let booking = Self.makeBooking(status: "requested")
        let accepted = Self.makeBooking(status: "accepted")
        let repository = JobDetailMockBookingRepository(acceptResult: .success(accepted))
        let viewModel = JobDetailViewModel(booking: booking, repository: repository)

        await viewModel.accept()

        XCTAssertEqual(viewModel.acceptedBookingId, accepted.id)
        XCTAssertFalse(viewModel.isAccepting)
        XCTAssertNil(viewModel.errorMessage)
        XCTAssertEqual(repository.acceptCallCount, 1)
        XCTAssertEqual(repository.lastAcceptedId, booking.id)
    }

    func test_accept_failure_setsError_doesNotSetAcceptedId() async {
        let booking = Self.makeBooking(status: "requested")
        let repository = JobDetailMockBookingRepository(acceptResult: .failure(NetworkError.forbidden))
        let viewModel = JobDetailViewModel(booking: booking, repository: repository)

        await viewModel.accept()

        XCTAssertNil(viewModel.acceptedBookingId)
        XCTAssertFalse(viewModel.isAccepting)
        XCTAssertEqual(viewModel.errorMessage, NetworkError.forbidden.userMessage)
    }

    func test_accept_setsIsAcceptingDuringCall() async {
        let booking = Self.makeBooking(status: "requested")
        let accepted = Self.makeBooking(status: "accepted")
        let repository = JobDetailMockBookingRepository(
            acceptResult: .success(accepted),
            delayNanoseconds: 100_000_000
        )
        let viewModel = JobDetailViewModel(booking: booking, repository: repository)

        let task = Task { await viewModel.accept() }
        try? await Task.sleep(nanoseconds: 10_000_000)

        XCTAssertTrue(viewModel.isAccepting)

        await task.value
        XCTAssertFalse(viewModel.isAccepting)
    }

    // MARK: - Fixtures

    private static func makeBooking(status: String) -> Booking {
        let json = """
        {
          "id": "10000000-0000-4000-8000-000000000001",
          "booking_number": "BK-AB12CD",
          "owner_id": "20000000-0000-4000-8000-000000000001",
          "runner_id": null,
          "status": "\(status)",
          "pet_spec": {
            "pet_type": "cat",
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

private final class JobDetailMockBookingRepository: BookingRepositoryProtocol {
    private let acceptResult: Result<Booking, Error>
    private let delayNanoseconds: UInt64
    private(set) var acceptCallCount = 0
    private(set) var lastAcceptedId: String?

    init(acceptResult: Result<Booking, Error>, delayNanoseconds: UInt64 = 0) {
        self.acceptResult = acceptResult
        self.delayNanoseconds = delayNanoseconds
    }

    func listAvailable() async throws -> [Booking] { [] }

    func get(id: String) async throws -> Booking {
        throw NetworkError.notFound
    }

    func accept(id: String) async throws -> Booking {
        acceptCallCount += 1
        lastAcceptedId = id
        if delayNanoseconds > 0 {
            try? await Task.sleep(nanoseconds: delayNanoseconds)
        }
        return try acceptResult.get()
    }

    func markPickup(id: String) async throws -> Booking {
        throw NetworkError.notFound
    }

    func markDelivered(id: String) async throws -> Booking {
        throw NetworkError.notFound
    }
}
