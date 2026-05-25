import Foundation
import XCTest
@testable import KilatRunner

@MainActor
final class JobHistoryViewModelTests: XCTestCase {
    func test_filterChip_appliesAndRefetches() async {
        let repository = JobHistoryRepositorySpy()
        repository.historyPages = [
            BookingHistoryPage(items: [JobBookingFixture.booking(id: "all-1", status: "completed")], nextCursor: ""),
            BookingHistoryPage(items: [JobBookingFixture.booking(id: "cancelled-1", status: "cancelled")], nextCursor: "")
        ]
        let viewModel = JobHistoryViewModel(repository: repository)

        await viewModel.loadFirstPage()
        await viewModel.applyFilter(.cancelled)

        XCTAssertEqual(repository.historyCalls.map(\.filter), [.all, .cancelled])
        XCTAssertEqual(viewModel.filter, .cancelled)
        XCTAssertEqual(viewModel.bookings.map(\.id), ["cancelled-1"])
    }

    func test_loadMore_appendsAndDeduplicatesOnCursor() async {
        let repository = JobHistoryRepositorySpy()
        repository.historyPages = [
            BookingHistoryPage(
                items: [
                    JobBookingFixture.booking(id: "job-1", status: "completed"),
                    JobBookingFixture.booking(id: "job-2", status: "completed")
                ],
                nextCursor: "cursor-2"
            ),
            BookingHistoryPage(
                items: [
                    JobBookingFixture.booking(id: "job-2", status: "completed"),
                    JobBookingFixture.booking(id: "job-3", status: "completed")
                ],
                nextCursor: ""
            )
        ]
        let viewModel = JobHistoryViewModel(repository: repository)

        await viewModel.loadFirstPage()
        await viewModel.loadMore()

        XCTAssertEqual(repository.historyCalls.map(\.cursor), [nil, "cursor-2"])
        XCTAssertEqual(viewModel.bookings.map(\.id), ["job-1", "job-2", "job-3"])
        XCTAssertFalse(viewModel.hasMore)
    }

}

enum JobBookingFixture {
    static func booking(
        id: String,
        status: String = "accepted",
        petType: String = "cat",
        scheduledAt: String? = nil,
        deliveredAt: String? = nil,
        updatedAt: String = "2026-05-25T10:00:00Z"
    ) -> Booking {
        let scheduled = scheduledAt.map { ",\"scheduled_at\":\"\($0)\"" } ?? ""
        let delivered = deliveredAt.map { ",\"delivered_at\":\"\($0)\"" } ?? ""
        let json = #"""
        {
          "id":"\#(id)",
          "booking_number":"BK-\#(id)",
          "owner_id":"owner-1",
          "runner_id":"runner-1",
          "status":"\#(status)",
          "pet_spec":{"pet_type":"\#(petType)","breed":"Mixed","name":"Milo","weight_kg":4.5,"special_needs":"","photo_url":""},
          "pickup_address":{"line1":"Pickup","line2":"","city":"Kuala Lumpur","state":"WP","postal_code":"50450","country":"MY","latitude":3.16,"longitude":101.71},
          "dropoff_address":{"line1":"Dropoff","line2":"","city":"Petaling Jaya","state":"Selangor","postal_code":"47300","country":"MY","latitude":3.11,"longitude":101.61},
          "route_spec":{"pickup_lat":3.16,"pickup_lng":101.71,"dropoff_lat":3.11,"dropoff_lng":101.61,"distance_km":12.4,"estimated_duration_min":28,"polyline":""},
          "estimated_price_cents":2500,
          "final_price_cents":3100,
          "currency":"MYR",
          "version":1,
          "created_at":"2026-05-20T10:00:00Z",
          "updated_at":"\#(updatedAt)"\#(scheduled)\#(delivered)
        }
        """#
        let decoder = JSONDecoder()
        decoder.keyDecodingStrategy = .convertFromSnakeCase
        decoder.dateDecodingStrategy = .iso8601
        return try! decoder.decode(Booking.self, from: Data(json.utf8))
    }
}

final class JobHistoryRepositorySpy: BookingRepositoryProtocol {
    struct HistoryCall: Equatable {
        let filter: BookingHistoryFilter
        let cursor: String?
        let limit: Int
    }

    var historyPages: [BookingHistoryPage] = []
    var scheduledBookings: [Booking] = []
    private(set) var historyCalls: [HistoryCall] = []

    func listAvailable() async throws -> [Booking] { [] }
    func get(id: String) async throws -> Booking { JobBookingFixture.booking(id: id) }
    func accept(id: String) async throws -> Booking { JobBookingFixture.booking(id: id) }
    func markPickup(id: String) async throws -> Booking { JobBookingFixture.booking(id: id) }
    func markDelivered(id: String) async throws -> Booking { JobBookingFixture.booking(id: id, status: "delivered") }

    func fetchHistory(filter: BookingHistoryFilter, cursor: String?, limit: Int) async throws -> BookingHistoryPage {
        historyCalls.append(HistoryCall(filter: filter, cursor: cursor, limit: limit))
        if historyPages.isEmpty {
            return BookingHistoryPage(items: [], nextCursor: "")
        }
        return historyPages.removeFirst()
    }

    func fetchScheduled() async throws -> [Booking] {
        scheduledBookings
    }
}
