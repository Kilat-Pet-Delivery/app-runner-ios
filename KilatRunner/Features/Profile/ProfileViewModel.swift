import Foundation
import Observation

@Observable
final class ProfileViewModel {
    var state: ProfileViewState?
    var errorMessage: String?
    private(set) var isLoading = false

    @ObservationIgnored private let repository: IdentityRepositoryProtocol

    init(repository: IdentityRepositoryProtocol = IdentityRepository()) {
        self.repository = repository
    }

    @MainActor
    func load() async {
        guard !isLoading else { return }
        isLoading = true
        errorMessage = nil
        defer { isLoading = false }

        do {
            async let profileTask = repository.fetchMe()
            async let tierTask = repository.fetchTier()
            let profile = try await profileTask
            do {
                let tier = try await tierTask
                state = ProfileViewState(profile: profile, tier: tier)
            } catch NetworkError.notFound {
                state = .bronzeFallback(profile: profile)
            }
        } catch let error as NetworkError {
            errorMessage = error.userMessage
        } catch {
            errorMessage = NetworkError.unknown(error.localizedDescription).userMessage
        }
    }
}
