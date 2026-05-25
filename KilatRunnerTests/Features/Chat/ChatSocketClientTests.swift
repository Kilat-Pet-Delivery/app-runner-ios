import XCTest
@testable import KilatRunner

@MainActor
final class ChatSocketClientTests: XCTestCase {
    func test_decode_messageSent_fromEnvelope() throws {
        let json = """
        {
          "type": "chat.message.sent",
          "payload": {
            "id": "m-1",
            "thread_id": "t-1",
            "sender_id": "user-1",
            "sender_side": "other",
            "body": "hello",
            "attachment_url": null,
            "delivery_state": "sent",
            "timestamp": "2026-05-19T10:00:00Z"
          }
        }
        """
        let data = Data(json.utf8)

        let event = try XCTUnwrap(ChatSocketClient.decode(data))

        guard case let .messageSent(message) = event else {
            XCTFail("Expected .messageSent, got \(event)")
            return
        }
        XCTAssertEqual(message.id, "m-1")
        XCTAssertEqual(message.threadID, "t-1")
        XCTAssertEqual(message.body, "hello")
        XCTAssertEqual(message.deliveryState, .sent)
    }

    func test_decode_unknownType_returnsNil() {
        let json = """
        { "type": "chat.unknown", "payload": {} }
        """
        XCTAssertNil(ChatSocketClient.decode(Data(json.utf8)))
    }

    func test_decode_typingEvent_capturesIsActive() throws {
        let json = """
        {
          "type": "chat.typing",
          "payload": {
            "thread_id": "t-1",
            "sender_id": "user-1",
            "is_active": true
          }
        }
        """
        let event = try XCTUnwrap(ChatSocketClient.decode(Data(json.utf8)))

        guard case let .typing(threadID, senderID, isActive) = event else {
            XCTFail("Expected .typing, got \(event)")
            return
        }
        XCTAssertEqual(threadID, "t-1")
        XCTAssertEqual(senderID, "user-1")
        XCTAssertTrue(isActive)
    }
}
