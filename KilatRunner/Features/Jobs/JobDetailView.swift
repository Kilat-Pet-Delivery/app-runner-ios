import MapKit
import SwiftUI

struct JobDetailView: View {
    @Environment(\.dismiss) private var dismiss
    @Bindable private var viewModel: JobDetailViewModel

    init(viewModel: JobDetailViewModel) {
        self.viewModel = viewModel
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 18) {
                summaryCard
                mapPreview
                if let errorMessage = viewModel.errorMessage {
                    errorBanner(message: errorMessage)
                }
                acceptButton
            }
            .padding(20)
        }
        .background(Color(.systemGroupedBackground))
        .navigationTitle(viewModel.booking.bookingNumber)
        .navigationBarTitleDisplayMode(.inline)
        .navigationDestination(
            isPresented: Binding(
                get: { viewModel.acceptedBookingId != nil },
                set: { newValue in if !newValue { viewModel.acceptedBookingId = nil } }
            )
        ) {
            ActiveDeliveryView(viewModel: ActiveDeliveryViewModel(booking: viewModel.booking)) {
                viewModel.acceptedBookingId = nil
                dismiss()
            }
        }
    }

    private var summaryCard: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack(alignment: .top) {
                VStack(alignment: .leading, spacing: 4) {
                    Label(
                        viewModel.booking.petSpec.name.isEmpty ? "Pet" : viewModel.booking.petSpec.name,
                        systemImage: "pawprint.fill"
                    )
                    .font(.headline)
                    if !viewModel.booking.petSpec.breed.isEmpty {
                        Text(viewModel.booking.petSpec.breed)
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    }
                }
                Spacer()
                VStack(alignment: .trailing, spacing: 4) {
                    Text(fareLabel)
                        .font(.headline)
                    if let distance = viewModel.booking.distanceKm {
                        Text(String(format: "%.1f km", distance))
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }
            }

            Divider()

            routeRow(
                icon: "circle.fill",
                tint: .green,
                title: "Pickup",
                address: viewModel.booking.pickupAddress.singleLineLabel
            )
            routeRow(
                icon: "mappin.circle.fill",
                tint: .red,
                title: "Drop-off",
                address: viewModel.booking.dropoffAddress.singleLineLabel
            )

            if !(viewModel.booking.notes ?? "").isEmpty {
                Divider()
                VStack(alignment: .leading, spacing: 4) {
                    Text("Notes")
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(.secondary)
                    Text(viewModel.booking.notes ?? "")
                        .font(.subheadline)
                }
            }
        }
        .padding(18)
        .background(Color(.secondarySystemGroupedBackground), in: RoundedRectangle(cornerRadius: 8))
    }

    private var mapPreview: some View {
        Map(initialPosition: .region(mapRegion)) {
            Marker("Pickup", coordinate: viewModel.booking.pickupCoordinate)
                .tint(.green)
            Marker("Drop-off", coordinate: viewModel.booking.dropoffCoordinate)
                .tint(.red)
        }
        .frame(height: 220)
        .clipShape(RoundedRectangle(cornerRadius: 8))
    }

    private var acceptButton: some View {
        Button {
            Task { await viewModel.accept() }
        } label: {
            HStack {
                if viewModel.isAccepting {
                    ProgressView()
                }
                Text(viewModel.isAccepting ? "Accepting…" : "Accept Job")
                    .fontWeight(.semibold)
            }
            .frame(maxWidth: .infinity)
        }
        .buttonStyle(.borderedProminent)
        .controlSize(.large)
        .tint(.green)
        .disabled(viewModel.isAccepting)
    }

    private func routeRow(icon: String, tint: Color, title: String, address: String) -> some View {
        HStack(alignment: .top, spacing: 12) {
            Image(systemName: icon)
                .foregroundStyle(tint)
                .font(.caption)
                .padding(.top, 6)
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(.secondary)
                Text(address)
                    .font(.subheadline)
                    .foregroundStyle(.primary)
            }
            Spacer()
        }
    }

    private func errorBanner(message: String) -> some View {
        HStack(alignment: .top, spacing: 12) {
            Image(systemName: "exclamationmark.triangle.fill")
                .foregroundStyle(.orange)
            Text(message)
                .font(.subheadline)
                .foregroundStyle(.primary)
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding(14)
        .background(Color(.secondarySystemGroupedBackground), in: RoundedRectangle(cornerRadius: 8))
    }

    private var fareLabel: String {
        let cents = viewModel.booking.finalPriceCents ?? viewModel.booking.estimatedPriceCents
        let amount = Double(cents) / 100
        return "\(viewModel.booking.currency) \(String(format: "%.2f", amount))"
    }

    private var mapRegion: MKCoordinateRegion {
        let pickup = viewModel.booking.pickupCoordinate
        let dropoff = viewModel.booking.dropoffCoordinate
        let center = CLLocationCoordinate2D(
            latitude: (pickup.latitude + dropoff.latitude) / 2,
            longitude: (pickup.longitude + dropoff.longitude) / 2
        )
        let latSpan = max(abs(pickup.latitude - dropoff.latitude) * 1.6, 0.02)
        let lngSpan = max(abs(pickup.longitude - dropoff.longitude) * 1.6, 0.02)
        return MKCoordinateRegion(
            center: center,
            span: MKCoordinateSpan(latitudeDelta: latSpan, longitudeDelta: lngSpan)
        )
    }
}
