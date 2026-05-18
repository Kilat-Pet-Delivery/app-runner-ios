import SwiftUI
import UIKit
import KilatUI

struct ResetSentView: View {
    @Environment(\.dismiss) private var dismiss
    let email: String
    private let repository: PasswordResetRepositoryProtocol
    private let openURLAction: (URL) -> Void

    @State private var isResending = false
    @State private var resendMessage: String?
    @State private var errorMessage: String?

    init(
        email: String,
        repository: PasswordResetRepositoryProtocol = PasswordResetRepository(),
        openURLAction: @escaping (URL) -> Void = { UIApplication.shared.open($0) }
    ) {
        self.email = email
        self.repository = repository
        self.openURLAction = openURLAction
    }

    var body: some View {
        VStack(spacing: Tokens.Space.xl) {
            Spacer()
            Image(systemName: "envelope.badge.fill")
                .font(.system(size: 64, weight: .semibold))
                .foregroundStyle(Tokens.Color.primary)
                .accessibilityIdentifier("resetSentEnvelopeIcon")

            VStack(spacing: Tokens.Space.xs) {
                Text("Check your email")
                    .font(Tokens.FontRole.titleL)
                    .foregroundStyle(Tokens.Color.textPrimary)
                Text(email)
                    .font(Tokens.FontRole.bodyBold)
                    .foregroundStyle(Tokens.Color.primary)
                Text("Your reset link expires in 1 hour.")
                    .font(Tokens.FontRole.label)
                    .foregroundStyle(Tokens.Color.textSecondary)
            }
            .multilineTextAlignment(.center)

            VStack(spacing: Tokens.Space.md) {
                PrimaryButton(title: "Open mail app", icon: "envelope.open.fill") {
                    openMailApp()
                }

                Button(isResending ? "Resending..." : "Resend link") {
                    Task { await resend() }
                }
                .font(Tokens.FontRole.label)
                .foregroundStyle(Tokens.Color.primary)
                .disabled(isResending)

                Button("Use different email") { dismiss() }
                    .font(Tokens.FontRole.label)
                    .foregroundStyle(Tokens.Color.textSecondary)
            }

            if let resendMessage {
                Text(resendMessage)
                    .font(Tokens.FontRole.caption)
                    .foregroundStyle(Tokens.Color.online)
            }
            if let errorMessage {
                Text(errorMessage)
                    .font(Tokens.FontRole.caption)
                    .foregroundStyle(Tokens.Color.destructive)
            }
            Spacer()
        }
        .padding(Tokens.Space.xl)
        .background(Tokens.Color.background.ignoresSafeArea())
        .navigationBarBackButtonHidden(false)
    }

    func openMailApp() {
        guard let url = URL(string: "message://") else { return }
        openURLAction(url)
    }

    @MainActor
    func resend() async {
        isResending = true
        resendMessage = nil
        errorMessage = nil
        defer { isResending = false }

        do {
            try await repository.forgotPassword(email: email)
            resendMessage = "Reset link sent again."
        } catch let error as NetworkError {
            errorMessage = error.userMessage
        } catch {
            errorMessage = NetworkError.unknown(error.localizedDescription).userMessage
        }
    }
}
