import SwiftUI
import KilatUI

struct RootView: View {
    @Environment(AppSession.self) private var session

    var body: some View {
        switch session.state {
        case .unauthenticated:
            LoginView(viewModel: LoginViewModel(appSession: session))
        case .authenticated:
            AuthenticatedRootView()
        }
    }
}

private struct AuthenticatedRootView: View {
    @Environment(AppSession.self) private var session
    @Environment(DeepLinkRouter.self) private var deepLinkRouter
    @AppStorage("permissions.completed") private var permissionsCompleted = false
    @State private var dashboardViewModel = DashboardViewModel()
    @State private var coachMarksState = CoachMarksState()
    @State private var navigationPath: [AuthenticatedRoute] = []
    @State private var tipPresentation: TipPresentation?
    @State private var tierPresentation: TierPromotionPresentation?

    private struct TipPresentation: Identifiable {
        let id = UUID()
        let payload: TipReceivedPayload
    }

    private struct TierPromotionPresentation: Identifiable {
        let id = UUID()
        let tier: String
    }

    var body: some View {
        NavigationStack(path: $navigationPath) {
            DashboardView(viewModel: dashboardViewModel)
                .overlay {
                    CoachMarksOverlay(state: coachMarksState)
                }
                .navigationDestination(for: AuthenticatedRoute.self) { route in
                    destination(for: route)
                }
        }
        .preferredColorScheme(session.colorSchemeOverride)
        .task {
            PushNotificationService.shared.registerForRemoteNotifications()
            handlePendingDeepLink()
        }
        .onChange(of: deepLinkRouter.pendingIntent) { _, _ in
            handlePendingDeepLink()
        }
        .fullScreenCover(isPresented: Binding(
            get: { !permissionsCompleted },
            set: { dismissed in
                if !dismissed { permissionsCompleted = true }
            }
        )) {
            PermissionsView(viewModel: PermissionsViewModel()) {
                permissionsCompleted = true
            }
        }
        .sheet(item: $tipPresentation) { presentation in
            NavigationStack {
                TipReceivedSheet(
                    viewModel: TipReceivedViewModel(payload: presentation.payload),
                    onClose: { tipPresentation = nil }
                )
                .presentationDetents([.medium])
            }
        }
        .sheet(item: $tierPresentation) { presentation in
            tierPromotionSheet(tier: presentation.tier)
        }
    }

    @ViewBuilder
    private func destination(for route: AuthenticatedRoute) -> some View {
        switch route {
        case .profile:
            ProfileView()
        case .settings:
            SettingsView(session: session)
        case .support:
            SupportView()
        case .notifications:
            NotificationsInboxView(viewModel: NotificationsViewModel())
        case let .chat(threadID):
            ChatThreadView(
                viewModel: ChatViewModel(
                    threadID: threadID,
                    selfUserID: "runner",
                    remoteUserID: "support"
                ),
                participantName: "Support"
            )
        case .bankAccounts:
            BankAccountsView(viewModel: BankAccountsViewModel())
        case .documents:
            Text("Documents")
                .navigationTitle("Documents")
        case .jobHistory:
            JobHistoryView(viewModel: JobHistoryViewModel())
        case .scheduledJobs:
            ScheduledJobsView(viewModel: ScheduledJobsViewModel())
        case .quests:
            QuestsView(viewModel: QuestsViewModel())
        case .hotZones:
            HotZonesView(viewModel: HotZonesViewModel())
        case .performance:
            PerformanceView(viewModel: PerformanceViewModel())
        case .reviews:
            ReviewsView(viewModel: ReviewsViewModel())
        case .referFriend:
            ReferFriendView(viewModel: ReferFriendViewModel())
        case let .proofRequired(bookingID):
            ProofRequiredRouteView(bookingID: bookingID)
        }
    }

    private func handlePendingDeepLink() {
        guard let intent = deepLinkRouter.consume() else { return }
        switch intent {
        case let .chatMessage(threadID):
            navigationPath.append(.chat(threadID: threadID))
        case let .tipReceived(payload):
            tipPresentation = TipPresentation(payload: payload)
        case .sosAcknowledged:
            navigationPath.append(.notifications)
        case .incidentAssigned:
            return
        case .questCompleted:
            navigationPath.append(.quests)
        case let .tierPromoted(tier):
            tierPresentation = TierPromotionPresentation(tier: tier)
        case .surgeActive:
            navigationPath.append(.hotZones)
        case let .proofRequired(bookingID):
            navigationPath.append(.proofRequired(bookingID: bookingID))
        }
    }

    private func tierPromotionSheet(tier: String) -> some View {
        VStack(spacing: Tokens.Space.lg) {
            AnimatedCheckmark(color: Tokens.Color.online)
                .frame(width: 88, height: 88)
            Text("\(tier.capitalized) unlocked")
                .font(Tokens.FontRole.displayL)
                .foregroundStyle(Tokens.Color.textPrimary)
            Text("Your latest runner tier is ready in Performance.")
                .font(Tokens.FontRole.label)
                .foregroundStyle(Tokens.Color.textSecondary)
                .multilineTextAlignment(.center)
            PrimaryButton(title: "View performance", icon: "chart.bar.fill") {
                tierPresentation = nil
                navigationPath.append(.performance)
            }
            SecondaryButton(title: "Close") {
                tierPresentation = nil
            }
        }
        .padding(Tokens.Space.xl)
        .background(Tokens.Color.surface)
    }
}

private struct ProofRequiredRouteView: View {
    let bookingID: String
    @State private var viewModel: ActiveDeliveryViewModel?
    @State private var errorMessage: String?

    var body: some View {
        Group {
            if let viewModel {
                ActiveDeliveryView(viewModel: viewModel)
            } else if let errorMessage {
                VStack(spacing: Tokens.Space.md) {
                    Image(systemName: "doc.badge.exclamationmark")
                        .font(.largeTitle)
                        .foregroundStyle(Tokens.Color.destructive)
                    Text("Could not open proof request")
                        .font(Tokens.FontRole.titleM)
                        .foregroundStyle(Tokens.Color.textPrimary)
                    Text(errorMessage)
                        .font(Tokens.FontRole.label)
                        .foregroundStyle(Tokens.Color.textSecondary)
                        .multilineTextAlignment(.center)
                }
                .padding(Tokens.Space.xl)
            } else {
                ProgressView("Opening proof request")
                    .tint(Tokens.Color.primary)
            }
        }
        .task {
            guard viewModel == nil, errorMessage == nil else { return }
            do {
                let booking = try await BookingRepository().get(id: bookingID)
                let activeViewModel = ActiveDeliveryViewModel(booking: booking)
                activeViewModel.deliveryPhase = .pickedUp
                activeViewModel.hasArrivedAtCurrentWaypoint = true
                viewModel = activeViewModel
            } catch let error as NetworkError {
                errorMessage = error.userMessage
            } catch {
                errorMessage = NetworkError.unknown(error.localizedDescription).userMessage
            }
        }
    }
}

#Preview {
    RootView()
        .environment(AppSession())
        .environment(DeepLinkRouter())
}

#Preview("KilatUI smoke") {
    PrimaryButton(title: "Sign in") {}
        .padding()
}
