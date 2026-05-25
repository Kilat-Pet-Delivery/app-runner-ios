import SwiftUI
import KilatUI

struct CancelActiveDeliverySheet: View {
    @Bindable var viewModel: CancelActiveViewModel
    let onClose: () -> Void
    let onSOS: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: Tokens.Space.lg) {
            Capsule()
                .fill(Tokens.Color.separator)
                .frame(width: 44, height: 5)
                .frame(maxWidth: .infinity)

            warningHeader

            VStack(alignment: .leading, spacing: Tokens.Space.sm) {
                ForEach(CancelActiveReason.allCases) { reason in
                    Button {
                        viewModel.selectedReason = reason
                    } label: {
                        HStack {
                            Text(reason.label)
                                .font(Tokens.FontRole.bodyBold)
                            Spacer()
                            if viewModel.selectedReason == reason {
                                Image(systemName: "checkmark.circle.fill")
                            }
                        }
                        .foregroundStyle(viewModel.selectedReason == reason ? Tokens.Color.primary : Tokens.Color.textPrimary)
                        .padding(Tokens.Space.sm)
                        .background(Tokens.Color.surfaceMuted, in: RoundedRectangle(cornerRadius: Tokens.Radius.sm, style: .continuous))
                    }
                    .buttonStyle(.plain)
                }
            }

            TextField("Add a note", text: $viewModel.notes, axis: .vertical)
                .font(Tokens.FontRole.body)
                .padding(Tokens.Space.sm)
                .background(Tokens.Color.surfaceMuted, in: RoundedRectangle(cornerRadius: Tokens.Radius.sm, style: .continuous))

            if let errorMessage = viewModel.errorMessage {
                Text(errorMessage)
                    .font(Tokens.FontRole.caption)
                    .foregroundStyle(Tokens.Color.destructive)
            }

            PrimaryButton(
                title: "Submit cancellation",
                icon: "xmark.circle.fill",
                isLoading: viewModel.isSubmitting,
                action: submit
            )
            SecondaryButton(title: "Keep delivery", icon: "arrow.uturn.left", action: onClose)
        }
        .padding(Tokens.Space.lg)
        .background(Tokens.Color.surface)
        .onChange(of: viewModel.route) { _, route in
            if route == .sos {
                onSOS()
            }
        }
        .onChange(of: viewModel.didSubmit) { _, didSubmit in
            if didSubmit {
                onClose()
            }
        }
    }

    private var warningHeader: some View {
        HStack(alignment: .top, spacing: Tokens.Space.sm) {
            Image(systemName: "exclamationmark.triangle.fill")
                .foregroundStyle(Tokens.Color.destructive)
            VStack(alignment: .leading, spacing: Tokens.Space.xxs) {
                Text("Cancel active delivery")
                    .font(Tokens.FontRole.titleM)
                    .foregroundStyle(Tokens.Color.textPrimary)
                Text("Cancelling after pickup can affect your rating. Use SOS for pet or safety emergencies.")
                    .font(Tokens.FontRole.caption)
                    .foregroundStyle(Tokens.Color.textSecondary)
            }
        }
    }

    private func submit() {
        Task { await viewModel.submit() }
    }
}
