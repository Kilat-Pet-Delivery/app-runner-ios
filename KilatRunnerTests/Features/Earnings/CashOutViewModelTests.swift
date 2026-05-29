import XCTest
@testable import KilatRunner

@MainActor
final class CashOutViewModelTests: XCTestCase {
    func test_defaultAmountIsMax() {
        let viewModel = CashOutViewModel(availableAmountCents: 23_400, repository: MockPayoutRepository())

        XCTAssertEqual(viewModel.amountCents, 23_400)
        XCTAssertEqual(viewModel.selectedQuickAmount, .max)
    }

    func test_quickAmount500_setsAmount() {
        let viewModel = CashOutViewModel(availableAmountCents: 80_000, repository: MockPayoutRepository())

        viewModel.selectQuickAmount(.fixed(50_000))

        XCTAssertEqual(viewModel.amountCents, 50_000)
    }

    func test_submit_callsRepoAndNavigatesToSent() async {
        let repository = MockPayoutRepository()
        let viewModel = CashOutViewModel(availableAmountCents: 23_400, repository: repository)

        await viewModel.submit()

        XCTAssertEqual(repository.cashOutCallCount, 1)
        XCTAssertEqual(repository.lastAmount, 23_400)
        XCTAssertEqual(viewModel.sentDetails?.cashOutID, "KR-CO-08274")
        XCTAssertEqual(viewModel.sentDetails?.etaMinutes, 30)
    }
}

final class MockPayoutRepository: PayoutRepositoryProtocol {
    var cashOutCallCount = 0
    var lastAmount: Int64?
    var lastDestinationID: String?

    func cashOut(amountMyrCents: Int64, destinationID: String) async throws -> CashOutResponse {
        cashOutCallCount += 1
        lastAmount = amountMyrCents
        lastDestinationID = destinationID
        return CashOutResponse(cashOutID: "KR-CO-08274", etaMinutes: 30)
    }
}
