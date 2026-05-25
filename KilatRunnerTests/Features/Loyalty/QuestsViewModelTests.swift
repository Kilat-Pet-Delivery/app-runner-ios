import XCTest
@testable import KilatRunner

@MainActor
final class QuestsViewModelTests: XCTestCase {
    func test_loadQuests_groupsDailyAndWeekly() async {
        let repository = LoyaltyRepositorySpy()
        repository.questResponse = QuestListResponse(
            streakDays: 4,
            daily: [QuestFixture.quest(id: "daily-1", cadence: .daily)],
            weekly: [QuestFixture.quest(id: "weekly-1", cadence: .weekly)]
        )
        let viewModel = QuestsViewModel(repository: repository)

        await viewModel.load()

        XCTAssertEqual(viewModel.streakDays, 4)
        XCTAssertEqual(viewModel.dailyQuests.map(\.id), ["daily-1"])
        XCTAssertEqual(viewModel.weeklyChallenges.map(\.id), ["weekly-1"])
    }

    func test_redeem_onSuccess_flipsStatusToRedeemed_locally() async {
        let repository = LoyaltyRepositorySpy()
        let completed = QuestFixture.quest(id: "daily-1", cadence: .daily, status: .completed)
        repository.questResponse = QuestListResponse(streakDays: 1, daily: [completed], weekly: [])
        repository.redeemedQuest = QuestFixture.quest(id: "daily-1", cadence: .daily, status: .redeemed)
        let viewModel = QuestsViewModel(repository: repository)

        await viewModel.load()
        await viewModel.redeem(completed)

        XCTAssertEqual(repository.redeemCalls, ["daily-1"])
        XCTAssertEqual(viewModel.dailyQuests.first?.status, .redeemed)
    }

    func test_redeem_onConflict409_doesNotFlipState() async {
        let repository = LoyaltyRepositorySpy()
        let completed = QuestFixture.quest(id: "daily-1", cadence: .daily, status: .completed)
        repository.questResponse = QuestListResponse(streakDays: 1, daily: [completed], weekly: [])
        repository.redeemError = NetworkError.invalidResponse
        let viewModel = QuestsViewModel(repository: repository)

        await viewModel.load()
        await viewModel.redeem(completed)

        XCTAssertEqual(viewModel.dailyQuests.first?.status, .completed)
        XCTAssertNotNil(viewModel.errorMessage)
    }
}

private enum QuestFixture {
    static func quest(id: String, cadence: QuestCadence, status: QuestStatus = .active) -> RunnerQuest {
        RunnerQuest(
            id: id,
            title: cadence == .daily ? "Complete 3 trips" : "Earn RM 100",
            subtitle: "Keep the streak alive",
            cadence: cadence,
            progressCurrent: status == .active ? 1 : 3,
            progressTarget: 3,
            rewardCents: 500,
            status: status
        )
    }
}

final class LoyaltyRepositorySpy: LoyaltyRepositoryProtocol {
    var questResponse = QuestListResponse(streakDays: 0, daily: [], weekly: [])
    var redeemedQuest: RunnerQuest?
    var redeemError: Error?
    var reviews: [RunnerReview] = []
    var referralResponse = ReferralListResponse(code: nil, friends: [])
    var createdCode = "RUNNER50"
    private(set) var redeemCalls: [String] = []
    private(set) var reviewFetches = 0
    private(set) var createCodeCalls = 0
    private(set) var redeemReferralCalls: [String] = []

    func fetchQuests() async throws -> QuestListResponse {
        questResponse
    }

    func redeemQuest(id: String) async throws -> RunnerQuest {
        redeemCalls.append(id)
        if let redeemError {
            throw redeemError
        }
        return redeemedQuest ?? QuestFixture.quest(id: id, cadence: .daily, status: .redeemed)
    }

    func fetchReviews() async throws -> [RunnerReview] {
        reviewFetches += 1
        return reviews
    }

    func fetchReferrals() async throws -> ReferralListResponse {
        referralResponse
    }

    func createReferralCode() async throws -> String {
        createCodeCalls += 1
        return createdCode
    }

    func redeemReferral(id: String) async throws {
        redeemReferralCalls.append(id)
    }
}
