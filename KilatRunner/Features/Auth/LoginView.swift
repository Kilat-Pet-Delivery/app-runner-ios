import SwiftUI

struct LoginView: View {
    @Bindable private var viewModel: LoginViewModel

    init(viewModel: LoginViewModel) {
        self.viewModel = viewModel
    }

    var body: some View {
        NavigationStack {
            VStack(spacing: 28) {
                Spacer()

                VStack(spacing: 10) {
                    Image(systemName: "bolt.car.fill")
                        .font(.system(size: 52, weight: .semibold))
                        .foregroundStyle(.blue)

                    Text("Kilat Runner")
                        .font(.largeTitle.bold())

                    Text("Sign in to manage deliveries")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }

                VStack(spacing: 14) {
                    TextField("Email", text: $viewModel.email)
                        .textContentType(.username)
                        .keyboardType(.emailAddress)
                        .textInputAutocapitalization(.never)
                        .autocorrectionDisabled()
                        .submitLabel(.next)
                        .padding()
                        .background(.thinMaterial, in: RoundedRectangle(cornerRadius: 8))

                    SecureField("Password", text: $viewModel.password)
                        .textContentType(.password)
                        .submitLabel(.go)
                        .padding()
                        .background(.thinMaterial, in: RoundedRectangle(cornerRadius: 8))
                        .onSubmit {
                            Task { await viewModel.login() }
                        }

                    if let errorMessage = viewModel.errorMessage {
                        Text(errorMessage)
                            .font(.footnote)
                            .foregroundStyle(.red)
                            .frame(maxWidth: .infinity, alignment: .leading)
                    }

                    Button {
                        Task { await viewModel.login() }
                    } label: {
                        HStack {
                            if viewModel.isSubmitting {
                                ProgressView()
                                    .tint(.white)
                            }
                            Text(viewModel.isSubmitting ? "Signing In" : "Sign In")
                                .fontWeight(.semibold)
                        }
                        .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(.borderedProminent)
                    .controlSize(.large)
                    .disabled(viewModel.isSubmitting)
                }

                Spacer()
            }
            .padding(24)
            .navigationBarTitleDisplayMode(.inline)
        }
    }
}

#Preview {
    LoginView(viewModel: LoginViewModel(appSession: AppSession()))
}
