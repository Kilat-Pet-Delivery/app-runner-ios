import MapKit
import SwiftUI

struct ActiveDeliveryView: View {
    @Bindable private var viewModel: ActiveDeliveryViewModel
    private let onBackToDashboard: () -> Void

    init(viewModel: ActiveDeliveryViewModel, onBackToDashboard: @escaping () -> Void = {}) {
        self.viewModel = viewModel
        self.onBackToDashboard = onBackToDashboard
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
            if viewModel.deliveryPhase == .delivered {
                tripCompleteOverlay
            }
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
            if let errorMessage = viewModel.errorMessage {
                errorBanner(message: errorMessage)
            }

            Button {
                Task { await viewModel.markPickup() }
            } label: {
                HStack {
                    if viewModel.isMarkingPickup {
                        ProgressView()
                    }
                    Label("Picked Up", systemImage: "shippingbox.fill")
                        .fontWeight(.semibold)
                }
                .frame(maxWidth: .infinity)
            }
            .buttonStyle(.borderedProminent)
            .controlSize(.large)
            .tint(.orange)
            .disabled(viewModel.deliveryPhase != .enroute || viewModel.isMarkingPickup)

            Button {
                Task { await viewModel.markDelivered() }
            } label: {
                HStack {
                    if viewModel.isMarkingDelivered {
                        ProgressView()
                    }
                    Label("Mark Delivered", systemImage: "checkmark.circle.fill")
                        .fontWeight(.semibold)
                }
                .frame(maxWidth: .infinity)
            }
            .buttonStyle(.borderedProminent)
            .controlSize(.large)
            .tint(.green)
            .disabled(viewModel.deliveryPhase != .pickedUp || viewModel.isMarkingDelivered)
        }
        .padding(14)
        .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 8))
    }

    private var tripCompleteOverlay: some View {
        Color.black.opacity(0.28)
            .ignoresSafeArea()
            .overlay {
                VStack(spacing: 18) {
                    Image(systemName: "checkmark.seal.fill")
                        .font(.system(size: 44, weight: .semibold))
                        .foregroundStyle(.green)

                    VStack(spacing: 6) {
                        Text("Trip complete")
                            .font(.title2.bold())
                        Text(fareLabel)
                            .font(.headline)
                            .foregroundStyle(.secondary)
                    }

                    Button {
                        onBackToDashboard()
                    } label: {
                        Label("Back to Dashboard", systemImage: "house.fill")
                            .fontWeight(.semibold)
                            .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(.borderedProminent)
                    .controlSize(.large)
                    .tint(.green)
                }
                .padding(20)
                .frame(maxWidth: 340)
                .background(Color(.systemBackground), in: RoundedRectangle(cornerRadius: 8))
                .padding(.horizontal, 24)
            }
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

    private func errorBanner(message: String) -> some View {
        HStack(alignment: .top, spacing: 10) {
            Image(systemName: "exclamationmark.triangle.fill")
                .foregroundStyle(.orange)
            Text(message)
                .font(.caption)
                .foregroundStyle(.primary)
                .fixedSize(horizontal: false, vertical: true)
            Spacer(minLength: 0)
        }
        .padding(10)
        .background(Color(.systemBackground).opacity(0.72), in: RoundedRectangle(cornerRadius: 8))
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

    private var fareLabel: String {
        let cents = viewModel.booking.finalPriceCents ?? viewModel.booking.estimatedPriceCents
        let amount = Double(cents) / 100
        return "\(viewModel.booking.currency) \(String(format: "%.2f", amount))"
    }
}
