import SwiftUI
import KilatUI

struct EarningsView: View {
    @Bindable private var viewModel: EarningsViewModel

    init(viewModel: EarningsViewModel) {
        self.viewModel = viewModel
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: Tokens.Space.md) {
                heroMetric
                periodControl
                chartPlaceholder
                breakdownCard
                recentDeliveriesCard
                payoutCard

                if let errorMessage = viewModel.errorMessage, viewModel.earnings.isEmpty {
                    errorBanner(message: errorMessage)
                }
            }
            .padding(Tokens.Space.md)
        }
        .background(Tokens.Color.background.ignoresSafeArea())
        .navigationTitle("Earnings")
        .navigationBarTitleDisplayMode(.inline)
        .refreshable { await viewModel.loadFirstPage() }
        .task {
            if viewModel.earnings.isEmpty {
                await viewModel.loadFirstPage()
            }
        }
    }

    private var heroMetric: some View {
        MetricTile(
            label: viewModel.selectedPeriod.label,
            value: formatAmount(viewModel.periodTotalCents),
            caption: "Across \(viewModel.earnings.count) trip\(viewModel.earnings.count == 1 ? "" : "s")",
            variant: .emphasis
        )
        .accessibilityIdentifier("earningsHeroMetric")
    }

    private var periodControl: some View {
        HStack(spacing: Tokens.Space.xs) {
            ForEach(EarningsPeriod.allCases) { period in
                periodPill(period)
            }
        }
    }

    private func periodPill(_ period: EarningsPeriod) -> some View {
        let isSelected = viewModel.selectedPeriod == period
        return Button { viewModel.selectedPeriod = period } label: {
            Text(period.label)
                .font(Tokens.FontRole.label)
                .padding(.horizontal, Tokens.Space.md)
                .padding(.vertical, Tokens.Space.xs)
                .foregroundStyle(isSelected ? Tokens.Color.onPrimary : Tokens.Color.textPrimary)
                .background(Capsule().fill(isSelected ? Tokens.Color.primary : Tokens.Color.surface))
        }
        .accessibilityIdentifier("earningsPeriodPill_\(period.rawValue)")
    }

    private var chartPlaceholder: some View {
        // Phase 8: striped block stand-in. Real bar chart deferred to a
        // follow-up plan per spec §15 backlog.
        GeometryReader { geo in
            let stripeWidth: CGFloat = 14
            let count = Int(geo.size.width / stripeWidth) + 1
            HStack(spacing: 0) {
                ForEach(0..<count, id: \.self) { i in
                    Rectangle()
                        .fill(i.isMultiple(of: 2) ? Tokens.Color.surfaceMuted : Tokens.Color.surface)
                        .frame(width: stripeWidth)
                }
            }
        }
        .frame(height: 140)
        .clipShape(RoundedRectangle(cornerRadius: Tokens.Radius.md, style: .continuous))
        .overlay(
            Text("Chart coming soon")
                .font(Tokens.FontRole.caption)
                .foregroundStyle(Tokens.Color.textSecondary)
        )
        .accessibilityIdentifier("earningsChartPlaceholder")
    }

    private var breakdownCard: some View {
        VStack(spacing: Tokens.Space.xs) {
            breakdownRow(label: "Base fares", amount: viewModel.periodTotalCents * 75 / 100)
            breakdownRow(label: "Tips", amount: viewModel.periodTotalCents * 15 / 100)
            breakdownRow(label: "Bonus", amount: viewModel.periodTotalCents * 10 / 100)
        }
        .padding(Tokens.Space.md)
        .background(Tokens.Color.surface, in: RoundedRectangle(cornerRadius: Tokens.Radius.md, style: .continuous))
    }

    private func breakdownRow(label: String, amount: Int) -> some View {
        HStack {
            Text(label)
                .font(Tokens.FontRole.label)
                .foregroundStyle(Tokens.Color.textSecondary)
            Spacer()
            Text(formatAmount(amount))
                .font(Tokens.FontRole.label)
                .foregroundStyle(Tokens.Color.textPrimary)
        }
    }

    private var recentDeliveriesCard: some View {
        VStack(alignment: .leading, spacing: Tokens.Space.sm) {
            HStack {
                Text("Recent deliveries")
                    .font(Tokens.FontRole.titleM)
                    .foregroundStyle(Tokens.Color.textPrimary)
                Spacer()
                Text("\(viewModel.earnings.count)")
                    .font(Tokens.FontRole.caption)
                    .foregroundStyle(Tokens.Color.textSecondary)
            }
            if viewModel.earnings.isEmpty {
                Text("Completed trips will appear here.")
                    .font(Tokens.FontRole.label)
                    .foregroundStyle(Tokens.Color.textSecondary)
                    .padding(.vertical, Tokens.Space.sm)
            } else {
                ForEach(viewModel.earnings.prefix(5)) { earning in
                    earningRow(earning)
                        .onAppear {
                            if earning.id == viewModel.earnings.last?.id {
                                Task { await viewModel.loadNextPage() }
                            }
                        }
                }
            }
        }
        .padding(Tokens.Space.md)
        .background(Tokens.Color.surface, in: RoundedRectangle(cornerRadius: Tokens.Radius.md, style: .continuous))
    }

    private func earningRow(_ earning: Earning) -> some View {
        HStack(alignment: .top, spacing: Tokens.Space.sm) {
            Image(kilatAsset: "wallet")
                .resizable()
                .renderingMode(.template)
                .frame(width: 20, height: 20)
                .foregroundStyle(Tokens.Color.online)
            VStack(alignment: .leading, spacing: 2) {
                Text("Booking \(String(earning.bookingId.prefix(8)))")
                    .font(Tokens.FontRole.label)
                    .foregroundStyle(Tokens.Color.textPrimary)
                Text(earning.completedAt.formatted(date: .abbreviated, time: .shortened))
                    .font(Tokens.FontRole.caption)
                    .foregroundStyle(Tokens.Color.textSecondary)
            }
            Spacer()
            Text("\(earning.currency) \(String(format: "%.2f", Double(earning.amountCents) / 100))")
                .font(Tokens.FontRole.bodyBold)
                .foregroundStyle(Tokens.Color.textPrimary)
        }
        .padding(.vertical, Tokens.Space.xxs)
    }

    private var payoutCard: some View {
        VStack(alignment: .leading, spacing: Tokens.Space.sm) {
            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    Text("Next payout")
                        .font(Tokens.FontRole.caption)
                        .foregroundStyle(Tokens.Color.textSecondary)
                        .textCase(.uppercase)
                    Text(formatAmount(viewModel.nextPayoutCents))
                        .font(Tokens.FontRole.titleL)
                        .foregroundStyle(Tokens.Color.textPrimary)
                }
                Spacer()
            }
            NavigationLink {
                CashOutView(
                    viewModel: CashOutViewModel(
                        availableAmountCents: Int64(max(viewModel.nextPayoutCents, viewModel.periodTotalCents))
                    )
                )
            } label: {
                Text("Cash out now")
                    .font(Tokens.FontRole.button)
                    .foregroundStyle(Tokens.Color.onPrimary)
                    .frame(maxWidth: .infinity)
                    .frame(height: Tokens.Hit.button)
                    .background(Tokens.Color.primary, in: RoundedRectangle(cornerRadius: Tokens.Radius.md, style: .continuous))
            }
        }
        .padding(Tokens.Space.md)
        .background(Tokens.Color.primaryTonal, in: RoundedRectangle(cornerRadius: Tokens.Radius.lg, style: .continuous))
    }

    private func errorBanner(message: String) -> some View {
        HStack(alignment: .top, spacing: Tokens.Space.xs) {
            Image(kilatAsset: "alert")
                .resizable()
                .renderingMode(.template)
                .frame(width: 18, height: 18)
                .foregroundStyle(Tokens.Color.destructive)
            Text(message)
                .font(Tokens.FontRole.label)
                .foregroundStyle(Tokens.Color.textPrimary)
        }
        .padding(Tokens.Space.md)
        .background(Tokens.Color.surface, in: RoundedRectangle(cornerRadius: Tokens.Radius.md, style: .continuous))
    }

    private func formatAmount(_ cents: Int) -> String {
        "\(viewModel.currency) \(String(format: "%.2f", Double(cents) / 100))"
    }
}

#Preview {
    NavigationStack {
        EarningsView(viewModel: {
            let vm = EarningsViewModel()
            vm.todayEarningsCents = 8_450
            vm.nextPayoutCents = 23_400
            return vm
        }())
    }
}
