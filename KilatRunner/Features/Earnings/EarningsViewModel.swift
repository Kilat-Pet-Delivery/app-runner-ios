import Foundation
import Observation

enum EarningsPeriod: String, CaseIterable, Identifiable {
    case today, week, month, all

    var id: String { rawValue }

    var label: String {
        switch self {
        case .today: return "Today"
        case .week:  return "Week"
        case .month: return "Month"
        case .all:   return "All"
        }
    }
}

@Observable
final class EarningsViewModel {
    var earnings: [Earning] = []
    private(set) var isLoading = false
    private(set) var currentPage = 0
    private(set) var hasMore = true
    var errorMessage: String?
    var selectedPeriod: EarningsPeriod = .week
    var todayEarningsCents: Int = 0
    var nextPayoutCents: Int = 0
    var currency: String = "MYR"

    /// Phase 8 ships the chart as a striped placeholder; a real chart is
    /// deferred to a follow-up plan. This flag is asserted in tests.
    let chartIsPlaceholder = true

    var periodTotalCents: Int {
        switch selectedPeriod {
        case .today: return todayEarningsCents
        case .week, .month, .all:
            return earnings.reduce(0) { $0 + Int($1.amountCents) }
        }
    }

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
