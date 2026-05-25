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
    @AppStorage("permissions.completed") private var permissionsCompleted = false
    @State private var dashboardViewModel = DashboardViewModel()
    @State private var coachMarksState = CoachMarksState()

    var body: some View {
        NavigationStack {
            DashboardView(viewModel: dashboardViewModel)
                .overlay {
                    CoachMarksOverlay(state: coachMarksState)
                }
                .navigationDestination(for: AuthenticatedRoute.self) { route in
                    destination(for: route)
                }
        }
        .preferredColorScheme(session.colorSchemeOverride)
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
            Text("Bank accounts")
                .navigationTitle("Bank accounts")
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
        }
    }
}

#Preview {
    RootView()
        .environment(AppSession())
}

#Preview("KilatUI smoke") {
    PrimaryButton(title: "Sign in") {}
        .padding()
}
