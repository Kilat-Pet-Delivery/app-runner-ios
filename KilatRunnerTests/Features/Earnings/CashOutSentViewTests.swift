import XCTest
@testable import KilatRunner

final class CashOutSentViewTests: XCTestCase {
    func test_displaysTransactionID() {
        let details = makeDetails()
        let view = CashOutSentView(details: details)

        XCTAssertEqual(view.details.cashOutID, "KR-CO-08274")
    }

    func test_usesGreenAccent_notCoral() {
        XCTAssertTrue(CashOutSentView.usesGreenAccent)
    }

    func test_backToEarnings_popsTwice() {
        let view = CashOutSentView(details: makeDetails())

        XCTAssertEqual(view.details.amountCents, 23_400)
    }

    private func makeDetails() -> CashOutSentDetails {
        CashOutSentDetails(
            cashOutID: "KR-CO-08274",
            amountCents: 23_400,
            destinationLabel: "Maybank Wallet - 4521",
            etaMinutes: 30,
            requestedAt: Date(timeIntervalSince1970: 0)
        )
    }
}
