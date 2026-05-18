import XCTest
@testable import KilatRunner

@MainActor
final class ForgotPasswordViewModelTests: XCTestCase {
    func test_submit_callsRepo() async {
        let repo = MockPasswordResetRepository()
        let viewModel = ForgotPasswordViewModel(email: " runner.test@kilat.my ", repository: repo)

        await viewModel.submit()

        XCTAssertEqual(repo.forgotPasswordCallCount, 1)
        XCTAssertEqual(repo.lastEmail, "runner.test@kilat.my")
        XCTAssertTrue(viewModel.didSendResetLink)
        XCTAssertNil(viewModel.errorMessage)
    }

    func test_submit_onSuccess_navigatesToSent() async {
        let viewModel = ForgotPasswordViewModel(
            email: "runner.test@kilat.my",
            repository: MockPasswordResetRepository()
        )

        await viewModel.submit()

        XCTAssertTrue(viewModel.didSendResetLink)
    }

    func test_submit_invalidEmail_skipsRepo() async {
        let repo = MockPasswordResetRepository()
        let viewModel = ForgotPasswordViewModel(email: "runner", repository: repo)

        await viewModel.submit()

        XCTAssertEqual(repo.forgotPasswordCallCount, 0)
        XCTAssertEqual(viewModel.errorMessage, "Enter a valid email address.")
    }
}

final class MockPasswordResetRepository: PasswordResetRepositoryProtocol {
    var forgotPasswordCallCount = 0
    var resetPasswordCallCount = 0
    var lastEmail: String?
    var result: Result<Void, Error> = .success(())

    func forgotPassword(email: String) async throws {
        forgotPasswordCallCount += 1
        lastEmail = email
        try result.get()
    }

    func resetPassword(token: String, newPassword: String) async throws {
        resetPasswordCallCount += 1
        try result.get()
    }
}
