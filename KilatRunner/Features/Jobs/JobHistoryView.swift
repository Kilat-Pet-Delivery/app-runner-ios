import SwiftUI
import KilatUI

struct JobHistoryView: View {
    @Bindable var viewModel: JobHistoryViewModel

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: Tokens.Space.lg) {
                summary
                filters

                if viewModel.bookings.isEmpty, viewModel.isLoading {
                    ProgressView()
                        .frame(maxWidth: .infinity)
                        .padding(.top, Tokens.Space.xl)
                } else if viewModel.bookings.isEmpty {
                    emptyState
                } else {
                    sections
                }

                if viewModel.hasMore {
                    PrimaryButton(
                        title: "Load more",
                        icon: "arrow.down.circle.fill",
                        isLoading: viewModel.isLoading,
                        action: { Task { await viewModel.loadMore() } }
                    )
                }

                if let errorMessage = viewModel.errorMessage {
                    Text(errorMessage)
                        .font(Tokens.FontRole.caption)
                        .foregroundStyle(Tokens.Color.destructive)
                }
            }
            .padding(Tokens.Space.lg)
        }
        .background(Tokens.Color.background.ignoresSafeArea())
        .navigationTitle("Job History")
        .navigationBarTitleDisplayMode(.inline)
        .task {
            if viewModel.bookings.isEmpty {
                await viewModel.loadFirstPage()
            }
        }
    }

    private var summary: some View {
        HStack(spacing: Tokens.Space.sm) {
            MetricTile(label: "This month", value: "\(viewModel.deliveriesThisMonth)")
            MetricTile(label: "Earnings", value: money(viewModel.totalEarningsCents))
        }
    }

    private var filters: some View {
        HStack(spacing: Tokens.Space.xs) {
            ForEach(BookingHistoryFilter.allCases) { filter in
                Button {
                    Task { await viewModel.applyFilter(filter) }
                } label: {
                    Text(filter.label)
                        .font(Tokens.FontRole.caption)
                        .foregroundStyle(viewModel.filter == filter ? Tokens.Color.onPrimaryTonal : Tokens.Color.textPrimary)
                        .padding(.horizontal, Tokens.Space.sm)
                        .padding(.vertical, Tokens.Space.xs)
                        .background(
                            viewModel.filter == filter ? Tokens.Color.primaryTonal : Tokens.Color.surface,
                            in: Capsule()
                        )
                }
                .buttonStyle(.plain)
            }
        }
    }

    private var sections: some View {
        VStack(alignment: .leading, spacing: Tokens.Space.lg) {
            ForEach(viewModel.sections) { section in
                VStack(alignment: .leading, spacing: Tokens.Space.sm) {
                    Text(section.title)
                        .font(Tokens.FontRole.caption)
                        .foregroundStyle(Tokens.Color.textSecondary)
                        .textCase(.uppercase)
                    ForEach(section.bookings) { booking in
                        historyRow(booking)
                    }
                }
            }
        }
    }

    private var emptyState: some View {
        VStack(spacing: Tokens.Space.sm) {
            Image(systemName: "clock.arrow.circlepath")
                .font(.system(size: 34, weight: .semibold))
                .foregroundStyle(Tokens.Color.primary)
            Text("No jobs yet")
                .font(Tokens.FontRole.titleM)
                .foregroundStyle(Tokens.Color.textPrimary)
        }
        .frame(maxWidth: .infinity)
        .padding(Tokens.Space.xl)
        .background(Tokens.Color.surface, in: RoundedRectangle(cornerRadius: Tokens.Radius.lg, style: .continuous))
    }

    private func historyRow(_ booking: Booking) -> some View {
        HStack(alignment: .top, spacing: Tokens.Space.sm) {
            Image(systemName: icon(for: booking))
                .font(.system(size: 22, weight: .semibold))
                .foregroundStyle(Tokens.Color.primary)
                .frame(width: 34, height: 34)
                .background(Tokens.Color.primaryTonal, in: Circle())

            VStack(alignment: .leading, spacing: Tokens.Space.xxs) {
                Text("\(booking.pickupAddress.city) → \(booking.dropoffAddress.city)")
                    .font(Tokens.FontRole.bodyBold)
                    .foregroundStyle(Tokens.Color.textPrimary)
                    .lineLimit(2)
                HStack(spacing: Tokens.Space.xs) {
                    if booking.petSpec.petType.lowercased() != "supplies" {
                        tag("LIVE", color: Tokens.Color.online)
                    }
                    if booking.status == .cancelled {
                        tag("CANCELLED", color: Tokens.Color.destructive)
                    }
                }
            }

            Spacer()

            VStack(alignment: .trailing, spacing: Tokens.Space.xxs) {
                Text(money(booking.finalPriceCents ?? booking.estimatedPriceCents))
                    .font(Tokens.FontRole.bodyBold)
                    .foregroundStyle(Tokens.Color.textPrimary)
                if (booking.finalPriceCents ?? 0) > booking.estimatedPriceCents {
                    Text("Tip")
                        .font(Tokens.FontRole.caption)
                        .foregroundStyle(Tokens.Color.primary)
                }
            }
        }
        .padding(Tokens.Space.md)
        .background(Tokens.Color.surface, in: RoundedRectangle(cornerRadius: Tokens.Radius.md, style: .continuous))
    }

    private func tag(_ title: String, color: Color) -> some View {
        Text(title)
            .font(Tokens.FontRole.caption)
            .foregroundStyle(color)
            .padding(.horizontal, Tokens.Space.xs)
            .padding(.vertical, 2)
            .background(Tokens.Color.surfaceMuted, in: Capsule())
    }

    private func icon(for booking: Booking) -> String {
        booking.petSpec.petType.lowercased() == "dog" ? "dog.fill" : "pawprint.fill"
    }

    private func money(_ cents: Int64) -> String {
        String(format: "RM %.2f", Double(cents) / 100)
    }
}
