import XCTest
@testable import KilatRunner

@MainActor
final class DeclineReasonViewModelTests: XCTestCase {
    func test_selectingReason_callsRepoAndDismisses() async {
        let repository = DeclineMockBookingRepository()
        let viewModel = DeclineReasonViewModel(bookingID: "booking-1", repository: repository)

        await viewModel.select(.tooFar)

        XCTAssertEqual(repository.declineCallCount, 1)
        XCTAssertEqual(repository.lastDeclineID, "booking-1")
        XCTAssertEqual(repository.lastReason, .tooFar)
        XCTAssertTrue(viewModel.didDismiss)
    }

    func test_skip_callsRepoWithOther() async {
        let repository = DeclineMockBookingRepository()
        let viewModel = DeclineReasonViewModel(bookingID: "booking-1", repository: repository)

        await viewModel.skip()

        XCTAssertEqual(repository.lastReason, .other)
        XCTAssertTrue(viewModel.didDismiss)
    }
}

private final class DeclineMockBookingRepository: BookingRepositoryProtocol {
    var declineCallCount = 0
    var lastDeclineID: String?
    var lastReason: DeclineReason?

    func listAvailable() async throws -> [Booking] { [] }
    func get(id: String) async throws -> Booking { throw NetworkError.notFound }
    func accept(id: String) async throws -> Booking { throw NetworkError.notFound }
    func decline(id: String, reason: DeclineReason) async throws {
        declineCallCount += 1
        lastDeclineID = id
        lastReason = reason
    }
    func markPickup(id: String) async throws -> Booking { throw NetworkError.notFound }
    func markDelivered(id: String) async throws -> Booking { throw NetworkError.notFound }
}
