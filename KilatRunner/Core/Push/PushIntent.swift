import Foundation

enum PushIntent: Equatable {
    case chatMessage(threadID: String)
    case tipReceived(TipReceivedPayload)
    case sosAcknowledged(incidentID: String)
    case incidentAssigned(incidentID: String)
    case questCompleted(questID: String)
    case tierPromoted(tier: String)
    case surgeActive(zoneCode: String)
    case proofRequired(bookingID: String)
}
