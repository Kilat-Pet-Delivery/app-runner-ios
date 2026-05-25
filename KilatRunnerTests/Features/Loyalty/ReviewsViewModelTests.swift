import XCTest
@testable import KilatRunner

@MainActor
final class ReviewsViewModelTests: XCTestCase {
    func test_filterByStars_refiltersFeed_locally() async throws {
        let repository = LoyaltyRepositorySpy()
        repository.reviews = [
            try ReviewFixture.review(id: "one", rating: 5),
            try ReviewFixture.review(id: "two", rating: 4),
            try ReviewFixture.review(id: "three", rating: 5)
        ]
        let viewModel = ReviewsViewModel(repository: repository)

        await viewModel.load()
        viewModel.selectStars(5)

        XCTAssertEqual(viewModel.filteredReviews.map(\.id), ["one", "three"])
        XCTAssertEqual(repository.reviewFetches, 1)

        viewModel.selectStars(5)

        XCTAssertNil(viewModel.selectedStars)
        XCTAssertEqual(viewModel.filteredReviews.count, 3)
        XCTAssertEqual(repository.reviewFetches, 1)
    }
}

private enum ReviewFixture {
    static func review(id: String, rating: Int) throws -> RunnerReview {
        RunnerReview(
            id: id,
            customerName: "Sarah",
            rating: rating,
            comment: rating == 5 ? "Friendly and clear" : "Smooth trip",
            tipCents: rating == 5 ? 500 : nil,
            createdAt: try XCTUnwrap(ISO8601DateFormatter().date(from: "2026-05-25T10:00:00Z"))
        )
    }
}
