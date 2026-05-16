import SwiftUI

struct EarningsView: View {
    @Bindable private var viewModel: EarningsViewModel

    init(viewModel: EarningsViewModel) {
        self.viewModel = viewModel
    }

    var body: some View {
        Group {
            if viewModel.isLoading && viewModel.earnings.isEmpty {
                ProgressView("Loading earnings")
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else if let errorMessage = viewModel.errorMessage, viewModel.earnings.isEmpty {
                ContentUnavailableView {
                    Label("Could not load earnings", systemImage: "wifi.exclamationmark")
                } description: {
                    Text(errorMessage)
                } actions: {
                    Button("Try Again") {
                        Task { await viewModel.loadFirstPage() }
                    }
                    .buttonStyle(.borderedProminent)
                }
            } else if viewModel.earnings.isEmpty {
                ContentUnavailableView(
                    "No earnings yet",
                    systemImage: "banknote",
                    description: Text("Completed trips will appear here.")
                )
            } else {
                List {
                    ForEach(viewModel.earnings) { earning in
                        row(for: earning)
                            .onAppear {
                                if earning.id == viewModel.earnings.last?.id {
                                    Task { await viewModel.loadNextPage() }
                                }
                            }
                    }

                    if viewModel.isLoading {
                        HStack {
                            Spacer()
                            ProgressView()
                            Spacer()
                        }
                    }
                }
                .listStyle(.plain)
            }
        }
        .navigationTitle("Earnings")
        .refreshable {
            await viewModel.loadFirstPage()
        }
        .task {
            if viewModel.earnings.isEmpty {
                await viewModel.loadFirstPage()
            }
        }
    }

    private func row(for earning: Earning) -> some View {
        HStack(alignment: .top, spacing: 12) {
            Image(systemName: "banknote.fill")
                .font(.title3)
                .foregroundStyle(.green)
                .frame(width: 30)

            VStack(alignment: .leading, spacing: 4) {
                Text(shortBookingId(earning.bookingId))
                    .font(.subheadline.weight(.semibold))
                Text(earning.completedAt.formatted(date: .abbreviated, time: .shortened))
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            Spacer()

            Text(amountLabel(earning))
                .font(.subheadline.weight(.semibold))
        }
        .padding(.vertical, 6)
    }

    private func shortBookingId(_ id: String) -> String {
        "Booking \(String(id.prefix(8)))"
    }

    private func amountLabel(_ earning: Earning) -> String {
        let amount = Double(earning.amountCents) / 100
        return "\(earning.currency) \(String(format: "%.2f", amount))"
    }
}

#Preview {
    NavigationStack {
        EarningsView(viewModel: EarningsViewModel())
    }
}
