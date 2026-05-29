import XCTest
@testable import KilatRunner

@MainActor
final class DeliveryCompleteViewModelTests: XCTestCase {
    func test_tagSelection_allowsMultiple_upToFive() {
        let viewModel = DeliveryCompleteViewModel { _ in ActiveDeliveryFixture.makeBooking() }

        for tag in DeliveryCompleteViewModel.availableTags {
            viewModel.toggleTag(tag)
        }
        viewModel.toggleTag("Extra")

        XCTAssertEqual(viewModel.selectedTags.count, 5)
        XCTAssertEqual(viewModel.selectedTags, DeliveryCompleteViewModel.availableTags)
    }

    func test_complete_submitsAndMarksComplete_onSuccess() async {
        var submitted: CustomerRatingRequest?
        let viewModel = DeliveryCompleteViewModel { request in
            submitted = request
            return ActiveDeliveryFixture.makeBooking()
        }
        viewModel.rating = 4
        viewModel.toggleTag("Friendly")

        await viewModel.complete()

        XCTAssertTrue(viewModel.didComplete)
        XCTAssertEqual(submitted, CustomerRatingRequest(rating: 4, tags: ["Friendly"]))
    }
}
