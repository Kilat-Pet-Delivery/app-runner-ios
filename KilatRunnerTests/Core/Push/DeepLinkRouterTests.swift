import XCTest
@testable import KilatRunner

@MainActor
final class DeepLinkRouterTests: XCTestCase {
    func test_pendingIntent_isClearedAfterConsume() {
        let router = DeepLinkRouter()
        router.publish(.chatMessage(threadID: "thread-1"))

        XCTAssertEqual(router.consume(), .chatMessage(threadID: "thread-1"))
        XCTAssertNil(router.pendingIntent)
    }

    func test_coldLaunchIntent_isObservedByRoot_onFirstAppear() {
        let router = DeepLinkRouter(initialIntent: .surgeActive(zoneCode: "KLCC"))

        XCTAssertEqual(router.pendingIntent, .surgeActive(zoneCode: "KLCC"))
        XCTAssertEqual(router.consume(), .surgeActive(zoneCode: "KLCC"))
    }
}
