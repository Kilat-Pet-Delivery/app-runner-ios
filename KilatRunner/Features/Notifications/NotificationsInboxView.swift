import SwiftUI
import KilatUI

struct NotificationsInboxView: View {
    @Bindable private var viewModel: NotificationsViewModel

    init(viewModel: NotificationsViewModel) {
        self.viewModel = viewModel
    }

    var body: some View {
        ScrollView {
            LazyVStack(spacing: Tokens.Space.sm) {
                if viewModel.items.isEmpty && !viewModel.isLoading {
                    emptyState
                }

                ForEach(viewModel.items) { item in
                    notificationRow(item)
                        .onAppear {
                            if item.id == viewModel.items.last?.id {
                                Task { await viewModel.loadNextPage() }
                            }
                        }
                }

                if viewModel.isLoading {
                    ProgressView()
                        .padding(Tokens.Space.lg)
                }
            }
            .padding(Tokens.Space.md)
        }
        .background(Tokens.Color.background.ignoresSafeArea())
        .navigationTitle("Notifications")
        .navigationBarTitleDisplayMode(.inline)
        .refreshable { await viewModel.loadFirstPage() }
        .task {
            if viewModel.items.isEmpty {
                await viewModel.loadFirstPage()
            }
        }
    }

    private var emptyState: some View {
        VStack(spacing: Tokens.Space.sm) {
            Image(kilatAsset: "bell")
                .resizable()
                .renderingMode(.template)
                .frame(width: 42, height: 42)
                .foregroundStyle(Tokens.Color.textSecondary)
            Text("No notifications yet")
                .font(Tokens.FontRole.titleM)
                .foregroundStyle(Tokens.Color.textPrimary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, Tokens.Space.xxxl)
    }

    private func notificationRow(_ item: RunnerNotification) -> some View {
        Button {
            viewModel.markReadLocally(item.id)
        } label: {
            HStack(alignment: .top, spacing: Tokens.Space.sm) {
                notificationIcon(for: item.type)

                VStack(alignment: .leading, spacing: Tokens.Space.xxs) {
                    HStack(alignment: .firstTextBaseline) {
                        Text(item.title)
                            .font(item.isUnread ? Tokens.FontRole.bodyBold : Tokens.FontRole.label)
                            .foregroundStyle(Tokens.Color.textPrimary)
                        Spacer()
                        Text(relativeTime(for: item.createdAt))
                            .font(Tokens.FontRole.caption)
                            .foregroundStyle(Tokens.Color.textSecondary)
                    }

                    Text(item.body)
                        .font(Tokens.FontRole.caption)
                        .foregroundStyle(Tokens.Color.textSecondary)
                        .lineLimit(2)
                }

                if item.isUnread {
                    Circle()
                        .fill(Tokens.Color.primary)
                        .frame(width: 9, height: 9)
                        .padding(.top, 5)
                }
            }
            .padding(Tokens.Space.md)
            .background(Tokens.Color.surface, in: RoundedRectangle(cornerRadius: Tokens.Radius.md))
        }
        .buttonStyle(.plain)
    }

    private func notificationIcon(for type: String) -> some View {
        let iconName: String
        switch type.lowercased() {
        case "payment", "payout", "cash_out":
            iconName = "wallet"
        case "booking", "job":
            iconName = "box"
        case "tracking", "route":
            iconName = "route"
        default:
            iconName = "bell"
        }

        return Image(kilatAsset: iconName)
            .resizable()
            .renderingMode(.template)
            .frame(width: 22, height: 22)
            .foregroundStyle(Tokens.Color.primary)
    }

    private func relativeTime(for date: Date) -> String {
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .abbreviated
        return formatter.localizedString(for: date, relativeTo: Date())
    }
}
