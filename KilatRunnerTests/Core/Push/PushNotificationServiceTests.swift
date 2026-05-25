import XCTest
@testable import KilatRunner

final class PushNotificationServiceTests: XCTestCase {
    func test_decode_chatMessagePayload_producesChatMessageIntent() {
        let intent = PushNotificationService().decodeIntent(userInfo: [
            "aps": ["category": "chat_message"],
            "thread_id": "thread-42"
        ])

        XCTAssertEqual(intent, .chatMessage(threadID: "thread-42"))
    }

    func test_decode_tipReceivedPayload_populatesAllFields() {
        let intent = PushNotificationService().decodeIntent(userInfo: [
            "aps": ["category": "tip_received"],
            "booking_id": "booking-1",
            "tip_amount_myr": 12.5,
            "customer_name": "Aina",
            "message": "Smooth ride",
            "thread_id": "thread-9"
        ])

        XCTAssertEqual(
            intent,
            .tipReceived(
                TipReceivedPayload(
                    bookingID: "booking-1",
                    tipAmountMYR: 12.5,
                    customerName: "Aina",
                    message: "Smooth ride",
                    threadID: "thread-9"
                )
            )
        )
    }

    func test_unknownCategory_doesNotCrash_andLogs() {
        let intent = PushNotificationService().decodeIntent(userInfo: [
            "aps": ["category": "mystery"]
        ])

        XCTAssertNil(intent)
    }
}
