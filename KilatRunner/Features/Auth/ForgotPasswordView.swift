import SwiftUI
import KilatUI

struct ForgotPasswordView: View {
    @Bindable private var viewModel: ForgotPasswordViewModel

    init(viewModel: ForgotPasswordViewModel) {
        self.viewModel = viewModel
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: Tokens.Space.xl) {
                header
                form
            }
            .padding(Tokens.Space.xl)
        }
        .background(Tokens.Color.background.ignoresSafeArea())
        .navigationTitle("Forgot password")
        .navigationBarTitleDisplayMode(.inline)
        .navigationDestination(isPresented: $viewModel.didSendResetLink) {
            ResetSentView(email: viewModel.email)
        }
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: Tokens.Space.sm) {
            Image(kilatAsset: "Logo-StampPaw")
                .resizable()
                .renderingMode(.template)
                .frame(width: 72, height: 72)
                .foregroundStyle(Tokens.Color.primary)

            Text("Reset your password")
                .font(Tokens.FontRole.titleL)
                .foregroundStyle(Tokens.Color.textPrimary)

            Text("Enter the email you use for Kilat Runner. We will send a reset link that expires in 1 hour.")
                .font(Tokens.FontRole.label)
                .foregroundStyle(Tokens.Color.textSecondary)
                .fixedSize(horizontal: false, vertical: true)
        }
    }

    private var form: some View {
        VStack(alignment: .leading, spacing: Tokens.Space.md) {
            TextField("Email", text: $viewModel.email)
                .textContentType(.username)
                .keyboardType(.emailAddress)
                .textInputAutocapitalization(.never)
                .autocorrectionDisabled()
                .submitLabel(.send)
                .padding(Tokens.Space.md)
                .background(Tokens.Color.surface, in: RoundedRectangle(cornerRadius: Tokens.Radius.md))
                .onSubmit { Task { await viewModel.submit() } }

            if let errorMessage = viewModel.errorMessage {
                Text(errorMessage)
                    .font(Tokens.FontRole.caption)
                    .foregroundStyle(Tokens.Color.destructive)
            }

            PrimaryButton(
                title: viewModel.isSubmitting ? "Sending link" : "Send reset link",
                icon: "envelope.fill",
                isLoading: viewModel.isSubmitting,
                isEnabled: viewModel.canSubmit,
                action: { Task { await viewModel.submit() } }
            )
        }
    }
}
