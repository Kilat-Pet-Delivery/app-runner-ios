import SwiftUI
import KilatUI

struct BankAccountsView: View {
    @Bindable private var viewModel: BankAccountsViewModel
    @State private var showsAddSheet = false

    init(viewModel: BankAccountsViewModel) {
        self.viewModel = viewModel
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: Tokens.Space.md) {
                if viewModel.isLoading && viewModel.accounts.isEmpty {
                    ProgressView()
                        .tint(Tokens.Color.primary)
                        .frame(maxWidth: .infinity)
                        .padding(Tokens.Space.xl)
                } else {
                    ForEach(viewModel.accounts) { account in
                        accountCard(account)
                    }
                    addSlot
                    payoutFooter
                }

                if let errorMessage = viewModel.errorMessage {
                    Text(errorMessage)
                        .font(Tokens.FontRole.caption)
                        .foregroundStyle(Tokens.Color.destructive)
                }
            }
            .padding(Tokens.Space.md)
        }
        .background(Tokens.Color.background.ignoresSafeArea())
        .navigationTitle("Bank accounts")
        .navigationBarTitleDisplayMode(.inline)
        .task {
            if viewModel.accounts.isEmpty {
                await viewModel.load()
            }
        }
        .sheet(isPresented: $showsAddSheet) {
            AddBankAccountSheet(viewModel: viewModel)
        }
    }

    private func accountCard(_ account: BankAccount) -> some View {
        VStack(alignment: .leading, spacing: Tokens.Space.md) {
            HStack(alignment: .top, spacing: Tokens.Space.md) {
                Image(kilatAsset: "card")
                    .resizable()
                    .renderingMode(.template)
                    .frame(width: 28, height: 28)
                    .foregroundStyle(Tokens.Color.primary)

                VStack(alignment: .leading, spacing: Tokens.Space.xxs) {
                    HStack(spacing: Tokens.Space.xs) {
                        Text(account.bankName)
                            .font(Tokens.FontRole.bodyBold)
                            .foregroundStyle(Tokens.Color.textPrimary)
                        if account.isDefault {
                            Text("DEFAULT")
                                .font(Tokens.FontRole.caption)
                                .foregroundStyle(Tokens.Color.onPrimaryTonal)
                                .padding(.horizontal, Tokens.Space.xs)
                                .padding(.vertical, 2)
                                .background(Tokens.Color.primaryTonal, in: Capsule())
                        }
                    }
                    Text(account.maskedNumber)
                        .font(Tokens.FontRole.label)
                        .foregroundStyle(Tokens.Color.textSecondary)
                    Text(account.holderName)
                        .font(Tokens.FontRole.caption)
                        .foregroundStyle(Tokens.Color.textSecondary)
                }
                Spacer()
            }

            HStack {
                if !account.isDefault {
                    Button("Set default") {
                        Task { await viewModel.setDefault(id: account.id) }
                    }
                    .font(Tokens.FontRole.label)
                    .foregroundStyle(Tokens.Color.primary)
                }
                Spacer()
                Button("Delete", role: .destructive) {
                    Task { await viewModel.delete(id: account.id) }
                }
                .font(Tokens.FontRole.label)
            }
        }
        .padding(Tokens.Space.md)
        .background(Tokens.Color.surface, in: RoundedRectangle(cornerRadius: Tokens.Radius.md, style: .continuous))
    }

    private var addSlot: some View {
        Button {
            showsAddSheet = true
        } label: {
            HStack {
                Image(systemName: "plus.circle.fill")
                Text("Add bank account")
                Spacer()
            }
            .font(Tokens.FontRole.label)
            .foregroundStyle(Tokens.Color.primary)
            .padding(Tokens.Space.lg)
            .overlay(
                RoundedRectangle(cornerRadius: Tokens.Radius.md, style: .continuous)
                    .stroke(style: StrokeStyle(lineWidth: 1.5, dash: [7, 5]))
                    .foregroundStyle(Tokens.Color.primary.opacity(0.45))
            )
        }
    }

    private var payoutFooter: some View {
        Label("Auto-payout every Friday", systemImage: "calendar.badge.clock")
            .font(Tokens.FontRole.label)
            .foregroundStyle(Tokens.Color.textSecondary)
            .padding(Tokens.Space.md)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(Tokens.Color.surfaceMuted, in: RoundedRectangle(cornerRadius: Tokens.Radius.md, style: .continuous))
    }
}
