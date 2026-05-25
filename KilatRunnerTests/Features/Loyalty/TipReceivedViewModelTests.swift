import Foundation
import XCTest
@testable import KilatRunner

@MainActor
final class TipReceivedViewModelTests: XCTestCase {
    func test_decodePushPayload_populatesAllFields() throws {
        let json = #"""
        {
          "booking_id": "booking-1",
          "tip_amount_myr": 12.5,
          "customer_name": "Sarah",
          "message": "Milo arrived happy!",
          "thread_id": "thread-1"
        }
        """#.data(using: .utf8)!

        let viewModel = try TipReceivedViewModel(jsonData: json)

        XCTAssertEqual(viewModel.bookingID, "booking-1")
        XCTAssertEqual(viewModel.tipAmountMYR, 12.5)
        XCTAssertEqual(viewModel.customerName, "Sarah")
        XCTAssertEqual(viewModel.message, "Milo arrived happy!")
        XCTAssertEqual(viewModel.threadID, "thread-1")
        XCTAssertEqual(viewModel.amountLabel, "RM 12.50")
    }

    func test_sendThankYou_opensChatThread_withPrefilledQuickReply() {
        let viewModel = TipReceivedViewModel(
            payload: TipReceivedPayload(
                bookingID: "booking-1",
                tipAmountMYR: 8,
                customerName: "Sarah",
                message: nil,
                threadID: "thread-1"
            )
        )

        viewModel.sendThankYou()

        XCTAssertEqual(viewModel.thankYouRoute?.threadID, "thread-1")
        XCTAssertEqual(viewModel.thankYouRoute?.quickReply, "Thank you for the tip, Sarah!")
    }
}
