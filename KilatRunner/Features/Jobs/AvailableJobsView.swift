import SwiftUI
import KilatUI

struct AvailableJobsView: View {
    @Bindable private var viewModel: AvailableJobsViewModel
    @Bindable private var reachability: NetworkReachability

    @MainActor
    init(viewModel: AvailableJobsViewModel) {
        self.init(viewModel: viewModel, reachability: NetworkReachability.shared)
    }

    init(viewModel: AvailableJobsViewModel, reachability: NetworkReachability) {
        self.viewModel = viewModel
        self.reachability = reachability
    }

    var body: some View {
        VStack(spacing: 0) {
            sortPills
                .padding(.horizontal, Tokens.Space.md)
                .padding(.top, Tokens.Space.sm)

            content
        }
        .background(Tokens.Color.background.ignoresSafeArea())
        .navigationTitle("Available jobs")
        .navigationBarTitleDisplayMode(.inline)
        .safeAreaInset(edge: .top, spacing: 0) {
            OfflineBannerView(reachability: reachability)
        }
        .refreshable { await viewModel.refresh() }
        .task { await viewModel.load() }
    }

    @ViewBuilder
    private var content: some View {
        if viewModel.isLoading && viewModel.jobs.isEmpty {
            VStack {
                ProgressView()
                    .tint(Tokens.Color.primary)
                Text("Loading available jobs")
                    .font(Tokens.FontRole.label)
                    .foregroundStyle(Tokens.Color.textSecondary)
                    .padding(.top, Tokens.Space.xs)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        } else if let errorMessage = viewModel.errorMessage, viewModel.jobs.isEmpty {
            errorState(errorMessage)
        } else if viewModel.jobs.isEmpty {
            emptyState
                .accessibilityIdentifier("availableJobsEmptyState")
        } else {
            ScrollView {
                LazyVStack(spacing: Tokens.Space.sm) {
                    ForEach(viewModel.sortedJobs) { booking in
                        NavigationLink {
                            JobDetailView(viewModel: JobDetailViewModel(booking: booking))
                        } label: {
                            JobRowCard(booking: booking)
                        }
                        .buttonStyle(.plain)
                    }
                }
                .padding(Tokens.Space.md)
            }
        }
    }

    private var sortPills: some View {
        HStack(spacing: Tokens.Space.xs) {
            ForEach(AvailableJobsSort.allCases) { option in
                sortPill(option)
            }
        }
    }

    private func sortPill(_ option: AvailableJobsSort) -> some View {
        let isSelected = viewModel.selectedSort == option
        return Button { viewModel.selectedSort = option } label: {
            Text(option.label)
                .font(Tokens.FontRole.label)
                .padding(.horizontal, Tokens.Space.md)
                .padding(.vertical, Tokens.Space.xs)
                .foregroundStyle(isSelected ? Tokens.Color.onPrimary : Tokens.Color.textPrimary)
                .background(
                    Capsule().fill(isSelected ? Tokens.Color.primary : Tokens.Color.surface)
                )
        }
        .accessibilityIdentifier("sortPill_\(option.rawValue)")
    }

    private var emptyState: some View {
        ScrollView {
            VStack(spacing: Tokens.Space.lg) {
                ZStack(alignment: .topTrailing) {
                    Circle()
                        .fill(Tokens.Color.primaryTonal)
                        .frame(width: 112, height: 112)
                    Image(systemName: "pawprint.fill")
                        .font(.system(size: 52, weight: .semibold))
                        .foregroundStyle(Tokens.Color.primary)
                        .frame(width: 112, height: 112)
                    Text("Zzz")
                        .font(Tokens.FontRole.caption)
                        .foregroundStyle(Tokens.Color.textSecondary)
                        .padding(.trailing, Tokens.Space.xs)
                }

                VStack(spacing: Tokens.Space.xs) {
                    Text("No jobs nearby")
                        .font(Tokens.FontRole.titleM)
                        .foregroundStyle(Tokens.Color.textPrimary)
                    Text("Try a busy zone, widen your search to \(viewModel.searchRadiusKm) km, or ask Kilat to alert you when bookings open up.")
                        .font(Tokens.FontRole.label)
                        .foregroundStyle(Tokens.Color.textSecondary)
                        .multilineTextAlignment(.center)
                }

                if let noticeMessage = viewModel.noticeMessage {
                    Label(noticeMessage, systemImage: "checkmark.circle.fill")
                        .font(Tokens.FontRole.caption)
                        .foregroundStyle(Tokens.Color.online)
                        .multilineTextAlignment(.center)
                }

                VStack(spacing: Tokens.Space.sm) {
                    NavigationLink(value: AuthenticatedRoute.hotZones) {
                        Label("Try a hot zone", systemImage: "map.fill")
                            .font(Tokens.FontRole.label)
                            .foregroundStyle(Tokens.Color.onPrimary)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, Tokens.Space.sm)
                            .background(Tokens.Color.primary, in: Capsule())
                    }

                    SecondaryButton(title: "Widen radius", icon: "scope") {
                        viewModel.widenRadius()
                    }

                    Button {
                        Task { await viewModel.createJobAlert() }
                    } label: {
                        HStack {
                            if viewModel.isCreatingJobAlert {
                                ProgressView()
                                    .tint(Tokens.Color.primary)
                            } else {
                                Image(systemName: "bell.badge.fill")
                            }
                            Text("Notify me when available")
                        }
                        .font(Tokens.FontRole.label)
                        .foregroundStyle(Tokens.Color.primary)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, Tokens.Space.sm)
                    }
                    .disabled(viewModel.isCreatingJobAlert)
                }
            }
            .padding(Tokens.Space.xl)
            .frame(maxWidth: .infinity)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    private func errorState(_ message: String) -> some View {
        VStack(spacing: Tokens.Space.md) {
            Image(kilatAsset: "alert")
                .resizable()
                .renderingMode(.template)
                .frame(width: 56, height: 56)
                .foregroundStyle(Tokens.Color.destructive)
            Text("Could not load jobs")
                .font(Tokens.FontRole.titleM)
                .foregroundStyle(Tokens.Color.textPrimary)
            Text(message)
                .font(Tokens.FontRole.label)
                .foregroundStyle(Tokens.Color.textSecondary)
                .multilineTextAlignment(.center)
            PrimaryButton(title: "Try again") {
                Task { await viewModel.load() }
            }
            .padding(.horizontal, Tokens.Space.xl)
        }
        .padding(Tokens.Space.xl)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

#Preview("Empty") {
    NavigationStack {
        AvailableJobsView(viewModel: AvailableJobsViewModel())
    }
}
