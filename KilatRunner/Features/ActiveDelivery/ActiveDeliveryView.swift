import MapKit
import SwiftUI
import KilatUI

struct ActiveDeliveryView: View {
    @Bindable private var viewModel: ActiveDeliveryViewModel
    private let onBackToDashboard: () -> Void

    init(viewModel: ActiveDeliveryViewModel, onBackToDashboard: @escaping () -> Void = {}) {
        self.viewModel = viewModel
        self.onBackToDashboard = onBackToDashboard
    }

    var body: some View {
        ZStack(alignment: .bottom) {
            map.ignoresSafeArea()

            VStack(spacing: 0) {
                Spacer()
                bottomSheet
            }

            if viewModel.deliveryPhase == .delivered {
                tripCompleteOverlay
            }
        }
        .navigationTitle("Active delivery")
        .navigationBarTitleDisplayMode(.inline)
        .onAppear { viewModel.onAppear() }
        .onDisappear { Task { await viewModel.onDisappear() } }
    }

    private var map: some View {
        Map(initialPosition: .region(mapRegion)) {
            Marker("Pickup", coordinate: viewModel.pickupCoordinate)
                .tint(Tokens.Color.online)
            Marker("Drop-off", coordinate: viewModel.dropoffCoordinate)
                .tint(Tokens.Color.destructive)
            if let current = viewModel.currentLocation {
                Annotation("You", coordinate: current) {
                    runnerPin
                }
            }
        }
    }

    private var runnerPin: some View {
        ZStack {
            Circle()
                .fill(Tokens.Color.primary.opacity(0.25))
                .frame(width: 36, height: 36)
            Circle()
                .fill(Tokens.Color.primary)
                .frame(width: 16, height: 16)
                .overlay(Circle().stroke(.white, lineWidth: 2))
        }
        .accessibilityIdentifier("runnerPin")
    }

    private var bottomSheet: some View {
        VStack(alignment: .leading, spacing: Tokens.Space.md) {
            HStack {
                Text(stageHeading)
                    .font(Tokens.FontRole.titleM)
                    .foregroundStyle(Tokens.Color.textPrimary)
                Spacer()
                StatusBadge(status: .inTransit)
            }

            customerContactRow

            VStack(alignment: .leading, spacing: Tokens.Space.xs) {
                routeRow(dotColor: Tokens.Color.online,
                         label: "Pickup",
                         address: viewModel.booking.pickupAddress.singleLineLabel)
                routeRow(dotColor: Tokens.Color.destructive,
                         label: "Drop-off",
                         address: viewModel.booking.dropoffAddress.singleLineLabel)
            }

            if let errorMessage = viewModel.errorMessage {
                errorBanner(message: errorMessage)
            }

            PrimaryButton(
                title: stageCtaTitle,
                icon: stageCtaIcon,
                isLoading: viewModel.isMarkingPickup || viewModel.isMarkingDelivered,
                isEnabled: stageCtaEnabled,
                action: stageCtaAction
            )
            .accessibilityIdentifier("activeDeliveryCTA")
        }
        .padding(Tokens.Space.lg)
        .background(Tokens.Color.surface)
        .clipShape(.rect(topLeadingRadius: Tokens.Radius.xl, topTrailingRadius: Tokens.Radius.xl))
        .tokenShadow(Tokens.Shadow.raised)
    }

    private var customerContactRow: some View {
        HStack(spacing: Tokens.Space.sm) {
            HStack(spacing: Tokens.Space.xs) {
                Image(kilatAsset: "paw")
                    .resizable()
                    .renderingMode(.template)
                    .frame(width: 18, height: 18)
                    .foregroundStyle(Tokens.Color.primary)
                Text(viewModel.booking.petSpec.name.isEmpty ? "Pet" : viewModel.booking.petSpec.name)
                    .font(Tokens.FontRole.bodyBold)
                    .foregroundStyle(Tokens.Color.textPrimary)
            }
            Spacer()
            Button {} label: {
                Image(kilatAsset: "phone")
                    .resizable()
                    .renderingMode(.template)
                    .frame(width: 22, height: 22)
                    .foregroundStyle(Tokens.Color.primary)
            }
            .accessibilityLabel("Call customer")
            Button {} label: {
                Image(kilatAsset: "message")
                    .resizable()
                    .renderingMode(.template)
                    .frame(width: 22, height: 22)
                    .foregroundStyle(Tokens.Color.primary)
            }
            .accessibilityLabel("Message customer")
        }
    }

