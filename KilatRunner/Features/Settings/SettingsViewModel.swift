import Foundation
import Observation

protocol SettingsRepositoryProtocol {
    func fetchSettings() async throws -> UserSettings
    func updateSettings(_ settings: UserSettings) async throws -> UserSettings
}

final class SettingsRepository: SettingsRepositoryProtocol {
    private let authInterceptor: AuthInterceptor

    init(authInterceptor: AuthInterceptor) {
        self.authInterceptor = authInterceptor
    }

    convenience init(apiClient: APIClient = APIClient(), tokenStore: TokenStore = KeychainStore()) {
        self.init(authInterceptor: AuthInterceptor(apiClient: apiClient, tokenStore: tokenStore))
    }

    func fetchSettings() async throws -> UserSettings {
        let envelope: APIResponseEnvelope<UserSettings> = try await authInterceptor.perform(.meSettings)
        return envelope.data
    }

    func updateSettings(_ settings: UserSettings) async throws -> UserSettings {
        let envelope: APIResponseEnvelope<UserSettings> = try await authInterceptor.perform(.updateMeSettings, body: settings)
        return envelope.data
    }
}

@Observable
final class SettingsViewModel {
    var settings: UserSettings
    var errorMessage: String?
    private(set) var isLoading = false
    private(set) var isSaving = false

    @ObservationIgnored private let repository: SettingsRepositoryProtocol
    @ObservationIgnored private let session: AppSession
    @ObservationIgnored private let defaults: UserDefaults
    @ObservationIgnored private let cacheKey = "runner.settings.cache"

    init(
        repository: SettingsRepositoryProtocol = SettingsRepository(),
        session: AppSession,
        defaults: UserDefaults = .standard
    ) {
        self.repository = repository
        self.session = session
        self.defaults = defaults
        self.settings = Self.cachedSettings(defaults: defaults, key: Self.cacheKey) ?? .fallback
        session.apply(theme: settings.theme)
    }

    @MainActor
    func load() async {
        guard !isLoading else { return }
        isLoading = true
        errorMessage = nil
        defer { isLoading = false }
        do {
            settings = try await repository.fetchSettings()
            cache(settings)
            session.apply(theme: settings.theme)
        } catch let error as NetworkError {
            errorMessage = error.userMessage
        } catch {
            errorMessage = NetworkError.unknown(error.localizedDescription).userMessage
        }
    }

    @MainActor
    func toggle(_ category: NotificationCategory) async {
        let previous = settings
        settings.notificationPreferences[category] = !(settings.notificationPreferences[category] ?? true)
        await save(previous: previous)
    }

    @MainActor
    func setLanguage(_ language: RunnerLanguage) async {
        let previous = settings
        settings.language = language
        await save(previous: previous)
    }

    @MainActor
    func setTheme(_ theme: RunnerTheme) async {
        let previous = settings
        settings.theme = theme
        session.apply(theme: theme)
        await save(previous: previous)
    }

    @MainActor
    private func save(previous: UserSettings) async {
        guard !isSaving else { return }
        isSaving = true
        errorMessage = nil
        cache(settings)
        defer { isSaving = false }
        do {
            settings = try await repository.updateSettings(settings)
            cache(settings)
            session.apply(theme: settings.theme)
        } catch let error as NetworkError {
            settings = previous
            cache(previous)
            session.apply(theme: previous.theme)
            errorMessage = error.userMessage
        } catch {
            settings = previous
            cache(previous)
            session.apply(theme: previous.theme)
            errorMessage = NetworkError.unknown(error.localizedDescription).userMessage
        }
    }

    private func cache(_ settings: UserSettings) {
        if let data = try? JSONEncoder().encode(settings) {
            defaults.set(data, forKey: Self.cacheKey)
        }
    }

    private static func cachedSettings(defaults: UserDefaults, key: String) -> UserSettings? {
        guard let data = defaults.data(forKey: key) else { return nil }
        return try? JSONDecoder().decode(UserSettings.self, from: data)
    }

    private static let cacheKey = "runner.settings.cache"
}
