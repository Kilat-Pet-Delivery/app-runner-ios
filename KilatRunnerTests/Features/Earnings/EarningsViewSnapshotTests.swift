import XCTest
@testable import KilatRunner

@MainActor
final class EarningsViewSnapshotTests: XCTestCase {

    func test_earnings_view_renders_hero_amount() {
        let vm = EarningsViewModel(repository: SnapshotMockEarningsRepository(), pageLimit: 20)
        vm.todayEarningsCents = 8_450
        vm.selectedPeriod = .today

        XCTAssertEqual(vm.periodTotalCents, 8_450,
                       "Today period should report todayEarningsCents as the hero amount")
        XCTAssertEqual(vm.currency, "MYR",
                       "Default currency is MYR; the hero formats RM-style with it")
    }

    func test_earnings_view_chart_block_is_placeholder() {
        let vm = EarningsViewModel(repository: SnapshotMockEarningsRepository(), pageLimit: 20)
        XCTAssertTrue(vm.chartIsPlaceholder,
                      "Phase 8 chart block must be flagged as placeholder; a real chart lands in a follow-up plan")
    }
}

private final class SnapshotMockEarningsRepository: EarningsRepositoryProtocol {
    func list(page: Int, limit: Int) async throws -> EarningsPage {
        EarningsPage(items: [], page: 1, limit: limit, total: 0)
    }
}
