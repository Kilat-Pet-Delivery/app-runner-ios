import Foundation
import Observation

enum CashOutQuickAmount: Equatable {
    case max
    case fixed(Int64)
}

struct CashOutSentDetails: Equatable {
    let cashOutID: String
    let amountCents: Int64
    let destinationLabel: String
    let etaMinutes: Int
    let requestedAt: Date
}

@Observable
final class CashOutViewModel {
    let availableAmountCents: Int64
    let feeCents: Int64 = 50
    var amountCents: Int64
    var selectedQuickAmount: CashOutQuickAmount = .max
    var destinationID: String
    var destinationLabel: String
    private(set) var isSubmitting = false
    var sentDetails: CashOutSentDetails?
    var errorMessage: String?

    var receiveAmountCents: Int64 {
        max(amountCents - feeCents, 0)
    }

    var progress: Double {
        guard availableAmountCents > 0 else { return 0 }
        return min(Double(amountCents) / Double(availableAmountCents), 1)
    }

    var isSubmitEnabled: Bool {
        amountCents > feeCents && amountCents <= availableAmountCents && !destinationID.isEmpty && !isSubmitting
    }

    @ObservationIgnored private let repository: PayoutRepositoryProtocol

    init(
        availableAmountCents: Int64,
        destinationID: String = "11111111-1111-4111-8111-111111111111",
        destinationLabel: String = "Maybank Wallet - 4521",
        repository: PayoutRepositoryProtocol = PayoutRepository()
    ) {
        self.availableAmountCents = availableAmountCents
        self.amountCents = availableAmountCents
        self.destinationID = destinationID
        self.destinationLabel = destinationLabel
        self.repository = repository
    }

    func selectQuickAmount(_ quickAmount: CashOutQuickAmount) {
        selectedQuickAmount = quickAmount
        switch quickAmount {
        case .max:
            amountCents = availableAmountCents
        case let .fixed(value):
            amountCents = min(value, availableAmountCents)
        }
    }

    @MainActor
    func submit() async {
        errorMessage = nil

        guard isSubmitEnabled else {
            errorMessage = "Choose an amount below your available balance."
            return
        }

        isSubmitting = true
        defer { isSubmitting = false }

        do {
            let response = try await repository.cashOut(amountMyrCents: amountCents, destinationID: destinationID)
            sentDetails = CashOutSentDetails(
                cashOutID: response.cashOutID,
                amountCents: amountCents,
                destinationLabel: destinationLabel,
                etaMinutes: response.etaMinutes,
                requestedAt: Date()
            )
        } catch let error as NetworkError {
            errorMessage = error.userMessage
        } catch {
            errorMessage = NetworkError.unknown(error.localizedDescription).userMessage
        }
    }
}
