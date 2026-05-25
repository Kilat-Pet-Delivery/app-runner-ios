import Foundation
import Observation

@MainActor
@Observable
final class ReferFriendViewModel {
    private(set) var referralCode: String?
    private(set) var friends: [ReferralFriend] = []
    private(set) var isLoading = false
    private(set) var isCreatingCode = false
    var errorMessage: String?

    @ObservationIgnored private let repository: LoyaltyRepositoryProtocol

    init(repository: LoyaltyRepositoryProtocol = LoyaltyRepository()) {
        self.repository = repository
    }

    var shareText: String {
        guard let referralCode else { return "Join Kilat Pet Delivery as a runner." }
        return "Join Kilat Pet Delivery with my runner code \(referralCode)."
    }

    func load() async {
        errorMessage = nil
        isLoading = true
        defer { isLoading = false }

        do {
            let response = try await repository.fetchReferrals()
            referralCode = response.code
            friends = response.friends
        } catch let error as NetworkError {
            errorMessage = error.userMessage
        } catch {
            errorMessage = NetworkError.unknown(error.localizedDescription).userMessage
        }
    }

    func ensureCode() async {
        guard referralCode == nil, !isCreatingCode else { return }
        isCreatingCode = true
        defer { isCreatingCode = false }

        do {
            referralCode = try await repository.createReferralCode()
        } catch let error as NetworkError {
            errorMessage = error.userMessage
        } catch {
            errorMessage = NetworkError.unknown(error.localizedDescription).userMessage
        }
    }

    func redeem(_ friend: ReferralFriend) async {
        guard friend.isPayoutEligible, let index = friends.firstIndex(where: { $0.id == friend.id }) else { return }
        friends[index].payoutStatus = .pending

        do {
            try await repository.redeemReferral(id: friend.id)
        } catch let error as NetworkError {
            friends[index].payoutStatus = .eligible
            errorMessage = error.userMessage
        } catch {
            friends[index].payoutStatus = .eligible
            errorMessage = NetworkError.unknown(error.localizedDescription).userMessage
        }
    }
}
