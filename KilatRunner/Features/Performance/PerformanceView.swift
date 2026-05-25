import SwiftUI
import KilatUI

struct PerformanceView: View {
    @Bindable private var viewModel: PerformanceViewModel

    init(viewModel: PerformanceViewModel) {
        self.viewModel = viewModel
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: Tokens.Space.lg) {
                if let state = viewModel.state {
                    hero(state)
                    chart(state)
                    kpis(state)
                    tierProgress(state)
                } else if viewModel.isLoading {
                    ProgressView()
                        .tint(Tokens.Color.primary)
                        .frame(maxWidth: .infinity)
                        .padding(.top, Tokens.Space.xxxl)
                } else if let errorMessage = viewModel.errorMessage {
                    Text(errorMessage)
                        .font(Tokens.FontRole.label)
                        .foregroundStyle(Tokens.Color.destructive)
                }
            }
            .padding(Tokens.Space.lg)
        }
        .background(Tokens.Color.background.ignoresSafeArea())
        .navigationTitle("Performance")
        .navigationBarTitleDisplayMode(.inline)
        .task {
            if viewModel.state == nil {
                await viewModel.load()
            }
        }
    }

    private func hero(_ state: PerformanceDashboardState) -> some View {
        VStack(alignment: .leading, spacing: Tokens.Space.sm) {
            Text("Rating")
                .font(Tokens.FontRole.caption)
                .foregroundStyle(Tokens.Color.textSecondary)
                .textCase(.uppercase)
            HStack(alignment: .firstTextBaseline, spacing: Tokens.Space.xs) {
                Text(state.ratingLabel)
                    .font(Tokens.FontRole.displayXL)
                    .foregroundStyle(Tokens.Color.textPrimary)
                Image(systemName: "star.fill")
                    .foregroundStyle(.yellow)
            }
            Text("\(state.tier.tier.displayName) tier")
                .font(Tokens.FontRole.label)
                .foregroundStyle(Tokens.Color.primary)
        }
        .padding(Tokens.Space.lg)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Tokens.Color.surface, in: RoundedRectangle(cornerRadius: Tokens.Radius.lg, style: .continuous))
        .tokenShadow(Tokens.Shadow.card)
    }

    private func chart(_ state: PerformanceDashboardState) -> some View {
        VStack(alignment: .leading, spacing: Tokens.Space.sm) {
            Text("On-time this week")
                .font(Tokens.FontRole.titleM)
                .foregroundStyle(Tokens.Color.textPrimary)
            BarChart(data: state.weeklyOnTime.map { (label: $0.label, value: $0.value, highlight: $0.highlight) })
        }
        .padding(Tokens.Space.md)
        .background(Tokens.Color.surface, in: RoundedRectangle(cornerRadius: Tokens.Radius.lg, style: .continuous))
    }

    private func kpis(_ state: PerformanceDashboardState) -> some View {
        LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: Tokens.Space.sm) {
            MetricTile(label: "Acceptance", value: state.acceptanceLabel)
            MetricTile(label: "Completion", value: state.completionLabel)
            MetricTile(label: "Avg payout", value: "RM 18")
            MetricTile(label: "Customer", value: state.ratingLabel)
        }
    }

    private func tierProgress(_ state: PerformanceDashboardState) -> some View {
        VStack(alignment: .leading, spacing: Tokens.Space.sm) {
            HStack {
                Text("Tier progress")
                    .font(Tokens.FontRole.titleM)
                    .foregroundStyle(Tokens.Color.textPrimary)
                Spacer()
                Text(state.tier.tier.nextTierName)
                    .font(Tokens.FontRole.caption)
                    .foregroundStyle(Tokens.Color.textSecondary)
            }
            ProgressBar(progress: state.tierProgress)
            Text("\(state.tier.deliveries30D) of \(state.tier.tier.progressTarget) deliveries")
                .font(Tokens.FontRole.caption)
                .foregroundStyle(Tokens.Color.textSecondary)
        }
        .padding(Tokens.Space.md)
        .background(Tokens.Color.surface, in: RoundedRectangle(cornerRadius: Tokens.Radius.lg, style: .continuous))
    }
}
