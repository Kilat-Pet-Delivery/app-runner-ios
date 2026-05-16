import Foundation
import Observation

@Observable
final class LoginViewModel {
    var email: String
    var password: String
    private(set) var isSubmitting = false
    var errorMessage: String?

    @ObservationIgnored private let authRepository: AuthRepositoryProtocol
    @ObservationIgnored private let appSession: AppSession

    init(
        email: String = "",
        password: String = "",
        authRepository: AuthRepositoryProtocol,
        appSession: AppSession
    ) {
        self.email = email
        self.password = password
        self.authRepository = authRepository
        self.appSession = appSession
    }

    convenience init(appSession: AppSession) {
        self.init(authRepository: AuthRepository(), appSession: appSession)
    }

    @MainActor
    func login() async {
        errorMessage = nil

        guard !email.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty,
              !password.isEmpty else {
            errorMessage = "Enter your email and password."
            return
        }

        isSubmitting = true
        defer { isSubmitting = false }

        do {
            _ = try await authRepository.login(email: email, password: password)
            appSession.markAuthenticated()
        } catch let error as NetworkError {
            errorMessage = error.userMessage
        } catch {
            errorMessage = NetworkError.unknown(error.localizedDescription).userMessage
        }
    }
}
