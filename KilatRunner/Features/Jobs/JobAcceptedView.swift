import MapKit
import SwiftUI
import KilatUI

struct JobAcceptedView: View {
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    let booking: Booking
    let onCancel: () -> Void
    let onBackToDashboard: () -> Void
    @State private var animate = false
    @State private var startsRoute = false
    @State private var startsPreTrip = false

    enum StartDestination: Equatable {
        case preTripChecklist
        case activeDelivery
    }

    var startDestination: StartDestination {
        booking.isLivePet ? .preTripChecklist : .activeDelivery
    }

    init(
        booking: Booking,
        onCancel: @escaping () -> Void = {},
        onBackToDashboard: @escaping () -> Void = {}
    ) {
        self.booking = booking
        self.onCancel = onCancel
        self.onBackToDashboard = onBackToDashboard
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: Tokens.Space.lg) {
                celebration
                routeSummary
                if booking.isLivePet {
                    livePetBanner
                }
                PrimaryButton(title: "Start route", icon: "location.fill") {
                    startRoute()
                }
                Button("5-minute grace cancel") { onCancel() }
                    .font(Tokens.FontRole.label)
                    .foregroundStyle(Tokens.Color.textSecondary)
                    .frame(maxWidth: .infinity)
            }
            .padding(Tokens.Space.lg)
        }
        .background(Tokens.Color.background.ignoresSafeArea())
        .navigationTitle("Job accepted")
        .navigationBarTitleDisplayMode(.inline)
        .navigationDestination(isPresented: $startsRoute) {
            ActiveDeliveryView(
                viewModel: ActiveDeliveryViewModel(booking: booking),
                onBackToDashboard: onBackToDashboard
            )
        }
        .navigationDestination(isPresented: $startsPreTrip) {
            PreTripChecklistView(
                booking: booking,
                viewModel: PreTripChecklistViewModel(bookingID: booking.id),
                onBackToDashboard: onBackToDashboard
            )
        }
        .onAppear {
            guard !reduceMotion else {
                animate = true
                return
            }
            withAnimation(.spring(response: 0.7, dampingFraction: 0.7)) {
                animate = true
            }
        }
    }

    private func startRoute() {
        switch startDestination {
        case .preTripChecklist:
            startsPreTrip = true
        case .activeDelivery:
            startsRoute = true
        }
    }

    private var celebration: some View {
        VStack(spacing: Tokens.Space.md) {
            ZStack {
                ForEach(0..<10, id: \.self) { index in
                    Circle()
                        .fill(index.isMultiple(of: 2) ? Tokens.Color.primary : Tokens.Color.online)
                        .frame(width: 6, height: 6)
                        .offset(x: animate ? CGFloat((index % 5) - 2) * 28 : 0,
                                y: animate ? CGFloat(index / 5 == 0 ? -42 : 42) : 0)
                        .opacity(animate ? 0.85 : 0)
                }

                Circle()
                    .fill(Tokens.Color.primary.opacity(0.16))
                    .frame(width: animate ? 128 : 84, height: animate ? 128 : 84)
                Image(kilatAsset: "check")
                    .resizable()
                    .renderingMode(.template)
                    .frame(width: 56, height: 56)
                    .foregroundStyle(Tokens.Color.primary)
                    .scaleEffect(animate ? 1 : 0.75)
            }
            .frame(maxWidth: .infinity)
            .frame(height: 150)

            VStack(spacing: Tokens.Space.xs) {
                Text("You got it!")
                    .font(Tokens.FontRole.displayL)
                    .foregroundStyle(Tokens.Color.textPrimary)
                Text("\(booking.petSpec.petType.capitalized) - \(booking.petSpec.name.isEmpty ? booking.bookingNumber : booking.petSpec.name) is now yours")
                    .font(Tokens.FontRole.label)
                    .foregroundStyle(Tokens.Color.textSecondary)
                    .multilineTextAlignment(.center)
            }
            .frame(maxWidth: .infinity)
        }
    }

    private var routeSummary: some View {
        VStack(alignment: .leading, spacing: Tokens.Space.md) {
            Map(initialPosition: .region(mapRegion)) {
                Marker("Pickup", coordinate: booking.pickupCoordinate)
                    .tint(Tokens.Color.online)
                Marker("Drop-off", coordinate: booking.dropoffCoordinate)
                    .tint(Tokens.Color.destructive)
            }
            .frame(height: 150)
            .clipShape(RoundedRectangle(cornerRadius: Tokens.Radius.md))

            routeRow(label: "Pickup", address: booking.pickupAddress.singleLineLabel, color: Tokens.Color.online)
            routeRow(label: "Drop-off", address: booking.dropoffAddress.singleLineLabel, color: Tokens.Color.destructive)

            HStack {
                metric(label: "Distance", value: String(format: "%.1f km", booking.routeSpec?.distanceKm ?? 0))
                metric(label: "ETA", value: "\(booking.routeSpec?.estimatedDurationMin ?? 0) min")
                metric(label: "Payout", value: payoutLabel)
            }
        }
        .padding(Tokens.Space.md)
        .background(Tokens.Color.surface, in: RoundedRectangle(cornerRadius: Tokens.Radius.lg))
        .tokenShadow(Tokens.Shadow.card)
        .accessibilityIdentifier("jobAcceptedSummary")
    }

    private var livePetBanner: some View {
        HStack(alignment: .top, spacing: Tokens.Space.sm) {
            Image(kilatAsset: "paw")
                .resizable()
                .renderingMode(.template)
                .frame(width: 22, height: 22)
                .foregroundStyle(Tokens.Color.primary)
            Text("Live pet handling: keep the cabin calm, shaded, and secure before pickup.")
                .font(Tokens.FontRole.label)
                .foregroundStyle(Tokens.Color.onPrimaryTonal)
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding(Tokens.Space.md)
        .background(Tokens.Color.primaryTonal, in: RoundedRectangle(cornerRadius: Tokens.Radius.md))
        .accessibilityIdentifier("livePetReminder")
    }

    private func routeRow(label: String, address: String, color: Color) -> some View {
        HStack(alignment: .top, spacing: Tokens.Space.sm) {
            Circle().fill(color).frame(width: 10, height: 10).padding(.top, 6)
            VStack(alignment: .leading, spacing: Tokens.Space.xxs) {
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

    private func metric(label: String, value: String) -> some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(label)
                .font(Tokens.FontRole.caption)
                .foregroundStyle(Tokens.Color.textSecondary)
            Text(value)
                .font(Tokens.FontRole.bodyBold)
                .foregroundStyle(Tokens.Color.textPrimary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private var payoutLabel: String {
        let cents = booking.finalPriceCents ?? booking.estimatedPriceCents
        return "\(booking.currency) \(String(format: "%.2f", Double(cents) / 100))"
    }

    private var mapRegion: MKCoordinateRegion {
        let pickup = booking.pickupCoordinate
        let dropoff = booking.dropoffCoordinate
        let center = CLLocationCoordinate2D(
            latitude: (pickup.latitude + dropoff.latitude) / 2,
            longitude: (pickup.longitude + dropoff.longitude) / 2
        )
        let latSpan = max(abs(pickup.latitude - dropoff.latitude) * 1.8, 0.02)
        let lngSpan = max(abs(pickup.longitude - dropoff.longitude) * 1.8, 0.02)
        return MKCoordinateRegion(center: center, span: MKCoordinateSpan(latitudeDelta: latSpan, longitudeDelta: lngSpan))
    }
}

extension Booking {
    var isLivePet: Bool {
        let type = petSpec.petType.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        return !type.isEmpty && type != "supplies" && type != "item"
    }
}
