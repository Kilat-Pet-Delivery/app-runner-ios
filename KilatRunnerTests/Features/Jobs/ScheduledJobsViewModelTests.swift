import Foundation
import XCTest
@testable import KilatRunner

@MainActor
final class ScheduledJobsViewModelTests: XCTestCase {
    func test_load_groupsByDayBucket() async {
        let repository = JobHistoryRepositorySpy()
        repository.scheduledBookings = [
            JobBookingFixture.booking(id: "tomorrow", scheduledAt: "2026-05-26T03:00:00Z"),
            JobBookingFixture.booking(id: "this-week", scheduledAt: "2026-05-30T03:00:00Z"),
            JobBookingFixture.booking(id: "next-week", scheduledAt: "2026-06-05T03:00:00Z"),
            JobBookingFixture.booking(id: "later", scheduledAt: "2026-06-20T03:00:00Z")
        ]
        let viewModel = ScheduledJobsViewModel(
            repository: repository,
            now: { Date(timeIntervalSince1970: 1_779_667_200) }, // 2026-05-25T00:00:00Z
            calendar: Calendar(identifier: .gregorian)
        )

        await viewModel.load()

        XCTAssertEqual(viewModel.sections.map(\.bucket), [.tomorrow, .thisWeek, .nextWeek, .later])
        XCTAssertEqual(viewModel.sections.map { $0.bookings.map(\.id) }, [["tomorrow"], ["this-week"], ["next-week"], ["later"]])
    }
}
