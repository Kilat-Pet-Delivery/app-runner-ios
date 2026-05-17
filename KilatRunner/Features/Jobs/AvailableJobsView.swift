import SwiftUI
import KilatUI

struct AvailableJobsView: View {
    @Bindable private var viewModel: AvailableJobsViewModel

    init(viewModel: AvailableJobsViewModel) {
        self.viewModel = viewModel
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
        VStack(spacing: Tokens.Space.md) {
            Image(kilatAsset: "box")
                .resizable()
                .renderingMode(.template)
                .frame(width: 64, height: 64)
                .foregroundStyle(Tokens.Color.textTertiary)
            Text("No available jobs")
                .font(Tokens.FontRole.titleM)
                .foregroundStyle(Tokens.Color.textPrimary)
            Text("Pull to refresh when new bookings come in.")
                .font(Tokens.FontRole.label)
                .foregroundStyle(Tokens.Color.textSecondary)
                .multilineTextAlignment(.center)
        }
        .padding(Tokens.Space.xl)
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
