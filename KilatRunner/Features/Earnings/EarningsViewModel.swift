import Foundation
import Observation

@Observable
final class EarningsViewModel {
    private(set) var earnings: [Earning] = []
    private(set) var isLoading = false
    private(set) var currentPage = 0
    private(set) var hasMore = true
    var errorMessage: String?

    @ObservationIgnored private let repository: EarningsRepositoryProtocol
    @ObservationIgnored private let pageLimit: Int

    init(repository: EarningsRepositoryProtocol = EarningsRepository(), pageLimit: Int = 20) {
        self.repository = repository
        self.pageLimit = pageLimit
    }

    @MainActor
    func loadFirstPage() async {
        guard !isLoading else { return }
        earnings = []
        currentPage = 0
        hasMore = true
        await load(page: 1, replacesExisting: true)
    }

    @MainActor
    func loadNextPage() async {
        guard hasMore, !isLoading else { return }
        await load(page: currentPage + 1, replacesExisting: false)
    }

    @MainActor
    private func load(page: Int, replacesExisting: Bool) async {
        errorMessage = nil
        isLoading = true
        defer { isLoading = false }

        do {
            let pageResult = try await repository.list(page: page, limit: pageLimit)
            earnings = replacesExisting ? pageResult.items : earnings + pageResult.items
            currentPage = pageResult.page
            hasMore = earnings.count < pageResult.total
        } catch let error as NetworkError {
            errorMessage = error.userMessage
        } catch {
            errorMessage = NetworkError.unknown(error.localizedDescription).userMessage
        }
    }
}
