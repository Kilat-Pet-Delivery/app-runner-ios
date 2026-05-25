import XCTest
@testable import KilatRunner

@MainActor
final class PreTripChecklistViewModelTests: XCTestCase {
    func test_allChecked_enablesPrimary() {
        let viewModel = PreTripChecklistViewModel(bookingID: "booking-1", repository: PreTripRepositorySpy())

        XCTAssertFalse(viewModel.isReady)

        for item in PreTripChecklistItem.allCases {
            viewModel.toggle(item)
        }

        XCTAssertTrue(viewModel.isReady)
    }
}

private final class PreTripRepositorySpy: PreTripChecklistRepositoryProtocol {
    func submit(bookingID: String, checkedItems: [PreTripChecklistItem]) async throws {}
}
