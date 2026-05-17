import MapKit
import SwiftUI
import KilatUI

struct JobDetailView: View {
    @Environment(\.dismiss) private var dismiss
    @Bindable private var viewModel: JobDetailViewModel

    init(viewModel: JobDetailViewModel) {
        self.viewModel = viewModel
    }

    var body: some View {
        VStack(spacing: 0) {
            ScrollView {
                VStack(alignment: .leading, spacing: Tokens.Space.md) {
                    headerRow
                    mapPreview
                    routeCard
                    if let notes = viewModel.booking.notes, !notes.isEmpty {
                        notesCard(notes: notes)
                    }
                    feeBreakdown
                    if let errorMessage = viewModel.errorMessage {
                        errorBanner(message: errorMessage)
                    }
                }
                .padding(Tokens.Space.md)
            }
            stickyFooter
        }
        .background(Tokens.Color.background.ignoresSafeArea())
        .navigationTitle(viewModel.booking.bookingNumber)
        .navigationBarTitleDisplayMode(.inline)
        .sheet(isPresented: $viewModel.showsDeclineSheet) {
            // TODO(phase-9-9.6): replace with DeclineReasonSheet content
            declineStubSheet
        }
        .navigationDestination(
            isPresented: Binding(
                get: { viewModel.acceptedBookingId != nil },
                set: { newValue in if !newValue { viewModel.acceptedBookingId = nil } }
            )
        ) {
            // TODO(phase-9-9.5): route via JobAcceptedView celebration screen before ActiveDelivery
            ActiveDeliveryView(viewModel: ActiveDeliveryViewModel(booking: viewModel.booking)) {
                viewModel.acceptedBookingId = nil
                dismiss()
            }
        }
    }

    private var headerRow: some View {
        HStack(alignment: .top) {
            VStack(alignment: .leading, spacing: Tokens.Space.xxs) {
                HStack(spacing: Tokens.Space.xs) {
                    Image(kilatAsset: "paw")
                        .resizable()
                        .renderingMode(.template)
                        .frame(width: 18, height: 18)
                        .foregroundStyle(Tokens.Color.primary)
                    Text(viewModel.booking.petSpec.name.isEmpty ? "Pet" : viewModel.booking.petSpec.name)
                        .font(Tokens.FontRole.titleM)
                        .foregroundStyle(Tokens.Color.textPrimary)
                }
                if !viewModel.booking.petSpec.breed.isEmpty {
                    Text(viewModel.booking.petSpec.breed)
                        .font(Tokens.FontRole.label)
                        .foregroundStyle(Tokens.Color.textSecondary)
                }
            }
            Spacer()
            VStack(alignment: .trailing, spacing: Tokens.Space.xxs) {
                Text(fareLabel)
                    .font(Tokens.FontRole.titleM)
                    .foregroundStyle(Tokens.Color.primary)
                if let distance = viewModel.booking.distanceKm {
                    Text(String(format: "%.1f km", distance))
                        .font(Tokens.FontRole.caption)
                        .foregroundStyle(Tokens.Color.textSecondary)
                }
            }
        }
    }

    private var mapPreview: some View {
        Map(initialPosition: .region(mapRegion)) {
            Marker("Pickup", coordinate: viewModel.booking.pickupCoordinate)
                .tint(Tokens.Color.online)
            Marker("Drop-off", coordinate: viewModel.booking.dropoffCoordinate)
                .tint(Tokens.Color.destructive)
        }
        .frame(height: 200)
        .clipShape(RoundedRectangle(cornerRadius: Tokens.Radius.lg))
    }

    private var routeCard: some View {
        VStack(alignment: .leading, spacing: Tokens.Space.md) {
            routeRow(dotColor: Tokens.Color.online,
                     title: "Pickup",
                     address: viewModel.booking.pickupAddress.singleLineLabel)
            Divider().background(Tokens.Color.separator)
            routeRow(dotColor: Tokens.Color.destructive,
                     title: "Drop-off",
                     address: viewModel.booking.dropoffAddress.singleLineLabel)
        }
        .padding(Tokens.Space.md)
        .background(Tokens.Color.surface, in: RoundedRectangle(cornerRadius: Tokens.Radius.lg, style: .continuous))
        .tokenShadow(Tokens.Shadow.card)
    }

    private func notesCard(notes: String) -> some View {
        VStack(alignment: .leading, spacing: Tokens.Space.xs) {
            Text("Pickup notes")
                .font(Tokens.FontRole.caption)
                .foregroundStyle(Tokens.Color.textSecondary)
                .textCase(.uppercase)
            Text(notes)
                .font(Tokens.FontRole.body)
                .foregroundStyle(Tokens.Color.textPrimary)
        }
        .padding(Tokens.Space.md)
        .background(Tokens.Color.surface, in: RoundedRectangle(cornerRadius: Tokens.Radius.md, style: .continuous))
    }

