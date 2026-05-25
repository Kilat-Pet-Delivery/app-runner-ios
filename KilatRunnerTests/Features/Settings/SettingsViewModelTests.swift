import XCTest
import SwiftUI
@testable import KilatRunner

@MainActor
final class SettingsViewModelTests: XCTestCase {
    func test_toggleNotificationCategory_optimisticallyMutatesAndRollsBackOnError() async {
        let repository = FakeSettingsRepository()
        repository.updateError = NetworkError.serverError(500)
        let session = AppSession(tokenStore: EmptyTokenStore())
        let viewModel = SettingsViewModel(repository: repository, session: session, defaults: .ephemeral())

        XCTAssertEqual(viewModel.settings.notificationPreferences[.chat], true)

        await viewModel.toggle(.chat)

        XCTAssertEqual(viewModel.settings.notificationPreferences[.chat], true)
        XCTAssertNotNil(viewModel.errorMessage)
    }

    func test_languageChange_doesNotChangeAppCopyInThisPlan() async {
        let repository = FakeSettingsRepository()
        let session = AppSession(tokenStore: EmptyTokenStore())
        let viewModel = SettingsViewModel(repository: repository, session: session, defaults: .ephemeral())

        await viewModel.setLanguage(.malay)

        XCTAssertEqual(viewModel.settings.language, .malay)
        XCTAssertNil(session.colorSchemeOverride)
    }

    func test_themeChange_updatesAppSessionColorSchemeOverride() async {
        let repository = FakeSettingsRepository()
        let session = AppSession(tokenStore: EmptyTokenStore())
        let viewModel = SettingsViewModel(repository: repository, session: session, defaults: .ephemeral())

        await viewModel.setTheme(.dark)

        XCTAssertEqual(session.colorSchemeOverride, .dark)
        XCTAssertEqual(viewModel.settings.theme, .dark)
    }
}

private final class FakeSettingsRepository: SettingsRepositoryProtocol {
    var settings = UserSettings.fallback
    var updateError: Error?

    func fetchSettings() async throws -> UserSettings {
        settings
    }

    func updateSettings(_ settings: UserSettings) async throws -> UserSettings {
        if let updateError {
            throw updateError
        }
        self.settings = settings
        return settings
    }
}

private final class EmptyTokenStore: TokenStore {
    func accessToken() -> String? { nil }
    func refreshToken() -> String? { nil }
    func saveAccessToken(_ token: String) throws {}
    func saveRefreshToken(_ token: String) throws {}
    func clear() {}
}

private extension UserDefaults {
    static func ephemeral() -> UserDefaults {
        let suiteName = "settings-tests-\(UUID().uuidString)"
        let suite = UserDefaults(suiteName: suiteName)!
        suite.removePersistentDomain(forName: suiteName)
        return suite
    }
}
