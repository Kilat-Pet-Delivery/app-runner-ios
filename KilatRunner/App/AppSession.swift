import Foundation
import SwiftUI
import Observation

@Observable
final class AppSession {
    enum State: Equatable {
        case unauthenticated
        case authenticated
    }

    @ObservationIgnored private let tokenStore: TokenStore

    var state: State
    var colorSchemeOverride: ColorScheme?

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

    func apply(theme: RunnerTheme) {
        switch theme {
        case .system:
            colorSchemeOverride = nil
        case .light:
            colorSchemeOverride = .light
        case .dark:
            colorSchemeOverride = .dark
        }
    }
}
