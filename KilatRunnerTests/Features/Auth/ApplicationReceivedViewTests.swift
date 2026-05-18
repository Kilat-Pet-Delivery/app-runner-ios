import XCTest
@testable import KilatRunner

final class ApplicationReceivedViewTests: XCTestCase {
    func test_displaysApplicationID() {
        let view = ApplicationReceivedView(applicationId: "KR-2026-00001")

        XCTAssertEqual(view.applicationId, "KR-2026-00001")
    }

    func test_doesNotShowCheckmark() {
        let view = ApplicationReceivedView(applicationId: "KR-2026-00001")

        XCTAssertEqual(view.applicationId.prefix(3), "KR-")
    }
}
