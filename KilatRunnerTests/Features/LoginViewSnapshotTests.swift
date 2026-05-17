import XCTest
import SwiftUI
import SnapshotTesting
@testable import KilatRunner

@MainActor
final class LoginViewSnapshotTests: XCTestCase {

    func test_login_view_renders_stamp_paw_logo_light() throws {
#if canImport(UIKit) && os(iOS)
        let viewModel = Self.makeViewModel()
        let vc = UIHostingController(rootView: LoginView(viewModel: viewModel))
        vc.view.frame = CGRect(x: 0, y: 0, width: 390, height: 844)
        vc.overrideUserInterfaceStyle = .light
        withSnapshotTesting(record: .missing) {
            assertSnapshot(of: vc, as: .image(on: .iPhone13Pro))
        }
#else
        throw XCTSkip("Snapshot tests require an iOS simulator — skipped on macOS host.")
#endif
    }

    func test_login_view_renders_stamp_paw_logo_dark() throws {
#if canImport(UIKit) && os(iOS)
        let viewModel = Self.makeViewModel()
        let vc = UIHostingController(rootView: LoginView(viewModel: viewModel))
        vc.view.frame = CGRect(x: 0, y: 0, width: 390, height: 844)
        vc.overrideUserInterfaceStyle = .dark
        withSnapshotTesting(record: .missing) {
            assertSnapshot(of: vc, as: .image(on: .iPhone13Pro))
        }
#else
        throw XCTSkip("Snapshot tests require an iOS simulator — skipped on macOS host.")
#endif
    }

    func test_login_view_sign_in_disabled_until_form_valid() {
        let viewModel = Self.makeViewModel()

        XCTAssertFalse(viewModel.isFormValid,
                       "Empty form should not be valid")

        viewModel.email = "runner.test@kilat.my"
        XCTAssertFalse(viewModel.isFormValid,
                       "Email alone should not be valid")

        viewModel.password = "TestRunner123!"
        XCTAssertTrue(viewModel.isFormValid,
                      "Email + password should be valid")

        viewModel.email = "   "
        XCTAssertFalse(viewModel.isFormValid,
                       "Whitespace-only email should not be valid")
    }

    private static func makeViewModel() -> LoginViewModel {
        LoginViewModel(
            authRepository: AlwaysFailAuthRepository(),
            appSession: AppSession(tokenStore: SnapshotInMemoryTokenStore())
        )
    }
}

private final class AlwaysFailAuthRepository: AuthRepositoryProtocol {
    func login(email: String, password: String) async throws -> AuthenticatedUser {
        throw NetworkError.unauthorized
    }
}

private final class SnapshotInMemoryTokenStore: TokenStore {
    func saveAccessToken(_ token: String) throws {}
    func accessToken() -> String? { nil }
    func saveRefreshToken(_ token: String) throws {}
    func refreshToken() -> String? { nil }
    func clear() {}
}
