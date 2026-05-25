import Foundation
import Observation

struct TipThankYouRoute: Hashable, Identifiable {
    let threadID: String
    let quickReply: String
    let customerName: String

    var id: String { threadID }
}

@MainActor
@Observable
final class TipReceivedViewModel {
    private(set) var bookingID: String
    private(set) var tipAmountMYR: Double
    private(set) var customerName: String
    private(set) var message: String?
    private(set) var threadID: String?
    var thankYouRoute: TipThankYouRoute?

    var amountLabel: String {
        String(format: "RM %.2f", tipAmountMYR)
    }

    init(payload: TipReceivedPayload) {
        self.bookingID = payload.bookingID
        self.tipAmountMYR = payload.tipAmountMYR
        self.customerName = payload.customerName
        self.message = payload.message
        self.threadID = payload.threadID
    }

    convenience init(jsonData: Data) throws {
        let payload = try JSONDecoder().decode(TipReceivedPayload.self, from: jsonData)
        self.init(payload: payload)
    }

    func sendThankYou() {
        guard let threadID, !threadID.isEmpty else { return }
        thankYouRoute = TipThankYouRoute(
            threadID: threadID,
            quickReply: "Thank you for the tip, \(customerName)!",
            customerName: customerName
        )
    }
}
