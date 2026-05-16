import SwiftUI

struct AvailableJobsView: View {
    @Bindable private var viewModel: AvailableJobsViewModel

    init(viewModel: AvailableJobsViewModel) {
        self.viewModel = viewModel
    }

    var body: some View {
        Group {
            if viewModel.isLoading && viewModel.jobs.isEmpty {
                ProgressView("Loading available jobs")
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else if let errorMessage = viewModel.errorMessage, viewModel.jobs.isEmpty {
                ContentUnavailableView {
                    Label("Could not load jobs", systemImage: "wifi.exclamationmark")
                } description: {
                    Text(errorMessage)
                } actions: {
                    Button("Try Again") {
                        Task { await viewModel.load() }
                    }
                    .buttonStyle(.borderedProminent)
                }
            } else if viewModel.jobs.isEmpty {
                ContentUnavailableView(
                    "No available jobs",
                    systemImage: "shippingbox",
                    description: Text("Pull to refresh when new bookings come in.")
                )
            } else {
                List(viewModel.jobs) { booking in
                    NavigationLink {
                        JobDetailView(viewModel: JobDetailViewModel(booking: booking))
                    } label: {
                        row(for: booking)
                    }
                }
                .listStyle(.plain)
            }
        }
        .navigationTitle("Available Jobs")
        .refreshable {
            await viewModel.refresh()
        }
        .task {
            await viewModel.load()
        }
    }

    private func row(for booking: Booking) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Label(booking.petSpec.name.isEmpty ? "Pet" : booking.petSpec.name, systemImage: "pawprint.fill")
                    .font(.subheadline.weight(.semibold))
                Spacer()
                Text(fareLabel(booking))
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(.primary)
            }

            VStack(alignment: .leading, spacing: 6) {
                routeLine(icon: "circle.fill", iconColor: .green, text: booking.pickupAddress.singleLineLabel)
                routeLine(icon: "mappin.circle.fill", iconColor: .red, text: booking.dropoffAddress.singleLineLabel)
            }

            if let distance = booking.distanceKm {
                Text(String(format: "%.1f km", distance))
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
        .padding(.vertical, 6)
    }

    private func routeLine(icon: String, iconColor: Color, text: String) -> some View {
        HStack(alignment: .top, spacing: 8) {
            Image(systemName: icon)
                .foregroundStyle(iconColor)
                .font(.caption)
                .padding(.top, 4)
            Text(text)
                .font(.subheadline)
                .foregroundStyle(.primary)
                .lineLimit(2)
        }
    }

    private func fareLabel(_ booking: Booking) -> String {
        let cents = booking.finalPriceCents ?? booking.estimatedPriceCents
        let amount = Double(cents) / 100
        return "\(booking.currency) \(String(format: "%.2f", amount))"
    }
}

#Preview {
    NavigationStack {
        AvailableJobsView(viewModel: AvailableJobsViewModel())
    }
}
