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
    @State private var dashboardViewModel = DashboardViewModel()

    var body: some View {
        NavigationStack {
            DashboardView(viewModel: dashboardViewModel)
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
