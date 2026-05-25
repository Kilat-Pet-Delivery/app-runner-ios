import MapKit
import SwiftUI
import KilatUI

struct ActiveDeliveryView: View {
    @Bindable private var viewModel: ActiveDeliveryViewModel
    @Bindable private var reachability: NetworkReachability
    private let onBackToDashboard: () -> Void
    @State private var chatPresentation: ChatPresentation?
    @State private var incidentPresentation: IncidentPresentation?
    @State private var showsCancelSheet = false

    @MainActor
    init(
        viewModel: ActiveDeliveryViewModel,
        onBackToDashboard: @escaping () -> Void = {}
    ) {
        self.init(
            viewModel: viewModel,
            reachability: NetworkReachability.shared,
            onBackToDashboard: onBackToDashboard
        )
    }

    init(
        viewModel: ActiveDeliveryViewModel,
        reachability: NetworkReachability,
        onBackToDashboard: @escaping () -> Void = {}
    ) {
        self.viewModel = viewModel
        self.reachability = reachability
        self.onBackToDashboard = onBackToDashboard
    }

    private struct ChatPresentation: Identifiable {
        let id: String
        let viewModel: ChatViewModel
        let participantName: String
    }

    private enum IncidentPresentation: Identifiable {
        case report
        case sos

        var id: String {
            switch self {
            case .report: return "report"
            case .sos: return "sos"
            }
        }
    }

