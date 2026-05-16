import SwiftUI
import UIKit

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
            VStack(alignment: .leading, spacing: 22) {
                header
                statusPanel
                actionGrid
                if let errorMessage = viewModel.errorMessage {
                    permissionBanner(message: errorMessage)
                }
            }
            .padding(20)
        }
        .background(Color(.systemGroupedBackground))
        .navigationTitle("Dashboard")
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button {
                    session.logout()
                } label: {
                    Label("Log Out", systemImage: "rectangle.portrait.and.arrow.right")
                }
            }
        }
        .task {
            await viewModel.loadRunner()
        }
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
        VStack(alignment: .leading, spacing: 8) {
            Text(viewModel.runner?.fullName ?? "Runner")
                .font(.title.bold())
                .lineLimit(2)

            HStack(spacing: 10) {
                Label(viewModel.runner?.vehicleType.capitalized ?? "Vehicle", systemImage: "car.fill")
                Text(viewModel.runner?.vehiclePlate ?? "Pending")
            }
            .font(.subheadline)
            .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private var statusPanel: some View {
        VStack(alignment: .leading, spacing: 18) {
            HStack {
                VStack(alignment: .leading, spacing: 6) {
                    Text(viewModel.isOnline ? "Online" : "Offline")
                        .font(.title3.bold())
                    Text(viewModel.isOnline ? "Ready for nearby jobs" : "Not receiving jobs")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }

                Spacer()

                Image(systemName: viewModel.isOnline ? "bolt.circle.fill" : "pause.circle.fill")
                    .font(.system(size: 34, weight: .semibold))
                    .foregroundStyle(viewModel.isOnline ? .green : .secondary)
            }

            Button {
                if viewModel.isOnline {
                    Task { await viewModel.toggleOnline() }
                } else {
                    showsPermissionRationale = true
                }
            } label: {
                HStack {
                    if viewModel.isTogglingOnline {
                        ProgressView()
                    }
                    Label(
                        viewModel.isOnline ? "Go Offline" : "Go Online",
                        systemImage: viewModel.isOnline ? "pause.fill" : "play.fill"
                    )
                    .fontWeight(.semibold)
                }
                .frame(maxWidth: .infinity)
            }
            .buttonStyle(.borderedProminent)
            .controlSize(.large)
            .tint(viewModel.isOnline ? .red : .green)
            .disabled(viewModel.isTogglingOnline || viewModel.isLoading)
        }
        .padding(18)
        .background(Color(.secondarySystemGroupedBackground), in: RoundedRectangle(cornerRadius: 8))
    }

    private var actionGrid: some View {
        LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
            NavigationLink {
                ContentUnavailableView("Available Jobs", systemImage: "shippingbox")
            } label: {
                actionTile(title: "Jobs", subtitle: "Available", icon: "shippingbox.fill")
            }

            NavigationLink {
                ContentUnavailableView("Earnings", systemImage: "banknote")
            } label: {
                actionTile(title: "Earnings", subtitle: "\(viewModel.runner?.totalTrips ?? 0) trips", icon: "banknote.fill")
            }
        }
    }

    private func actionTile(title: String, subtitle: String, icon: String) -> some View {
        VStack(alignment: .leading, spacing: 14) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundStyle(.blue)
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.headline)
                    .foregroundStyle(.primary)
                Text(subtitle)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
        .frame(maxWidth: .infinity, minHeight: 104, alignment: .leading)
        .padding(16)
        .background(Color(.secondarySystemGroupedBackground), in: RoundedRectangle(cornerRadius: 8))
    }

    private func permissionBanner(message: String) -> some View {
        HStack(alignment: .top, spacing: 12) {
            Image(systemName: "exclamationmark.triangle.fill")
                .foregroundStyle(.orange)
            VStack(alignment: .leading, spacing: 8) {
                Text(message)
                    .font(.subheadline)
                    .foregroundStyle(.primary)
                    .fixedSize(horizontal: false, vertical: true)
                Button {
                    if let url = URL(string: UIApplication.openSettingsURLString) {
                        openURL(url)
                    }
                } label: {
                    Label("Open Settings", systemImage: "gear")
                }
                .buttonStyle(.borderless)
            }
        }
        .padding(14)
        .background(Color(.secondarySystemGroupedBackground), in: RoundedRectangle(cornerRadius: 8))
    }
}

#Preview {
    NavigationStack {
        DashboardView(viewModel: DashboardViewModel())
            .environment(AppSession())
    }
}
