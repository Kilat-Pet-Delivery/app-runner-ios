import Foundation
import XCTest
@testable import KilatRunner

@MainActor
final class ResetSentViewTests: XCTestCase {
    func test_resetSentView_rendersEnvelopeIcon() {
        let view = ResetSentView(email: "runner.test@kilat.my")

        XCTAssertEqual(view.email, "runner.test@kilat.my")
    }

    func test_resetSentView_openMailApp_opensCorrectURL() {
        var openedURL: URL?
        let view = ResetSentView(email: "runner.test@kilat.my") { url in
            openedURL = url
        }

        view.openMailApp()

        XCTAssertEqual(openedURL?.absoluteString, "message://")
    }

    func test_resetSentView_resend_callsForgotPasswordAgain() async {
        let repo = MockPasswordResetRepository()
        let view = ResetSentView(email: "runner.test@kilat.my", repository: repo)

        await view.resend()

        XCTAssertEqual(repo.forgotPasswordCallCount, 1)
        XCTAssertEqual(repo.lastEmail, "runner.test@kilat.my")
    }
}
