import XCTest
@testable import KilatRunner

@MainActor
final class ReferFriendViewModelTests: XCTestCase {
    func test_createCodeIsIdempotent_acrossMultipleCalls() async {
        let repository = LoyaltyRepositorySpy()
        repository.createdCode = "AIMAN50"
        let viewModel = ReferFriendViewModel(repository: repository)

        await viewModel.ensureCode()
        await viewModel.ensureCode()

        XCTAssertEqual(viewModel.referralCode, "AIMAN50")
        XCTAssertEqual(repository.createCodeCalls, 1)
    }

    func test_payoutEligibleRow_showsRedeemAction() async throws {
        let repository = LoyaltyRepositorySpy()
        let friend = try ReferralFixture.friend(id: "friend-1", status: .eligible)
        repository.referralResponse = ReferralListResponse(code: "AIMAN50", friends: [friend])
        let viewModel = ReferFriendViewModel(repository: repository)

        await viewModel.load()

        XCTAssertTrue(viewModel.friends[0].isPayoutEligible)

        await viewModel.redeem(friend)

        XCTAssertEqual(repository.redeemReferralCalls, ["friend-1"])
        XCTAssertEqual(viewModel.friends[0].payoutStatus, .pending)
    }
}

private enum ReferralFixture {
    static func friend(id: String, status: ReferralPayoutStatus) throws -> ReferralFriend {
        ReferralFriend(
            id: id,
            name: "Alya",
            signupDate: try XCTUnwrap(ISO8601DateFormatter().date(from: "2026-05-20T10:00:00Z")),
            deliveriesToDate: 5,
            payoutStatus: status
        )
    }
}
