import Foundation
import Observation

@Observable
final class AppSession {
    enum State: Equatable {
        case unauthenticated
        case authenticated
    }

    @ObservationIgnored private let tokenStore: TokenStore

    var state: State

    init(tokenStore: TokenStore = KeychainStore()) {
        self.tokenStore = tokenStore
        state = tokenStore.accessToken() == nil ? .unauthenticated : .authenticated
    }

    func markAuthenticated() {
        state = .authenticated
    }

    func logout() {
        tokenStore.clear()
        state = .unauthenticated
    }
}
