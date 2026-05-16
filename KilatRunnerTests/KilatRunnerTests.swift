import XCTest
@testable import KilatRunner

final class KilatRunnerTests: XCTestCase {
    func testAppSessionStartsUnauthenticated() {
        let session = AppSession()

        XCTAssertEqual(session.state, .unauthenticated)
    }
}