    private var tripCompleteOverlay: some View {
        Color.black.opacity(0.32)
            .ignoresSafeArea()
            .overlay {
                VStack(spacing: Tokens.Space.lg) {
                    Image(kilatAsset: "check")
                        .resizable()
                        .renderingMode(.template)
                        .frame(width: 56, height: 56)
                        .foregroundStyle(Tokens.Color.online)

                    VStack(spacing: Tokens.Space.xxs) {
                        Text("Trip complete")
                            .font(Tokens.FontRole.titleL)
                            .foregroundStyle(Tokens.Color.textPrimary)
                        Text(fareLabel)
                            .font(Tokens.FontRole.titleM)
                            .foregroundStyle(Tokens.Color.primary)
                    }

                    PrimaryButton(title: "Back to dashboard", icon: "house.fill", action: onBackToDashboard)
                }
                .padding(Tokens.Space.xl)
                .frame(maxWidth: 360)
                .background(Tokens.Color.surface,
                            in: RoundedRectangle(cornerRadius: Tokens.Radius.xl, style: .continuous))
                .padding(.horizontal, Tokens.Space.xl)
            }
    }

    private func routeRow(dotColor: Color, label: String, address: String) -> some View {
        HStack(alignment: .top, spacing: Tokens.Space.sm) {
            Circle().fill(dotColor).frame(width: 10, height: 10).padding(.top, 5)
            VStack(alignment: .leading, spacing: 2) {
                Text(label)
                    .font(Tokens.FontRole.caption)
                    .foregroundStyle(Tokens.Color.textSecondary)
                    .textCase(.uppercase)
                Text(address)
                    .font(Tokens.FontRole.label)
                    .foregroundStyle(Tokens.Color.textPrimary)
                    .lineLimit(2)
            }
        }
    }

    private func errorBanner(message: String) -> some View {
        HStack(alignment: .top, spacing: Tokens.Space.xs) {
            Image(kilatAsset: "alert")
                .resizable()
                .renderingMode(.template)
                .frame(width: 16, height: 16)
                .foregroundStyle(Tokens.Color.destructive)
            Text(message)
                .font(Tokens.FontRole.caption)
                .foregroundStyle(Tokens.Color.textPrimary)
        }
        .padding(Tokens.Space.xs)
        .background(Tokens.Color.surfaceMuted, in: RoundedRectangle(cornerRadius: Tokens.Radius.sm, style: .continuous))
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

    private var stageHeading: String {
        switch viewModel.presentationStage {
        case .toPickup:   return "Heading to pickup"
        case .atPickup:   return "Arrived at pickup"
        case .toDropoff:  return "Heading to drop-off"
        case .atDropoff:  return "Arrived at drop-off"
        case .delivered:  return "Delivered"
        }
    }

    private var stageCtaTitle: String {
        switch viewModel.presentationStage {
        case .toPickup:   return "I have arrived"
        case .atPickup:   return "Picked up"
        case .toDropoff:  return "I have arrived"
        case .atDropoff:  return "Mark delivered"
        case .delivered:  return "Back to dashboard"
        }
    }

    private var stageCtaIcon: String? {
        switch viewModel.presentationStage {
        case .toPickup, .toDropoff: return "mappin.circle.fill"
        case .atPickup:             return "shippingbox.fill"
        case .atDropoff:            return "checkmark.circle.fill"
        case .delivered:            return "house.fill"
        }
    }

    private var stageCtaEnabled: Bool {
        switch viewModel.presentationStage {
        case .toPickup, .toDropoff: return !viewModel.isMarkingPickup && !viewModel.isMarkingDelivered
        case .atPickup:             return !viewModel.isMarkingPickup
        case .atDropoff:            return !viewModel.isMarkingDelivered
        case .delivered:            return true
        }
    }

    private var stageCtaAction: () -> Void {
        switch viewModel.presentationStage {
        case .toPickup, .toDropoff:
            return { viewModel.hasArrivedAtCurrentWaypoint = true }
        case .atPickup:
            return {
                Task {
                    await viewModel.markPickup()
                    viewModel.hasArrivedAtCurrentWaypoint = false
                }
            }
        case .atDropoff:
            return {
                Task {
                    await viewModel.markDelivered()
                    viewModel.hasArrivedAtCurrentWaypoint = false
                }
            }
        case .delivered:
            return onBackToDashboard
        }
    }

    private var fareLabel: String {
        let cents = viewModel.booking.finalPriceCents ?? viewModel.booking.estimatedPriceCents
        return "\(viewModel.booking.currency) \(String(format: "%.2f", Double(cents) / 100))"
    }
}
