import Foundation
import Observation

@MainActor
@Observable
final class QuestsViewModel {
    private(set) var streakDays = 0
    private(set) var dailyQuests: [RunnerQuest] = []
    private(set) var weeklyChallenges: [RunnerQuest] = []
    private(set) var isLoading = false
    private(set) var redeemingQuestIDs: Set<String> = []
    private(set) var errorMessage: String?

    @ObservationIgnored private let repository: LoyaltyRepositoryProtocol

    var topActiveQuest: RunnerQuest? {
        (dailyQuests + weeklyChallenges).first { $0.status == .active || $0.status == .completed }
    }

    init(repository: LoyaltyRepositoryProtocol = LoyaltyRepository()) {
        self.repository = repository
    }

    func load() async {
        guard !isLoading else { return }
        errorMessage = nil
        isLoading = true
        defer { isLoading = false }

        do {
            let response = try await repository.fetchQuests()
            streakDays = response.streakDays
            dailyQuests = response.daily
            weeklyChallenges = response.weekly
        } catch let error as NetworkError {
            errorMessage = error.userMessage
        } catch {
            errorMessage = NetworkError.unknown(error.localizedDescription).userMessage
        }
    }

    func redeem(_ quest: RunnerQuest) async {
        guard quest.isClaimable, !redeemingQuestIDs.contains(quest.id) else { return }
        errorMessage = nil
        redeemingQuestIDs.insert(quest.id)
        let previous = quest
        updateQuest(id: quest.id) { $0.status = .redeemed }

        do {
            let redeemed = try await repository.redeemQuest(id: quest.id)
            replaceQuest(redeemed)
        } catch let error as NetworkError {
            replaceQuest(previous)
            errorMessage = error.userMessage
        } catch {
            replaceQuest(previous)
            errorMessage = NetworkError.unknown(error.localizedDescription).userMessage
        }

        redeemingQuestIDs.remove(quest.id)
    }

    private func updateQuest(id: String, mutate: (inout RunnerQuest) -> Void) {
        if let index = dailyQuests.firstIndex(where: { $0.id == id }) {
            mutate(&dailyQuests[index])
        }
        if let index = weeklyChallenges.firstIndex(where: { $0.id == id }) {
            mutate(&weeklyChallenges[index])
        }
    }

    private func replaceQuest(_ quest: RunnerQuest) {
        updateQuest(id: quest.id) { $0 = quest }
    }
}
