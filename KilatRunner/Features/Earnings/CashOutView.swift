import SwiftUI
import KilatUI

struct CashOutView: View {
    @Environment(\.dismiss) private var dismiss
    @Bindable private var viewModel: CashOutViewModel

    init(viewModel: CashOutViewModel) {
        self.viewModel = viewModel
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: Tokens.Space.lg) {
                amountHero
                quickAmounts
                destinationCard
                feeBreakdown
                infoNote
                if let errorMessage = viewModel.errorMessage {
                    Text(errorMessage)
                        .font(Tokens.FontRole.caption)
                        .foregroundStyle(Tokens.Color.destructive)
                }
                PrimaryButton(
                    title: "Cash out \(formatRM(viewModel.amountCents))",
                    icon: "banknote.fill",
                    isLoading: viewModel.isSubmitting,
                    isEnabled: viewModel.isSubmitEnabled,
                    action: { Task { await viewModel.submit() } }
                )
                Button("Cancel") { dismiss() }
                    .font(Tokens.FontRole.label)
                    .foregroundStyle(Tokens.Color.textSecondary)
                    .frame(maxWidth: .infinity)
            }
            .padding(Tokens.Space.lg)
        }
        .background(Tokens.Color.background.ignoresSafeArea())
        .navigationTitle("Cash out")
        .navigationBarTitleDisplayMode(.inline)
        .navigationDestination(
            isPresented: Binding(
                get: { viewModel.sentDetails != nil },
                set: { newValue in if !newValue { viewModel.sentDetails = nil } }
            )
        ) {
            if let details = viewModel.sentDetails {
                CashOutSentView(details: details)
            }
        }
    }

    private var amountHero: some View {
        VStack(alignment: .leading, spacing: Tokens.Space.md) {
            Text(formatRM(viewModel.amountCents))
                .font(Tokens.FontRole.displayXL)
                .foregroundStyle(Tokens.Color.textPrimary)
            Text("of \(formatRM(viewModel.availableAmountCents)) available")
                .font(Tokens.FontRole.label)
                .foregroundStyle(Tokens.Color.textSecondary)
            ProgressView(value: viewModel.progress)
                .tint(Tokens.Color.primary)
        }
        .padding(Tokens.Space.lg)
        .background(Tokens.Color.surface, in: RoundedRectangle(cornerRadius: Tokens.Radius.lg))
        .tokenShadow(Tokens.Shadow.card)
    }

    private var quickAmounts: some View {
        HStack(spacing: Tokens.Space.xs) {
            quickAmountButton("Max", .max)
            quickAmountButton("RM 500", .fixed(50_000))
            quickAmountButton("RM 250", .fixed(25_000))
            quickAmountButton("RM 100", .fixed(10_000))
        }
    }

    private func quickAmountButton(_ title: String, _ quickAmount: CashOutQuickAmount) -> some View {
        let selected = viewModel.selectedQuickAmount == quickAmount
        return Button {
            viewModel.selectQuickAmount(quickAmount)
        } label: {
            Text(title)
                .font(Tokens.FontRole.caption)
                .foregroundStyle(selected ? Tokens.Color.onPrimary : Tokens.Color.textPrimary)
                .frame(maxWidth: .infinity)
                .padding(.vertical, Tokens.Space.sm)
                .background(selected ? Tokens.Color.primary : Tokens.Color.surface, in: RoundedRectangle(cornerRadius: Tokens.Radius.sm))
        }
    }

    private var destinationCard: some View {
        HStack(spacing: Tokens.Space.md) {
            Image(kilatAsset: "card")
                .resizable()
                .renderingMode(.template)
                .frame(width: 28, height: 28)
                .foregroundStyle(Tokens.Color.primary)
            VStack(alignment: .leading, spacing: 2) {
                Text("Maybank Wallet")
                    .font(Tokens.FontRole.bodyBold)
                    .foregroundStyle(Tokens.Color.textPrimary)
                Text("•••• 4521")
                    .font(Tokens.FontRole.caption)
                    .foregroundStyle(Tokens.Color.textSecondary)
            }
            Spacer()
            Text("DEFAULT")
                .font(Tokens.FontRole.caption)
                .foregroundStyle(Tokens.Color.onPrimaryTonal)
                .padding(.horizontal, Tokens.Space.xs)
                .padding(.vertical, Tokens.Space.xxs)
                .background(Tokens.Color.primaryTonal, in: Capsule())
        }
        .padding(Tokens.Space.md)
        .background(Tokens.Color.surface, in: RoundedRectangle(cornerRadius: Tokens.Radius.md))
    }

    private var feeBreakdown: some View {
        VStack(spacing: Tokens.Space.xs) {
            row("Amount", formatRM(viewModel.amountCents))
            row("Instant fee", "-\(formatRM(viewModel.feeCents))")
            Divider().background(Tokens.Color.separator)
            row("You will receive", formatRM(viewModel.receiveAmountCents), bold: true)
        }
        .padding(Tokens.Space.md)
        .background(Tokens.Color.surface, in: RoundedRectangle(cornerRadius: Tokens.Radius.md))
    }

    private var infoNote: some View {
        VStack(alignment: .leading, spacing: Tokens.Space.xs) {
            Label("Arrives in ~30 min - DuitNow instant", systemImage: "clock.fill")
            Text("Friday auto-payout will continue as usual.")
        }
        .font(Tokens.FontRole.label)
        .foregroundStyle(Tokens.Color.textSecondary)
        .padding(Tokens.Space.md)
        .background(Tokens.Color.surfaceMuted, in: RoundedRectangle(cornerRadius: Tokens.Radius.md))
    }

    private func row(_ label: String, _ value: String, bold: Bool = false) -> some View {
        HStack {
            Text(label)
            Spacer()
            Text(value)
        }
        .font(bold ? Tokens.FontRole.bodyBold : Tokens.FontRole.label)
        .foregroundStyle(bold ? Tokens.Color.textPrimary : Tokens.Color.textSecondary)
    }

    private func formatRM(_ cents: Int64) -> String {
        "RM \(String(format: "%.2f", Double(cents) / 100))"
    }
}
