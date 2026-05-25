import SwiftUI
import KilatUI

struct OfflineView: View {
    @Environment(\.dismiss) private var dismiss
    @Bindable private var viewModel: OfflineViewModel

    init(viewModel: OfflineViewModel) {
        self.viewModel = viewModel
    }

    var body: some View {
        VStack(spacing: Tokens.Space.xl) {
            Spacer()

            ZStack {
                Circle()
                    .fill(Tokens.Color.destructive.opacity(0.14))
                    .frame(width: 120, height: 120)
                Image(systemName: "wifi.slash")
                    .font(.system(size: 48, weight: .semibold))
                    .foregroundStyle(Tokens.Color.destructive)
            }

            VStack(spacing: Tokens.Space.xs) {
                Text("You're offline")
                    .font(Tokens.FontRole.displayL)
                    .foregroundStyle(Tokens.Color.textPrimary)
                    .multilineTextAlignment(.center)
                Text("Kilat will keep queued delivery actions ready and send them once your connection returns.")
                    .font(Tokens.FontRole.label)
                    .foregroundStyle(Tokens.Color.textSecondary)
                    .multilineTextAlignment(.center)
            }

            queuedActionsCard

            Spacer()

            PrimaryButton(title: "Back", icon: "chevron.left") {
                dismiss()
            }
        }
        .padding(Tokens.Space.xl)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Tokens.Color.background.ignoresSafeArea())
        .navigationBarTitleDisplayMode(.inline)
        .task { await viewModel.refresh() }
    }

    private var queuedActionsCard: some View {
        VStack(alignment: .leading, spacing: Tokens.Space.md) {
            HStack {
                Label("Queued actions", systemImage: "tray.full.fill")
                    .font(Tokens.FontRole.bodyBold)
                    .foregroundStyle(Tokens.Color.textPrimary)
                Spacer()
                Text("\(viewModel.queuedWaypointCount)")
                    .font(Tokens.FontRole.titleM)
                    .foregroundStyle(Tokens.Color.primary)
            }
            Text(viewModel.queuedActionsSummary)
                .font(Tokens.FontRole.label)
                .foregroundStyle(Tokens.Color.textSecondary)
        }
        .padding(Tokens.Space.lg)
        .background(Tokens.Color.surface, in: RoundedRectangle(cornerRadius: Tokens.Radius.lg, style: .continuous))
        .tokenShadow(Tokens.Shadow.card)
        .accessibilityIdentifier("offlineQueuedActionsCard")
    }
}
