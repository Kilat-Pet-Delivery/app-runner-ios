import SwiftUI
import KilatUI

struct CashOutSentView: View {
    @Environment(\.dismiss) private var dismiss
    static let usesGreenAccent = true
    let details: CashOutSentDetails

    var body: some View {
        ScrollView {
            VStack(spacing: Tokens.Space.lg) {
                header
                etaBar
                transactionCard
                links
                PrimaryButton(title: "Back to earnings", icon: "arrow.left") {
                    dismiss()
                }
            }
            .padding(Tokens.Space.lg)
        }
        .background(Tokens.Color.background.ignoresSafeArea())
        .navigationTitle("Cash out sent")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button { dismiss() } label: {
                    Image(systemName: "xmark")
                        .foregroundStyle(Tokens.Color.textPrimary)
                }
            }
        }
    }

    private var header: some View {
        VStack(spacing: Tokens.Space.md) {
            Image(kilatAsset: "check")
                .resizable()
                .renderingMode(.template)
                .frame(width: 58, height: 58)
                .foregroundStyle(Tokens.Color.online)
            Text("CASH OUT SENT")
                .font(Tokens.FontRole.caption)
                .foregroundStyle(Tokens.Color.online)
            Text(formatRM(details.amountCents))
                .font(Tokens.FontRole.displayXL)
                .foregroundStyle(Tokens.Color.textPrimary)
            Text("to \(details.destinationLabel)")
                .font(Tokens.FontRole.label)
                .foregroundStyle(Tokens.Color.textSecondary)
        }
        .frame(maxWidth: .infinity)
    }

    private var etaBar: some View {
        Text("Arriving by \(arrivalTime) - ~\(details.etaMinutes) min - DuitNow")
            .font(Tokens.FontRole.label)
            .foregroundStyle(Tokens.Color.online)
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(Tokens.Space.md)
            .background(Tokens.Color.onlineTonal, in: RoundedRectangle(cornerRadius: Tokens.Radius.md))
    }

    private var transactionCard: some View {
        VStack(spacing: Tokens.Space.sm) {
            row("Transaction ID", details.cashOutID, mono: true)
            row("Timestamp", details.requestedAt.formatted(date: .abbreviated, time: .shortened))
            row("Bank", details.destinationLabel)
            row("Reference", "DuitNow instant")
        }
        .padding(Tokens.Space.md)
        .background(Tokens.Color.surface, in: RoundedRectangle(cornerRadius: Tokens.Radius.md))
        .accessibilityIdentifier("cashOutTransactionCard")
    }

    private var links: some View {
        HStack(spacing: Tokens.Space.xl) {
            Button("Get receipt") {}
            Button("Share to WhatsApp") {}
        }
        .font(Tokens.FontRole.label)
        .foregroundStyle(Tokens.Color.primary)
    }

    private func row(_ label: String, _ value: String, mono: Bool = false) -> some View {
        HStack {
            Text(label)
                .foregroundStyle(Tokens.Color.textSecondary)
            Spacer()
            Text(value)
                .font(mono ? Tokens.FontRole.mono : Tokens.FontRole.label)
                .foregroundStyle(Tokens.Color.textPrimary)
                .multilineTextAlignment(.trailing)
        }
        .font(Tokens.FontRole.label)
    }

    private var arrivalTime: String {
        details.requestedAt.addingTimeInterval(TimeInterval(details.etaMinutes * 60)).formatted(date: .omitted, time: .shortened)
    }

    private func formatRM(_ cents: Int64) -> String {
        "RM \(String(format: "%.2f", Double(cents) / 100))"
    }
}
