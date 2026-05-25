import SwiftUI
import KilatUI

struct OfflineBannerView: View {
    @Bindable private var reachability: NetworkReachability
    private let queuedCountProvider: () async -> Int
    @State private var queuedWaypointCount = 0
    @State private var showsOfflineView = false

    init(
        reachability: NetworkReachability,
        queuedCountProvider: @escaping () async -> Int = { 0 }
    ) {
        self.reachability = reachability
        self.queuedCountProvider = queuedCountProvider
    }

    var body: some View {
        if reachability.isOffline {
            Button {
                showsOfflineView = true
            } label: {
                HStack(spacing: Tokens.Space.sm) {
                    Image(systemName: "wifi.slash")
                        .imageScale(.medium)
                    Text("You're offline")
                        .font(Tokens.FontRole.label)
                    Spacer()
                    if queuedWaypointCount > 0 {
                        Text("\(queuedWaypointCount) queued")
                            .font(Tokens.FontRole.caption)
                            .padding(.horizontal, Tokens.Space.xs)
                            .padding(.vertical, 3)
                            .background(.white.opacity(0.2), in: Capsule())
                    }
                    Image(systemName: "chevron.right")
                        .font(.caption)
                }
                .foregroundStyle(.white)
                .padding(.horizontal, Tokens.Space.md)
                .padding(.vertical, Tokens.Space.xs)
                .frame(maxWidth: .infinity)
                .background(Tokens.Color.destructive)
            }
            .buttonStyle(.plain)
            .accessibilityIdentifier("offlineBanner")
            .task(id: reachability.status) {
                queuedWaypointCount = await queuedCountProvider()
            }
            .fullScreenCover(isPresented: $showsOfflineView) {
                NavigationStack {
                    OfflineView(
                        viewModel: OfflineViewModel(
                            queuedWaypointCount: queuedWaypointCount,
                            queuedCountProvider: queuedCountProvider
                        )
                    )
                }
            }
        }
    }
}
