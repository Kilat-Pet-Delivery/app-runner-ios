import XCTest
@testable import KilatRunner

@MainActor
final class PerformanceViewModelTests: XCTestCase {
    func test_barChart_dataIsLast7Days_withTodayHighlighted() async throws {
        let repository = PerformanceRepositorySpy()
        repository.tier = TierSnapshot(
            tier: .silver,
            deliveries30D: 42,
            onTimeRate: 0.92,
            acceptanceRate: 0.84,
            ratingAverage: 4.92
        )
        let today = try XCTUnwrap(Self.date("2026-05-25T12:00:00Z"))
        let viewModel = PerformanceViewModel(repository: repository, today: { today })

        await viewModel.load()

        let bars = try XCTUnwrap(viewModel.state?.weeklyOnTime)
        XCTAssertEqual(bars.count, 7)
        XCTAssertEqual(bars.last?.label, "Mon")
        XCTAssertEqual(bars.filter(\.highlight).map(\.label), ["Mon"])
        XCTAssertGreaterThan(bars.last?.value ?? 0, 90)
    }

    private static func date(_ value: String) -> Date? {
        ISO8601DateFormatter().date(from: value)
    }
}

private final class PerformanceRepositorySpy: PerformanceRepositoryProtocol {
    var tier = TierSnapshot(
        tier: .bronze,
        deliveries30D: 0,
        onTimeRate: 0,
        acceptanceRate: 0,
        ratingAverage: 0
    )

    func fetchTier() async throws -> TierSnapshot {
        tier
    }
}
