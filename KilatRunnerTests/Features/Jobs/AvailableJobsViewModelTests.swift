import XCTest
@testable import KilatRunner

@MainActor
final class AvailableJobsViewModelTests: XCTestCase {
    func test_load_populatesJobs() async {
        let repository = MockBookingRepository(listAvailableResult: .success([Self.booking1, Self.booking2]))
        let viewModel = AvailableJobsViewModel(repository: repository)

        await viewModel.load()

        XCTAssertEqual(viewModel.jobs, [Self.booking1, Self.booking2])
        XCTAssertFalse(viewModel.isLoading)
        XCTAssertNil(viewModel.errorMessage)
        XCTAssertEqual(repository.listAvailableCallCount, 1)
    }

    func test_load_emptyList_isHandled() async {
        let repository = MockBookingRepository(listAvailableResult: .success([]))
        let viewModel = AvailableJobsViewModel(repository: repository)

        await viewModel.load()

        XCTAssertEqual(viewModel.jobs, [])
        XCTAssertFalse(viewModel.isLoading)
        XCTAssertNil(viewModel.errorMessage)
    }

    func test_load_failure_setsError() async {
        let repository = MockBookingRepository(listAvailableResult: .failure(NetworkError.serverError(500)))
        let viewModel = AvailableJobsViewModel(repository: repository)

        await viewModel.load()

        XCTAssertEqual(viewModel.jobs, [])
        XCTAssertFalse(viewModel.isLoading)
        XCTAssertEqual(viewModel.errorMessage, NetworkError.serverError(500).userMessage)
    }

    func test_widenRadius_increasesSearchRadius_andSetsNotice() {
        let viewModel = AvailableJobsViewModel(repository: MockBookingRepository())

        viewModel.widenRadius()

        XCTAssertEqual(viewModel.searchRadiusKm, 12)
        XCTAssertEqual(viewModel.noticeMessage, "Search radius widened to 12 km.")
    }

    func test_createJobAlert_postsRadius_andSetsNotice() async {
        let repository = MockBookingRepository()
        let viewModel = AvailableJobsViewModel(repository: repository)

        await viewModel.createJobAlert()

        XCTAssertEqual(repository.createJobAlertRadiusKm, 8)
        XCTAssertEqual(viewModel.noticeMessage, "We'll notify you when jobs are available nearby.")
        XCTAssertFalse(viewModel.isCreatingJobAlert)
    }

    // MARK: - Fixtures

    private static let booking1 = AvailableJobsViewModelTests.makeBooking(id: "10000000-0000-4000-8000-000000000001", bookingNumber: "BK-AB12CD")
    private static let booking2 = AvailableJobsViewModelTests.makeBooking(id: "10000000-0000-4000-8000-000000000002", bookingNumber: "BK-ABCXYZ")

    private static func makeBooking(id: String, bookingNumber: String) -> Booking {
        let json = """
        {
          "id": "\(id)",
          "booking_number": "\(bookingNumber)",
          "owner_id": "20000000-0000-4000-8000-000000000001",
          "runner_id": null,
          "status": "requested",
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

private final class MockBookingRepository: BookingRepositoryProtocol {
    private let listAvailableResult: Result<[Booking], Error>
    private(set) var listAvailableCallCount = 0
    private(set) var createJobAlertRadiusKm: Int?

    init(listAvailableResult: Result<[Booking], Error> = .success([])) {
        self.listAvailableResult = listAvailableResult
    }

    func listAvailable() async throws -> [Booking] {
        listAvailableCallCount += 1
        return try listAvailableResult.get()
    }

    func createJobAlert(radiusKm: Int) async throws {
        createJobAlertRadiusKm = radiusKm
    }

    func get(id: String) async throws -> Booking {
        throw NetworkError.notFound
    }

    func accept(id: String) async throws -> Booking {
        throw NetworkError.notFound
    }

    func markPickup(id: String) async throws -> Booking {
        throw NetworkError.notFound
    }

    func markDelivered(id: String) async throws -> Booking {
        throw NetworkError.notFound
    }
}