    var body: some View {
        ZStack(alignment: .bottom) {
            map.ignoresSafeArea()

            VStack(spacing: 0) {
                Spacer()
                bottomSheet
            }

            if viewModel.presentationStage == .complete {
                tripCompleteOverlay
            }
        }
        .navigationTitle("Active delivery")
        .navigationBarTitleDisplayMode(.inline)
        .safeAreaInset(edge: .top, spacing: 0) {
            OfflineBannerView(reachability: reachability) {
                await viewModel.queuedWaypointCount()
            }
        }
        .onAppear { viewModel.onAppear() }
        .onDisappear { Task { await viewModel.onDisappear() } }
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                alertButton
            }
        }
        .sheet(item: $chatPresentation) { presentation in
            NavigationStack {
                ChatThreadView(viewModel: presentation.viewModel, participantName: presentation.participantName)
                    .navigationTitle(presentation.participantName)
                    .toolbar {
                        ToolbarItem(placement: .topBarTrailing) {
                            Button("Done") { chatPresentation = nil }
                        }
                    }
            }
        }
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
        .sheet(isPresented: $showsCancelSheet) {
            CancelActiveDeliverySheet(
                viewModel: CancelActiveViewModel(bookingID: viewModel.booking.id),
                onClose: { showsCancelSheet = false },
                onSOS: {
                    showsCancelSheet = false
                    incidentPresentation = .sos
                }
            )
            .presentationDetents([.large])
        }
        .fullScreenCover(item: $incidentPresentation) { presentation in
            NavigationStack {
                switch presentation {
                case .report:
                    ReportProblemView(
                        viewModel: ReportProblemViewModel(bookingID: viewModel.booking.id),
                        onSOS: { incidentPresentation = .sos },
                        onDone: { incidentPresentation = nil }
                    )
                    .toolbar {
                        ToolbarItem(placement: .topBarLeading) {
                            Button("Done") { incidentPresentation = nil }
                        }
                    }
                case .sos:
                    SOSView(
                        viewModel: SOSViewModel(bookingID: viewModel.booking.id),
                        onClose: { incidentPresentation = nil }
                    )
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

    private var alertButton: some View {
        Button {
            incidentPresentation = .report
        } label: {
            Image(systemName: "exclamationmark.triangle.fill")
                .foregroundStyle(Tokens.Color.destructive)
        }
        .simultaneousGesture(
            LongPressGesture(minimumDuration: 1)
                .onEnded { _ in incidentPresentation = .sos }
        )
        .accessibilityLabel("Report problem")
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

            if showsDefaultRouteContent {
                customerContactRow

                VStack(alignment: .leading, spacing: Tokens.Space.xs) {
                    routeRow(dotColor: Tokens.Color.online,
                             label: "Pickup",
                             address: viewModel.booking.pickupAddress.singleLineLabel)
                    if isLivePetBooking {
                        NavigationLink {
                            PetProfileView(viewModel: PetProfileViewModel(bookingID: viewModel.booking.id))
                        } label: {
                            routeRow(dotColor: Tokens.Color.destructive,
                                     label: "Drop-off",
                                     address: viewModel.booking.dropoffAddress.singleLineLabel)
                        }
                        .buttonStyle(.plain)
                    } else {
                        routeRow(dotColor: Tokens.Color.destructive,
                                 label: "Drop-off",
                                 address: viewModel.booking.dropoffAddress.singleLineLabel)
                    }
                }
            }

            if let errorMessage = viewModel.errorMessage {
                errorBanner(message: errorMessage)
            }

            stageContent
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
            Button {
                presentChat()
            } label: {
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

    @ViewBuilder private var stageContent: some View {
        switch viewModel.presentationStage {
        case .arrivedAtPickup:
            ArrivedAtPickupView(
                vendorName: viewModel.booking.pickupAddress.line1,
                orderID: viewModel.booking.bookingNumber,
                isLoading: viewModel.isMarkingPickup,
                onConfirmPickup: { Task { await viewModel.markPickedUp() } },
                onItemMissing: { viewModel.errorMessage = "Contact support to report a missing item." }
            )
        case .arrivedAtDropoff:
            ProofOfDeliveryView(
                viewModel: ProofOfDeliveryViewModel { proof in
                    try await viewModel.submitProofOfDelivery(proof)
                },
                isLivePet: isLivePetBooking
            )
        case .proofSubmitted:
            DeliveryCompleteView(
                viewModel: DeliveryCompleteViewModel { request in
                    try await viewModel.submitCustomerRatingAndComplete(request)
                },
                fareLabel: fareLabel,
                onDone: onBackToDashboard,
                onViewEarnings: onBackToDashboard
            )
        case .complete:
            PrimaryButton(title: "Back to dashboard", icon: "house.fill", action: onBackToDashboard)
        default:
            VStack(spacing: Tokens.Space.sm) {
                PrimaryButton(
                    title: stageCtaTitle,
                    icon: stageCtaIcon,
                    isLoading: viewModel.isMarkingPickup || viewModel.isMarkingDelivered,
                    isEnabled: stageCtaEnabled,
                    action: stageCtaAction
                )
                .accessibilityIdentifier("activeDeliveryCTA")

                SecondaryButton(
                    title: "Cancel delivery",
                    icon: "xmark.circle.fill",
                    action: { showsCancelSheet = true }
                )
            }
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
        case .toPickup:          return "Heading to pickup"
        case .arrivedAtPickup:   return "Arrived at pickup"
        case .pickedUp:          return "Picked up"
        case .toDropoff:         return "Heading to drop-off"
        case .arrivedAtDropoff:  return "Arrived at drop-off"
        case .proofSubmitted:    return "Proof submitted"
        case .complete:          return "Delivered"
        }
    }

    private var stageCtaTitle: String {
        switch viewModel.presentationStage {
        case .toPickup:          return "I have arrived"
        case .arrivedAtPickup:   return "Picked up"
        case .pickedUp:          return "Continue"
        case .toDropoff:         return "I have arrived"
        case .arrivedAtDropoff:  return "Submit proof"
        case .proofSubmitted:    return "Complete delivery"
        case .complete:          return "Back to dashboard"
        }
    }

    private var stageCtaIcon: String? {
        switch viewModel.presentationStage {
        case .toPickup, .toDropoff: return "mappin.circle.fill"
        case .arrivedAtPickup:      return "shippingbox.fill"
        case .pickedUp:             return "arrow.right.circle.fill"
        case .arrivedAtDropoff:     return "checkmark.seal.fill"
        case .proofSubmitted:       return "checkmark.circle.fill"
        case .complete:             return "house.fill"
        }
    }

    private var stageCtaEnabled: Bool {
        switch viewModel.presentationStage {
        case .toPickup, .toDropoff: return !viewModel.isMarkingPickup && !viewModel.isMarkingDelivered
        case .arrivedAtPickup:      return !viewModel.isMarkingPickup
        case .pickedUp:             return true
        case .arrivedAtDropoff:     return !viewModel.isSubmittingProof
        case .proofSubmitted:       return !viewModel.isCompletingDelivery
        case .complete:             return true
        }
    }

    private var stageCtaAction: () -> Void {
        switch viewModel.presentationStage {
        case .toPickup:
            return { Task { await viewModel.arriveAtPickup() } }
        case .toDropoff:
            return { Task { await viewModel.arriveAtDropoff() } }
        case .arrivedAtPickup:
            return { Task { await viewModel.markPickedUp() } }
        case .pickedUp:
            return {}
        case .arrivedAtDropoff:
            return {}
        case .proofSubmitted:
            return { Task { _ = await viewModel.completeDelivery() } }
        case .complete:
            return onBackToDashboard
        }
    }

    private var showsDefaultRouteContent: Bool {
        switch viewModel.presentationStage {
        case .arrivedAtPickup, .arrivedAtDropoff, .proofSubmitted:
            return false
        default:
            return true
        }
    }

    private var fareLabel: String {
        let cents = viewModel.booking.finalPriceCents ?? viewModel.booking.estimatedPriceCents
        return "\(viewModel.booking.currency) \(String(format: "%.2f", Double(cents) / 100))"
    }

    private var isLivePetBooking: Bool {
        !viewModel.booking.petSpec.petType.isEmpty && viewModel.booking.petSpec.petType.lowercased() != "supplies"
    }

    private func presentChat() {
        let booking = viewModel.booking
        let selfUserID = booking.runnerId ?? ""
        let chatViewModel = ChatViewModel(
            threadID: booking.id,
            selfUserID: selfUserID,
            remoteUserID: booking.ownerId
        )
        let participantName = booking.petSpec.name.isEmpty ? "Customer" : "\(booking.petSpec.name)'s owner"
        chatPresentation = ChatPresentation(
            id: booking.id,
            viewModel: chatViewModel,
            participantName: participantName
        )
    }
}
