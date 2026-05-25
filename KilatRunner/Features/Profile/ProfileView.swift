import SwiftUI
import KilatUI

struct ProfileView: View {
    @Environment(AppSession.self) private var session
    @Bindable private var viewModel: ProfileViewModel

    init(viewModel: ProfileViewModel = ProfileViewModel()) {
        self.viewModel = viewModel
    }

    var body: some View {
        ScrollView {
            VStack(spacing: Tokens.Space.lg) {
                if let state = viewModel.state {
                    header(state)
                    stats(state)
                    infoRows(state)
                    tierCard(state)
                    navigationRows
                } else if viewModel.isLoading {
                    ProgressView()
                        .padding(.top, Tokens.Space.xxxl)
                } else if let errorMessage = viewModel.errorMessage {
                    Text(errorMessage)
                        .font(Tokens.FontRole.label)
                        .foregroundStyle(Tokens.Color.destructive)
                        .padding(Tokens.Space.lg)
                }
            }
            .padding(Tokens.Space.lg)
        }
        .background(Tokens.Color.background.ignoresSafeArea())
        .navigationTitle("Profile")
        .navigationBarTitleDisplayMode(.inline)
        .task {
            if viewModel.state == nil {
                await viewModel.load()
            }
        }
    }

    private func header(_ state: ProfileViewState) -> some View {
        VStack(spacing: Tokens.Space.sm) {
            Avatar(name: state.profile.fullName, size: 84)
            Text(state.profile.fullName)
                .font(Tokens.FontRole.titleL)
                .foregroundStyle(Tokens.Color.textPrimary)
            HStack(spacing: Tokens.Space.xs) {
                Text(state.tier.tier.displayName)
                    .font(Tokens.FontRole.caption)
                    .foregroundStyle(Tokens.Color.primary)
                    .padding(.horizontal, Tokens.Space.sm)
                    .padding(.vertical, Tokens.Space.xxs)
                    .background(Tokens.Color.primaryTonal, in: Capsule())
                Text(String(format: "%.2f star", state.profile.ratingAverage))
                    .font(Tokens.FontRole.label)
                    .foregroundStyle(Tokens.Color.textSecondary)
            }
        }
        .frame(maxWidth: .infinity)
    }

    private func stats(_ state: ProfileViewState) -> some View {
        HStack(spacing: Tokens.Space.sm) {
            MetricTile(label: "Deliveries", value: "\(state.profile.deliveries)")
            MetricTile(label: "On-time", value: percent(state.profile.onTimeRate))
            MetricTile(label: "Accept", value: percent(state.profile.acceptanceRate))
        }
    }

    private func infoRows(_ state: ProfileViewState) -> some View {
        VStack(spacing: 0) {
            infoRow("Phone", state.profile.phone)
            infoRow("Vehicle", [state.profile.vehicleType, state.profile.vehiclePlate].compactMap { $0 }.joined(separator: " · "))
            verificationRow("IC verified", verified: state.profile.identityVerified)
            verificationRow("License verified", verified: state.profile.licenseVerified)
        }
        .background(Tokens.Color.surface, in: RoundedRectangle(cornerRadius: Tokens.Radius.lg, style: .continuous))
    }

    private func tierCard(_ state: ProfileViewState) -> some View {
        VStack(alignment: .leading, spacing: Tokens.Space.sm) {
            HStack {
                Text("Tier progress")
                    .font(Tokens.FontRole.titleM)
                    .foregroundStyle(Tokens.Color.textPrimary)
                Spacer()
                Text(state.tier.tier.nextTierName)
                    .font(Tokens.FontRole.caption)
                    .foregroundStyle(Tokens.Color.textSecondary)
            }
            ProgressBar(progress: state.tierProgress)
            Text("\(state.tier.deliveries30D) of \(state.tier.tier.progressTarget) deliveries this month")
                .font(Tokens.FontRole.caption)
                .foregroundStyle(Tokens.Color.textSecondary)
        }
        .padding(Tokens.Space.md)
        .background(Tokens.Color.surface, in: RoundedRectangle(cornerRadius: Tokens.Radius.lg, style: .continuous))
    }

    private var navigationRows: some View {
        VStack(spacing: 0) {
            NavigationLink(value: AuthenticatedRoute.settings) { navRow("Settings", icon: "sliders") }
            NavigationLink(value: AuthenticatedRoute.support) { navRow("Support", icon: "message") }
            NavigationLink(value: AuthenticatedRoute.bankAccounts) { navRow("Bank accounts", icon: "wallet") }
            NavigationLink(value: AuthenticatedRoute.documents) { navRow("Documents", icon: "card") }
            Button {
                session.logout()
            } label: {
                navRow("Sign out", icon: "xmark", destructive: true)
            }
        }
        .buttonStyle(.plain)
        .background(Tokens.Color.surface, in: RoundedRectangle(cornerRadius: Tokens.Radius.lg, style: .continuous))
    }

    private func infoRow(_ title: String, _ value: String) -> some View {
        HStack {
            Text(title)
                .font(Tokens.FontRole.label)
                .foregroundStyle(Tokens.Color.textSecondary)
            Spacer()
            Text(value.isEmpty ? "Not set" : value)
                .font(Tokens.FontRole.label)
                .foregroundStyle(Tokens.Color.textPrimary)
        }
        .padding(Tokens.Space.md)
    }

    private func verificationRow(_ title: String, verified: Bool) -> some View {
        HStack {
            Text(title)
                .font(Tokens.FontRole.label)
                .foregroundStyle(Tokens.Color.textSecondary)
            Spacer()
            Text(verified ? "Verified" : "Pending")
                .font(Tokens.FontRole.caption)
                .foregroundStyle(verified ? Tokens.Color.online : Tokens.Color.textSecondary)
                .padding(.horizontal, Tokens.Space.sm)
                .padding(.vertical, Tokens.Space.xxs)
                .background(Tokens.Color.surfaceMuted, in: Capsule())
        }
        .padding(Tokens.Space.md)
    }

    private func navRow(_ title: String, icon: String, destructive: Bool = false) -> some View {
        HStack(spacing: Tokens.Space.sm) {
            Image(kilatAsset: icon)
                .resizable()
                .renderingMode(.template)
                .frame(width: 20, height: 20)
            Text(title)
                .font(Tokens.FontRole.label)
            Spacer()
            Image(kilatAsset: "chevron-right")
                .resizable()
                .renderingMode(.template)
                .frame(width: 16, height: 16)
                .opacity(destructive ? 0 : 1)
        }
        .foregroundStyle(destructive ? Tokens.Color.destructive : Tokens.Color.textPrimary)
        .padding(Tokens.Space.md)
    }

    private func percent(_ value: Double) -> String {
        "\(Int((value * 100).rounded()))%"
    }
}
