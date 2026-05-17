import SwiftUI
import KilatUI

struct LoginView: View {
    @Bindable private var viewModel: LoginViewModel

    init(viewModel: LoginViewModel) {
        self.viewModel = viewModel
    }

    var body: some View {
        NavigationStack {
            VStack(spacing: Tokens.Space.xl) {
                Spacer()

                logoSection

                formSection

                inlineLinks

                Spacer()
            }
            .padding(.horizontal, Tokens.Space.xl)
            .padding(.vertical, Tokens.Space.lg)
            .background(Tokens.Color.background.ignoresSafeArea())
            .navigationBarTitleDisplayMode(.inline)
        }
    }

    private var logoSection: some View {
        VStack(spacing: Tokens.Space.sm) {
            Image(kilatAsset: "Logo-StampPaw")
                .resizable()
                .renderingMode(.template)
                .aspectRatio(contentMode: .fit)
                .frame(width: 96, height: 96)
                .foregroundStyle(Tokens.Color.primary)
                .accessibilityIdentifier("loginLogo")

            Text("Kilat Runner")
                .font(Tokens.FontRole.displayL)
                .foregroundStyle(Tokens.Color.textPrimary)

            Text("Sign in to manage deliveries")
                .font(Tokens.FontRole.label)
                .foregroundStyle(Tokens.Color.textSecondary)
        }
    }

    private var formSection: some View {
        VStack(spacing: Tokens.Space.md) {
            TextField("Email", text: $viewModel.email)
                .textContentType(.username)
                .keyboardType(.emailAddress)
                .textInputAutocapitalization(.never)
                .autocorrectionDisabled()
                .submitLabel(.next)
                .padding(Tokens.Space.md)
                .background(Tokens.Color.surface, in: RoundedRectangle(cornerRadius: Tokens.Radius.md))

            SecureField("Password", text: $viewModel.password)
                .textContentType(.password)
                .submitLabel(.go)
                .padding(Tokens.Space.md)
                .background(Tokens.Color.surface, in: RoundedRectangle(cornerRadius: Tokens.Radius.md))
                .onSubmit { Task { await viewModel.login() } }

            if let errorMessage = viewModel.errorMessage {
                Text(errorMessage)
                    .font(Tokens.FontRole.caption)
                    .foregroundStyle(Tokens.Color.destructive)
                    .frame(maxWidth: .infinity, alignment: .leading)
            }

            PrimaryButton(
                title: viewModel.isSubmitting ? "Signing in" : "Sign in",
                isLoading: viewModel.isSubmitting,
                isEnabled: viewModel.isFormValid,
                action: { Task { await viewModel.login() } }
            )
        }
    }

    private var inlineLinks: some View {
        HStack(spacing: Tokens.Space.xl) {
            // TODO(phase-9): wire to ForgotPasswordView (catalog 3.5)
            Button("Forgot password?") {}
                .font(Tokens.FontRole.label)
                .foregroundStyle(Tokens.Color.primary)

            // TODO(phase-9): wire to ApplyView (catalog 3.5)
            Button("Apply to join") {}
                .font(Tokens.FontRole.label)
                .foregroundStyle(Tokens.Color.primary)
        }
    }
}

#Preview("Login (light)") {
    LoginView(viewModel: LoginViewModel(appSession: AppSession()))
        .preferredColorScheme(.light)
}

#Preview("Login (dark)") {
    LoginView(viewModel: LoginViewModel(appSession: AppSession()))
        .preferredColorScheme(.dark)
}
