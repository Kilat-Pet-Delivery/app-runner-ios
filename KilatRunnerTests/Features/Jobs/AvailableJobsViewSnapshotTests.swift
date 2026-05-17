import XCTest
import SwiftUI
import SnapshotTesting
@testable import KilatRunner

@MainActor
final class AvailableJobsViewSnapshotTests: XCTestCase {

    func test_available_jobs_view_renders_list() throws {
#if canImport(UIKit) && os(iOS)
        let viewModel = AvailableJobsViewModel(repository: SnapshotMockBookingRepository())
        viewModel.jobs = [Self.makeBooking(id: "10000000-0000-4000-8000-000000000001",
                                           bookingNumber: "BK-AB12CD",
                                           priceCents: 2800,
                                           distanceKm: 12.4),
                          Self.makeBooking(id: "10000000-0000-4000-8000-000000000002",
                                           bookingNumber: "BK-AB14EF",
                                           priceCents: 1850,
                                           distanceKm: 5.2)]
        renderSnapshot(viewModel: viewModel, style: .light, testName: "renders_list_light")
#else
        throw XCTSkip("Snapshot tests require an iOS simulator — skipped on macOS host.")
#endif
    }

    func test_available_jobs_view_empty_state_shows_empty_message() throws {
#if canImport(UIKit) && os(iOS)
        let viewModel = AvailableJobsViewModel(repository: SnapshotMockBookingRepository())
        viewModel.jobs = []
        XCTAssertTrue(viewModel.jobs.isEmpty)
        renderSnapshot(viewModel: viewModel, style: .light, testName: "empty_state_light")
#else
        throw XCTSkip("Snapshot tests require an iOS simulator — skipped on macOS host.")
#endif
    }

#if canImport(UIKit) && os(iOS)
    private func renderSnapshot(viewModel: AvailableJobsViewModel, style: UIUserInterfaceStyle, testName: String) {
        let view = NavigationStack { AvailableJobsView(viewModel: viewModel) }
        let vc = UIHostingController(rootView: view)
        vc.view.frame = CGRect(x: 0, y: 0, width: 390, height: 844)
        vc.overrideUserInterfaceStyle = style
        withSnapshotTesting(record: .missing) {
            assertSnapshot(of: vc, as: .image(on: .iPhone13Pro), named: testName)
        }
    }
#endif

    private static func makeBooking(id: String, bookingNumber: String, priceCents: Int, distanceKm: Double) -> Booking {
        let json = """
        {
          "id": "\(id)",
          "booking_number": "\(bookingNumber)",
          "owner_id": "20000000-0000-4000-8000-000000000001",
          "runner_id": null,
          "status": "requested",
          "pet_spec": {
            "pet_type": "cat", "breed": "Persian", "name": "Milo",
            "weight_kg": 4.5, "special_needs": "", "photo_url": ""
          },
          "pickup_address": {
            "line1": "123 Jalan Ampang", "line2": "", "city": "Kuala Lumpur",
            "state": "WP", "postal_code": "50450", "country": "MY",
            "latitude": 3.1626, "longitude": 101.7185
          },
          "dropoff_address": {
            "line1": "1 Jalan SS2/24", "line2": "", "city": "Petaling Jaya",
            "state": "Selangor", "postal_code": "47300", "country": "MY",
            "latitude": 3.1170, "longitude": 101.6190
          },
          "route_spec": {
            "pickup_lat": 3.1626, "pickup_lng": 101.7185,
            "dropoff_lat": 3.1170, "dropoff_lng": 101.6190,
            "distance_km": \(distanceKm), "estimated_duration_min": 28, "polyline": ""
          },
          "estimated_price_cents": \(priceCents),
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

private final class SnapshotMockBookingRepository: BookingRepositoryProtocol {
    func listAvailable() async throws -> [Booking] { [] }
    func get(id: String) async throws -> Booking { fatalError() }
    func accept(id: String) async throws -> Booking { fatalError() }
    func markPickup(id: String) async throws -> Booking { fatalError() }
    func markDelivered(id: String) async throws -> Booking { fatalError() }
}
