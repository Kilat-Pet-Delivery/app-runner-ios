import Foundation
import Observation

@MainActor
@Observable
final class ReviewsViewModel {
    private(set) var reviews: [RunnerReview] = []
    private(set) var isLoading = false
    var errorMessage: String?
    var selectedStars: Int?

    @ObservationIgnored private let repository: LoyaltyRepositoryProtocol

    init(repository: LoyaltyRepositoryProtocol = LoyaltyRepository()) {
        self.repository = repository
    }

    var filteredReviews: [RunnerReview] {
        guard let selectedStars else { return reviews }
        return reviews.filter { $0.rating == selectedStars }
    }

    var summaryChips: [(label: String, count: Int)] {
        [
            ("Friendly", reviews.filter { $0.comment.localizedCaseInsensitiveContains("friendly") }.count),
            ("Tipped", reviews.filter { ($0.tipCents ?? 0) > 0 }.count),
            ("5 star", reviews.filter { $0.rating == 5 }.count)
        ]
    }

    func load() async {
        errorMessage = nil
        isLoading = true
        defer { isLoading = false }

        do {
            reviews = try await repository.fetchReviews()
        } catch let error as NetworkError {
            errorMessage = error.userMessage
        } catch {
            errorMessage = NetworkError.unknown(error.localizedDescription).userMessage
        }
    }

    func selectStars(_ stars: Int?) {
        selectedStars = selectedStars == stars ? nil : stars
    }
}
