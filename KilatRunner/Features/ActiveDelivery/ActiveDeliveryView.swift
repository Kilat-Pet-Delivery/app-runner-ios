import MapKit
import SwiftUI

struct ActiveDeliveryView: View {
    @Bindable private var viewModel: ActiveDeliveryViewModel

    init(viewModel: ActiveDeliveryViewModel) {
        self.viewModel = viewModel
    }

    var body: some View {
        ZStack(alignment: .top) {
            map
                .ignoresSafeArea(edges: .bottom)
            VStack(spacing: 12) {
                summaryCard
                Spacer()
                actionCard
            }
            .padding(.horizontal, 16)
            .padding(.top, 8)
            .padding(.bottom, 24)
        }
        .navigationTitle("Active Delivery")
        .navigationBarTitleDisplayMode(.inline)
        .onAppear {
            viewModel.onAppear()
        }
        .task {
            // onDisappear handles cleanup via Task cancellation when view goes away.
        }
        .onDisappear {
            Task { await viewModel.onDisappear() }
        }
    }

    private var map: some View {
        Map(initialPosition: .region(mapRegion)) {
            Marker("Pickup", coordinate: viewModel.pickupCoordinate)
                .tint(.green)
            Marker("Drop-off", coordinate: viewModel.dropoffCoordinate)
                .tint(.red)
            if let current = viewModel.currentLocation {
                Marker("You", systemImage: "location.fill", coordinate: current)
                    .tint(.blue)
            }
        }
    }

    private var summaryCard: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Label(
                    viewModel.booking.petSpec.name.isEmpty ? "Pet" : viewModel.booking.petSpec.name,
                    systemImage: "pawprint.fill"
                )
                .font(.subheadline.weight(.semibold))
                Spacer()
                Text(phaseLabel)
                    .font(.caption.weight(.semibold))
                    .padding(.horizontal, 10)
                    .padding(.vertical, 4)
                    .background(phaseTint.opacity(0.15), in: Capsule())
                    .foregroundStyle(phaseTint)
            }
            VStack(alignment: .leading, spacing: 4) {
                routeLine(icon: "circle.fill", tint: .green, text: viewModel.booking.pickupAddress.singleLineLabel)
                routeLine(icon: "mappin.circle.fill", tint: .red, text: viewModel.booking.dropoffAddress.singleLineLabel)
            }
        }
        .padding(14)
        .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 8))
    }

    private var actionCard: some View {
        VStack(spacing: 10) {
            Button {
                // Wired in Phase 8.
            } label: {
                Text("Picked Up")
                    .fontWeight(.semibold)
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(.borderedProminent)
            .controlSize(.large)
            .tint(.orange)
            .disabled(viewModel.deliveryPhase != .enroute)

            Button {
                // Wired in Phase 8.
            } label: {
                Text("Mark Delivered")
                    .fontWeight(.semibold)
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(.borderedProminent)
            .controlSize(.large)
            .tint(.green)
            .disabled(viewModel.deliveryPhase != .pickedUp)
        }
        .padding(14)
        .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 8))
    }

    private func routeLine(icon: String, tint: Color, text: String) -> some View {
        HStack(alignment: .top, spacing: 8) {
            Image(systemName: icon)
                .foregroundStyle(tint)
                .font(.caption)
                .padding(.top, 4)
            Text(text)
                .font(.subheadline)
                .lineLimit(2)
        }
    }

    private var mapRegion: MKCoordinateRegion {
        let pickup = viewModel.pickupCoordinate
        let dropoff = viewModel.dropoffCoordinate
        let center = CLLocationCoordinate2D(
            latitude: (pickup.latitude + dropoff.latitude) / 2,
            longitude: (pickup.longitude + dropoff.longitude) / 2
        )
        let latSpan = max(abs(pickup.latitude - dropoff.latitude) * 1.8, 0.02)
        let lngSpan = max(abs(pickup.longitude - dropoff.longitude) * 1.8, 0.02)
        return MKCoordinateRegion(
            center: center,
            span: MKCoordinateSpan(latitudeDelta: latSpan, longitudeDelta: lngSpan)
        )
    }

    private var phaseLabel: String {
        switch viewModel.deliveryPhase {
        case .enroute: return "En route"
        case .pickedUp: return "Picked up"
        case .delivered: return "Delivered"
        }
    }

    private var phaseTint: Color {
        switch viewModel.deliveryPhase {
        case .enroute: return .blue
        case .pickedUp: return .orange
        case .delivered: return .green
        }
    }
}
