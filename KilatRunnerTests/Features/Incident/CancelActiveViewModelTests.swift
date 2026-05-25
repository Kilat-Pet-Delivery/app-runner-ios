import XCTest
@testable import KilatRunner

@MainActor
final class CancelActiveViewModelTests: XCTestCase {
    func test_petEmergency_routesToSOS_withoutCreatingIncident() async {
        let repository = IncidentRepositorySpy()
        let viewModel = CancelActiveViewModel(bookingID: "booking-1", repository: repository)
        viewModel.selectedReason = .petEmergency

        await viewModel.submit()

        XCTAssertEqual(viewModel.route, .sos)
        XCTAssertEqual(repository.createCalls.count, 0)
    }

    func test_otherReason_createsIncident_withTypeCancelActive() async {
        let repository = IncidentRepositorySpy()
        let viewModel = CancelActiveViewModel(bookingID: "booking-1", repository: repository)
        viewModel.selectedReason = .other
        viewModel.notes = "Customer cancelled at lobby"

        await viewModel.submit()

        XCTAssertTrue(viewModel.didSubmit)
        XCTAssertEqual(repository.createCalls.count, 1)
        XCTAssertEqual(repository.createCalls[0].type, .cancelActive)
        XCTAssertEqual(repository.createCalls[0].bookingID, "booking-1")
        XCTAssertEqual(repository.createCalls[0].notes, "Other: Customer cancelled at lobby")
    }
}
