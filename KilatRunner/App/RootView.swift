import SwiftUI

struct RootView: View {
    @Environment(AppSession.self) private var session

    var body: some View {
        switch session.state {
        case .unauthenticated:
            ContentUnavailableView(
                "Login screen placeholder",
                systemImage: "lock",
                description: Text("Phase 2 wires the real login flow.")
            )
        case .authenticated:
            ContentUnavailableView(
                "Authenticated home placeholder",
                systemImage: "bolt.car",
                description: Text("Phase 3 wires the dashboard.")
            )
        }
    }
}

#Preview {
    RootView()
        .environment(AppSession())
}