    private var feeBreakdown: some View {
        VStack(spacing: Tokens.Space.xs) {
            feeRow(label: "Base fare", amount: estimatedAmount * 0.7)
            feeRow(label: "Distance", amount: estimatedAmount * 0.25)
            feeRow(label: "Service fee", amount: estimatedAmount * 0.05)
            Divider().background(Tokens.Color.separator)
            feeRow(label: "Total", amount: estimatedAmount, isTotal: true)
        }
        .padding(Tokens.Space.md)
        .background(Tokens.Color.surface, in: RoundedRectangle(cornerRadius: Tokens.Radius.md, style: .continuous))
    }

    private func feeRow(label: String, amount: Double, isTotal: Bool = false) -> some View {
        HStack {
            Text(label)
                .font(isTotal ? Tokens.FontRole.bodyBold : Tokens.FontRole.label)
                .foregroundStyle(isTotal ? Tokens.Color.textPrimary : Tokens.Color.textSecondary)
            Spacer()
            Text("\(viewModel.booking.currency) \(String(format: "%.2f", amount))")
                .font(isTotal ? Tokens.FontRole.bodyBold : Tokens.FontRole.label)
                .foregroundStyle(isTotal ? Tokens.Color.primary : Tokens.Color.textPrimary)
        }
    }

    private var stickyFooter: some View {
        HStack(spacing: Tokens.Space.sm) {
            SecondaryButton(title: "Decline") {
                viewModel.showsDeclineSheet = true
            }
            PrimaryButton(
                title: viewModel.isAccepting ? "Accepting" : "Accept \(fareLabel)",
                isLoading: viewModel.isAccepting,
                isEnabled: !viewModel.isAccepting,
                action: { Task { await viewModel.accept() } }
            )
        }
        .padding(Tokens.Space.md)
        .background(Tokens.Color.surface)
        .tokenShadow(Tokens.Shadow.raised)
        .accessibilityIdentifier("jobDetailStickyFooter")
    }

    private var declineStubSheet: some View {
        VStack(spacing: Tokens.Space.lg) {
            Text("Decline job")
                .font(Tokens.FontRole.titleL)
                .foregroundStyle(Tokens.Color.textPrimary)
            Text("Reason picker comes in Phase 9.")
                .font(Tokens.FontRole.label)
                .foregroundStyle(Tokens.Color.textSecondary)
                .multilineTextAlignment(.center)
            PrimaryButton(title: "Close") {
                viewModel.showsDeclineSheet = false
            }
        }
        .padding(Tokens.Space.xl)
        .presentationDetents([.medium])
    }

    private func routeRow(dotColor: Color, title: String, address: String) -> some View {
        HStack(alignment: .top, spacing: Tokens.Space.sm) {
            Circle()
                .fill(dotColor)
                .frame(width: 10, height: 10)
                .padding(.top, 6)
            VStack(alignment: .leading, spacing: Tokens.Space.xxs) {
                Text(title)
                    .font(Tokens.FontRole.caption)
                    .foregroundStyle(Tokens.Color.textSecondary)
                    .textCase(.uppercase)
                Text(address)
                    .font(Tokens.FontRole.label)
                    .foregroundStyle(Tokens.Color.textPrimary)
            }
            Spacer()
        }
    }

    private func errorBanner(message: String) -> some View {
        HStack(alignment: .top, spacing: Tokens.Space.sm) {
            Image(kilatAsset: "alert")
                .resizable()
                .renderingMode(.template)
                .frame(width: 18, height: 18)
                .foregroundStyle(Tokens.Color.destructive)
            Text(message)
                .font(Tokens.FontRole.label)
                .foregroundStyle(Tokens.Color.textPrimary)
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding(Tokens.Space.md)
        .background(Tokens.Color.surface, in: RoundedRectangle(cornerRadius: Tokens.Radius.md, style: .continuous))
    }

    private var fareLabel: String {
        let cents = viewModel.booking.finalPriceCents ?? viewModel.booking.estimatedPriceCents
        return "\(viewModel.booking.currency) \(String(format: "%.2f", Double(cents) / 100))"
    }

    private var estimatedAmount: Double {
        let cents = viewModel.booking.finalPriceCents ?? viewModel.booking.estimatedPriceCents
        return Double(cents) / 100
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
