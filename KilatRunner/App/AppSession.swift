import Foundation
import Observation

@Observable
final class AppSession {
    enum State: Equatable {
        case unauthenticated
        case authenticated
    }

    var state: State = .unauthenticated

    func markAuthenticated() {
        state = .authenticated
    }

    func logout() {
        state = .unauthenticated
    }
}
