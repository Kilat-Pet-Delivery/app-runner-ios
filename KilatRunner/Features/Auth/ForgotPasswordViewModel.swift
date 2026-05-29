import Foundation
import Observation

@Observable
final class ForgotPasswordViewModel {
    var email: String
    private(set) var isSubmitting = false
    var errorMessage: String?
    var didSendResetLink = false

    var canSubmit: Bool {
        email.trimmingCharacters(in: .whitespacesAndNewlines).contains("@") && !isSubmitting
    }

    @ObservationIgnored private let repository: PasswordResetRepositoryProtocol

    init(email: String = "", repository: PasswordResetRepositoryProtocol = PasswordResetRepository()) {
        self.email = email
        self.repository = repository
    }

    @MainActor
    func submit() async {
        errorMessage = nil
        let trimmedEmail = email.trimmingCharacters(in: .whitespacesAndNewlines)

        guard trimmedEmail.contains("@") else {
            errorMessage = "Enter a valid email address."
            return
        }

        isSubmitting = true
        defer { isSubmitting = false }

        do {
            try await repository.forgotPassword(email: trimmedEmail)
            email = trimmedEmail
            didSendResetLink = true
        } catch let error as NetworkError {
            errorMessage = error.userMessage
        } catch {
            errorMessage = NetworkError.unknown(error.localizedDescription).userMessage
        }
    }
}
