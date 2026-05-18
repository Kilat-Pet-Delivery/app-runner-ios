import SwiftUI
import UIKit
import KilatUI

struct DashboardView: View {
    @Environment(AppSession.self) private var session
    @Environment(\.openURL) private var openURL
    @Bindable private var viewModel: DashboardViewModel
    @State private var showsPermissionRationale = false

    init(viewModel: DashboardViewModel) {
        self.viewModel = viewModel
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: Tokens.Space.lg) {
                header
                statusPanel
                heroEarnings
                statsRow
                if viewModel.activeJob != nil {
                    activeJobCard
                }
                weeklyGoal
                actionGrid
                if let errorMessage = viewModel.errorMessage {
                    permissionBanner(message: errorMessage)
                }
            }
            .padding(Tokens.Space.lg)
        }
        .background(Tokens.Color.background.ignoresSafeArea())
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarLeading) {
                NavigationLink {
                    NotificationsInboxView(viewModel: NotificationsViewModel())
                } label: {
                    Image(kilatAsset: "bell")
                        .resizable()
                        .renderingMode(.template)
                        .frame(width: 22, height: 22)
                        .foregroundStyle(Tokens.Color.textPrimary)
                }
                .accessibilityLabel("Notifications")
                .accessibilityIdentifier("notificationsBell")
            }
            ToolbarItem(placement: .topBarTrailing) {
                Button { session.logout() } label: {
                    Label("Log Out", systemImage: "rectangle.portrait.and.arrow.right")
                        .foregroundStyle(Tokens.Color.textPrimary)
                }
            }
        }
        .task { await viewModel.loadRunner() }
        .sheet(isPresented: $showsPermissionRationale) {
            PermissionRationaleSheet {
                showsPermissionRationale = false
                Task { await viewModel.toggleOnline() }
            } onCancel: {
                showsPermissionRationale = false
            }
        }
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: Tokens.Space.xxs) {
            Text(viewModel.runner?.fullName ?? "Runner")
                .font(Tokens.FontRole.titleL)
                .foregroundStyle(Tokens.Color.textPrimary)
                .lineLimit(2)

            HStack(spacing: Tokens.Space.xs) {
                Image(kilatAsset: "scooter")
                    .resizable()
                    .renderingMode(.template)
                    .frame(width: 16, height: 16)
                Text(viewModel.runner?.vehicleType.capitalized ?? "Vehicle")
                Text("·")
                Text(viewModel.runner?.vehiclePlate ?? "Pending")
            }
            .font(Tokens.FontRole.label)
            .foregroundStyle(Tokens.Color.textSecondary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private var statusPanel: some View {
        VStack(alignment: .leading, spacing: Tokens.Space.md) {
            HStack(alignment: .center) {
                VStack(alignment: .leading, spacing: Tokens.Space.xxs) {
                    Text(viewModel.isOnline ? "Online" : "Offline")
                        .font(Tokens.FontRole.titleM)
                        .foregroundStyle(Tokens.Color.textPrimary)
                    Text(viewModel.isOnline ? "Ready for nearby jobs" : "Not receiving jobs")
                        .font(Tokens.FontRole.label)
                        .foregroundStyle(Tokens.Color.textSecondary)
                }
                Spacer()
                StatusBadge(status: viewModel.isOnline ? .online : .offline, pulses: viewModel.isOnline)
            }

            PrimaryButton(
                title: viewModel.isOnline ? "Go offline" : "Go online",
                icon: viewModel.isOnline ? "pause.fill" : "play.fill",
                variant: viewModel.isOnline ? .destructive : .primary,
                isLoading: viewModel.isTogglingOnline,
                isEnabled: !viewModel.isLoading,
                action: {
                    if viewModel.isOnline {
                        Task { await viewModel.toggleOnline() }
                    } else {
                        showsPermissionRationale = true
                    }
                }
            )
        }
        .padding(Tokens.Space.lg)
        .background(Tokens.Color.surface, in: RoundedRectangle(cornerRadius: Tokens.Radius.lg, style: .continuous))
        .tokenShadow(Tokens.Shadow.card)
    }

    private var heroEarnings: some View {
        MetricTile(
            label: "This week",
            value: formatRM(viewModel.weeklyEarningsCents),
            caption: "Goal: \(formatRM(viewModel.weeklyGoalCents))",
            variant: .emphasis
        )
    }

    private var statsRow: some View {
        HStack(spacing: Tokens.Space.md) {
            MetricTile(label: "Deliveries", value: "\(viewModel.deliveriesThisWeek)")
            MetricTile(label: "Online time", value: formatMinutes(viewModel.onlineMinutesThisWeek))
        }
    }

    private var activeJobCard: some View {
        let job = viewModel.activeJob!
        return VStack(alignment: .leading, spacing: Tokens.Space.sm) {
            HStack {
                Text("ACTIVE DELIVERY")
                    .font(Tokens.FontRole.caption)
                    .foregroundStyle(Tokens.Color.onPrimaryTonal)
                Spacer()
                StatusBadge(status: .inTransit)
            }
            Text(job.pickupAddress)
                .font(Tokens.FontRole.titleM)
                .foregroundStyle(Tokens.Color.onPrimaryTonal)
                .lineLimit(2)
            Text("→ \(job.dropoffAddress)")
                .font(Tokens.FontRole.label)
                .foregroundStyle(Tokens.Color.onPrimaryTonal.opacity(0.85))
                .lineLimit(2)
        }
        .padding(Tokens.Space.lg)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Tokens.Color.primaryTonal, in: RoundedRectangle(cornerRadius: Tokens.Radius.lg, style: .continuous))
        .accessibilityIdentifier("activeJobCard")
    }

    private var weeklyGoal: some View {
        VStack(alignment: .leading, spacing: Tokens.Space.xs) {
            HStack {
                Text("Weekly goal")
                    .font(Tokens.FontRole.caption)
                    .foregroundStyle(Tokens.Color.textSecondary)
                    .textCase(.uppercase)
                Spacer()
                Text("\(Int(viewModel.weeklyGoalProgress * 100))%")
                    .font(Tokens.FontRole.caption)
                    .foregroundStyle(Tokens.Color.textSecondary)
            }
            ProgressView(value: viewModel.weeklyGoalProgress)
                .tint(Tokens.Color.primary)
        }
        .padding(Tokens.Space.md)
        .background(Tokens.Color.surface, in: RoundedRectangle(cornerRadius: Tokens.Radius.md, style: .continuous))
    }

    private var actionGrid: some View {
        LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: Tokens.Space.sm) {
            NavigationLink {
                AvailableJobsView(viewModel: AvailableJobsViewModel())
            } label: {
                actionTile(title: "Jobs", subtitle: "Available", icon: "box")
            }

            NavigationLink {
                EarningsView(viewModel: EarningsViewModel())
            } label: {
                actionTile(title: "Earnings", subtitle: "\(viewModel.runner?.totalTrips ?? 0) trips", icon: "wallet")
            }
        }
    }

    private func actionTile(title: String, subtitle: String, icon: String) -> some View {
        VStack(alignment: .leading, spacing: Tokens.Space.sm) {
            Image(kilatAsset: icon)
                .resizable()
                .renderingMode(.template)
                .frame(width: 26, height: 26)
                .foregroundStyle(Tokens.Color.primary)
            VStack(alignment: .leading, spacing: Tokens.Space.xxs) {
                Text(title)
                    .font(Tokens.FontRole.titleM)
                    .foregroundStyle(Tokens.Color.textPrimary)
                Text(subtitle)
                    .font(Tokens.FontRole.caption)
                    .foregroundStyle(Tokens.Color.textSecondary)
            }
        }
        .frame(maxWidth: .infinity, minHeight: 104, alignment: .leading)
        .padding(Tokens.Space.md)
        .background(Tokens.Color.surface, in: RoundedRectangle(cornerRadius: Tokens.Radius.lg, style: .continuous))
        .tokenShadow(Tokens.Shadow.card)
    }

    private func permissionBanner(message: String) -> some View {
        HStack(alignment: .top, spacing: Tokens.Space.sm) {
            Image(kilatAsset: "alert")
                .resizable()
                .renderingMode(.template)
                .frame(width: 22, height: 22)
                .foregroundStyle(Tokens.Color.destructive)
            VStack(alignment: .leading, spacing: Tokens.Space.xs) {
                Text(message)
                    .font(Tokens.FontRole.label)
                    .foregroundStyle(Tokens.Color.textPrimary)
                    .fixedSize(horizontal: false, vertical: true)
                Button {
                    if let url = URL(string: UIApplication.openSettingsURLString) {
                        openURL(url)
                    }
                } label: {
                    Text("Open Settings")
                        .font(Tokens.FontRole.label)
                        .foregroundStyle(Tokens.Color.primary)
                }
            }
        }
        .padding(Tokens.Space.md)
        .background(Tokens.Color.surface, in: RoundedRectangle(cornerRadius: Tokens.Radius.md, style: .continuous))
    }

    private func formatRM(_ cents: Int) -> String {
        let value = Double(cents) / 100.0
        return String(format: "RM %.2f", value)
    }

    private func formatMinutes(_ minutes: Int) -> String {
        let hours = minutes / 60
        let mins = minutes % 60
        return "\(hours)h \(mins)m"
    }
}

#Preview("Dashboard (offline)") {
    NavigationStack {
        DashboardView(viewModel: DashboardViewModel())
            .environment(AppSession())
    }
}

#Preview("Dashboard (online, active)") {
    NavigationStack {
        DashboardView(viewModel: {
            let vm = DashboardViewModel()
            vm.isOnline = true
            vm.weeklyEarningsCents = 23_400
            vm.deliveriesThisWeek = 11
            vm.onlineMinutesThisWeek = 312
            vm.activeJob = DashboardActiveJob(
                bookingId: "abc",
                pickupAddress: "Pet Haven · Bangsar",
                dropoffAddress: "Mont Kiara · 12 Jalan 23"
            )
            return vm
        }())
        .environment(AppSession())
    }
}
