import SwiftUI
import KilatUI

struct QuestsView: View {
    @Bindable var viewModel: QuestsViewModel

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: Tokens.Space.lg) {
                streakMeter
                questSection("Daily quests", quests: viewModel.dailyQuests)
                questSection("Weekly challenges", quests: viewModel.weeklyChallenges)

                if viewModel.isLoading, viewModel.dailyQuests.isEmpty, viewModel.weeklyChallenges.isEmpty {
                    ProgressView()
                        .frame(maxWidth: .infinity)
                }

                if let errorMessage = viewModel.errorMessage {
                    Text(errorMessage)
                        .font(Tokens.FontRole.caption)
                        .foregroundStyle(Tokens.Color.destructive)
                }
            }
            .padding(Tokens.Space.lg)
        }
        .background(Tokens.Color.background.ignoresSafeArea())
        .navigationTitle("Quests")
        .navigationBarTitleDisplayMode(.inline)
        .task {
            if viewModel.dailyQuests.isEmpty, viewModel.weeklyChallenges.isEmpty {
                await viewModel.load()
            }
        }
    }

    private var streakMeter: some View {
        VStack(alignment: .leading, spacing: Tokens.Space.sm) {
            HStack {
                Text("\(viewModel.streakDays)-day streak")
                    .font(Tokens.FontRole.titleM)
                    .foregroundStyle(Tokens.Color.textPrimary)
                Spacer()
                Image(systemName: "flame.fill")
                    .foregroundStyle(Tokens.Color.primary)
            }
            HStack(spacing: 5) {
                ForEach(0..<12, id: \.self) { day in
                    Capsule()
                        .fill(day < viewModel.streakDays ? Tokens.Color.primary : Tokens.Color.surfaceMuted)
                        .frame(height: 10)
                }
            }
        }
        .padding(Tokens.Space.md)
        .background(Tokens.Color.surface, in: RoundedRectangle(cornerRadius: Tokens.Radius.lg, style: .continuous))
    }

    private func questSection(_ title: String, quests: [RunnerQuest]) -> some View {
        VStack(alignment: .leading, spacing: Tokens.Space.sm) {
            Text(title)
                .font(Tokens.FontRole.caption)
                .foregroundStyle(Tokens.Color.textSecondary)
                .textCase(.uppercase)

            if quests.isEmpty {
                Text("No quests available")
                    .font(Tokens.FontRole.label)
                    .foregroundStyle(Tokens.Color.textSecondary)
                    .padding(Tokens.Space.md)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(Tokens.Color.surface, in: RoundedRectangle(cornerRadius: Tokens.Radius.md, style: .continuous))
            } else {
                ForEach(quests) { quest in
                    questCard(quest)
                }
            }
        }
    }

    private func questCard(_ quest: RunnerQuest) -> some View {
        VStack(alignment: .leading, spacing: Tokens.Space.sm) {
            HStack(alignment: .top) {
                VStack(alignment: .leading, spacing: Tokens.Space.xxs) {
                    Text(quest.title)
                        .font(Tokens.FontRole.bodyBold)
                        .foregroundStyle(Tokens.Color.textPrimary)
                    Text(quest.subtitle)
                        .font(Tokens.FontRole.caption)
                        .foregroundStyle(Tokens.Color.textSecondary)
                }
                Spacer()
                Text(money(quest.rewardCents))
                    .font(Tokens.FontRole.label)
                    .foregroundStyle(Tokens.Color.primary)
            }

            ProgressBar(progress: quest.progress)

            HStack {
                Text("\(quest.progressCurrent)/\(quest.progressTarget)")
                    .font(Tokens.FontRole.caption)
                    .foregroundStyle(Tokens.Color.textSecondary)
                Spacer()
                if quest.status == .redeemed {
                    Text("Redeemed")
                        .font(Tokens.FontRole.caption)
                        .foregroundStyle(Tokens.Color.online)
                } else {
                    Button {
                        Task { await viewModel.redeem(quest) }
                    } label: {
                        Text("Claim")
                            .font(Tokens.FontRole.caption)
                            .foregroundStyle(quest.isClaimable ? Tokens.Color.primary : Tokens.Color.textSecondary)
                    }
                    .disabled(!quest.isClaimable || viewModel.redeemingQuestIDs.contains(quest.id))
                }
            }
        }
        .padding(Tokens.Space.md)
        .background(Tokens.Color.surface, in: RoundedRectangle(cornerRadius: Tokens.Radius.md, style: .continuous))
    }

    private func money(_ cents: Int) -> String {
        String(format: "RM %.2f", Double(cents) / 100)
    }
}
