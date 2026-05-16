import XCTest
@testable import KilatRunner

@MainActor
final class LoginViewModelTests: XCTestCase {
    func test_login_success_setsSessionAuthenticated() async {
        let session = AppSession(tokenStore: LoginViewModelInMemoryTokenStore())
        let repository = MockAuthRepository(result: .success(Self.user))
        let viewModel = LoginViewModel(
            email: "runner.test@kilat.my",
            password: "TestRunner123!",
            authRepository: repository,
            appSession: session
        )

        await viewModel.login()

        XCTAssertEqual(session.state, .authenticated)
        XCTAssertFalse(viewModel.isSubmitting)
        XCTAssertNil(viewModel.errorMessage)
    }

    func test_login_failure_setsErrorMessage_doesNotAuthenticate() async {
        let session = AppSession(tokenStore: LoginViewModelInMemoryTokenStore())
        let repository = MockAuthRepository(result: .failure(NetworkError.unauthorized))
        let viewModel = LoginViewModel(
            email: "runner.test@kilat.my",
            password: "wrong",
            authRepository: repository,
            appSession: session
        )

        await viewModel.login()

        XCTAssertEqual(session.state, .unauthenticated)
        XCTAssertEqual(viewModel.errorMessage, NetworkError.unauthorized.userMessage)
    }

    func test_login_setsIsSubmittingDuringCall() async {
        let session = AppSession(tokenStore: LoginViewModelInMemoryTokenStore())
        let repository = MockAuthRepository(result: .success(Self.user), delayNanoseconds: 100_000_000)
        let viewModel = LoginViewModel(
            email: "runner.test@kilat.my",
            password: "TestRunner123!",
            authRepository: repository,
            appSession: session
        )

        let task = Task { await viewModel.login() }
        try? await Task.sleep(nanoseconds: 10_000_000)

        XCTAssertTrue(viewModel.isSubmitting)

        await task.value
        XCTAssertFalse(viewModel.isSubmitting)
    }

    func test_login_emptyEmailOrPassword_setsValidationError_skipsNetwork() async {
        let session = AppSession(tokenStore: LoginViewModelInMemoryTokenStore())
        let repository = MockAuthRepository(result: .success(Self.user))
        let viewModel = LoginViewModel(
            email: "",
            password: "",
            authRepository: repository,
            appSession: session
        )

        await viewModel.login()

        XCTAssertEqual(viewModel.errorMessage, "Enter your email and password.")
        XCTAssertEqual(repository.loginCallCount, 0)
        XCTAssertEqual(session.state, .unauthenticated)
    }

    private static let user = AuthenticatedUser(
        id: "11111111-1111-4111-8111-111111111111",
        email: "runner.test@kilat.my",
        phone: "+60123456780",
        fullName: "Test Runner",
        role: "runner",
        isVerified: true,
        avatarURL: nil,
        createdAt: nil
    )
}

private final class MockAuthRepository: AuthRepositoryProtocol {
    private let result: Result<AuthenticatedUser, Error>
    private let delayNanoseconds: UInt64
    private(set) var loginCallCount = 0

    init(result: Result<AuthenticatedUser, Error>, delayNanoseconds: UInt64 = 0) {
        self.result = result
        self.delayNanoseconds = delayNanoseconds
    }

    func login(email: String, password: String) async throws -> AuthenticatedUser {
        loginCallCount += 1
        if delayNanoseconds > 0 {
            try? await Task.sleep(nanoseconds: delayNanoseconds)
        }
        return try result.get()
    }
}

private final class LoginViewModelInMemoryTokenStore: TokenStore {
    private var storedAccessToken: String?
    private var storedRefreshToken: String?

    func saveAccessToken(_ token: String) throws {
        storedAccessToken = token
    }

    func accessToken() -> String? {
        storedAccessToken
    }

    func saveRefreshToken(_ token: String) throws {
        storedRefreshToken = token
    }

    func refreshToken() -> String? {
        storedRefreshToken
    }

    func clear() {
        storedAccessToken = nil
        storedRefreshToken = nil
    }
}
