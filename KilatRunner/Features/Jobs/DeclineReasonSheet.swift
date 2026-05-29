import SwiftUI
import KilatUI

struct DeclineReasonSheet: View {
    @Bindable private var viewModel: DeclineReasonViewModel
    let onDismissAfterSubmit: () -> Void

    init(viewModel: DeclineReasonViewModel, onDismissAfterSubmit: @escaping () -> Void) {
        self.viewModel = viewModel
        self.onDismissAfterSubmit = onDismissAfterSubmit
    }

    var body: some View {
        VStack(alignment: .leading, spacing: Tokens.Space.lg) {
            Capsule()
                .fill(Tokens.Color.separator)
                .frame(width: 42, height: 5)
                .frame(maxWidth: .infinity)

            VStack(alignment: .leading, spacing: Tokens.Space.xs) {
                Text("Why are you declining?")
                    .font(Tokens.FontRole.titleL)
                    .foregroundStyle(Tokens.Color.textPrimary)
                Text("This helps dispatch offer better jobs next time.")
                    .font(Tokens.FontRole.label)
                    .foregroundStyle(Tokens.Color.textSecondary)
            }

            VStack(spacing: Tokens.Space.sm) {
                ForEach(DeclineReason.allCases) { reason in
                    Button {
                        Task { await viewModel.select(reason) }
                    } label: {
                        HStack {
                            Text(reason.label)
                                .font(Tokens.FontRole.label)
                            Spacer()
                            if viewModel.selectedReason == reason && viewModel.isSubmitting {
                                ProgressView()
                            } else {
                                Image(systemName: "chevron.right")
                            }
                        }
                        .foregroundStyle(Tokens.Color.textPrimary)
                        .padding(Tokens.Space.md)
                        .background(Tokens.Color.surfaceMuted, in: RoundedRectangle(cornerRadius: Tokens.Radius.md))
                    }
                    .disabled(viewModel.isSubmitting)
                }
            }

            if let errorMessage = viewModel.errorMessage {
                Text(errorMessage)
                    .font(Tokens.FontRole.caption)
                    .foregroundStyle(Tokens.Color.destructive)
            }

            Button("Skip") {
                Task { await viewModel.skip() }
            }
            .font(Tokens.FontRole.label)
            .foregroundStyle(Tokens.Color.primary)
            .frame(maxWidth: .infinity)
            .disabled(viewModel.isSubmitting)
        }
        .padding(Tokens.Space.xl)
        .background(Tokens.Color.surface)
        .presentationDetents([.medium])
        .onChange(of: viewModel.didDismiss) { _, didDismiss in
            if didDismiss {
                onDismissAfterSubmit()
            }
        }
    }
}
