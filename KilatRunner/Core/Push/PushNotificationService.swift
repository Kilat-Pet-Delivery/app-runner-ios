import Foundation
import UIKit
import UserNotifications

final class PushNotificationService {
    static let shared = PushNotificationService()

    private let decoder: JSONDecoder

    init(decoder: JSONDecoder = PushNotificationService.makeDecoder()) {
        self.decoder = decoder
    }

    func registerForRemoteNotifications() {
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .badge, .sound]) { granted, _ in
            guard granted else { return }
            DispatchQueue.main.async {
                UIApplication.shared.registerForRemoteNotifications()
            }
        }
    }

    func decodeIntent(userInfo: [AnyHashable: Any]) -> PushIntent? {
        guard let category = category(from: userInfo) else {
            print("Kilat push ignored: missing category")
            return nil
        }

        switch category {
        case "chat_message":
            guard let threadID = stringValue(for: ["thread_id", "threadID"], in: userInfo) else { return nil }
            return .chatMessage(threadID: threadID)
        case "tip_received":
            return decodeTipPayload(from: userInfo).map(PushIntent.tipReceived)
        case "sos_ack":
            guard let incidentID = stringValue(for: ["incident_id", "incidentID"], in: userInfo) else { return nil }
            return .sosAcknowledged(incidentID: incidentID)
        case "incident_assigned":
            guard let incidentID = stringValue(for: ["incident_id", "incidentID"], in: userInfo) else { return nil }
            return .incidentAssigned(incidentID: incidentID)
        case "quest_completed":
            guard let questID = stringValue(for: ["quest_id", "questID"], in: userInfo) else { return nil }
            return .questCompleted(questID: questID)
        case "tier_promoted":
            guard let tier = stringValue(for: ["tier"], in: userInfo) else { return nil }
            return .tierPromoted(tier: tier)
        case "surge_active":
            guard let zoneCode = stringValue(for: ["zone_code", "zoneCode"], in: userInfo) else { return nil }
            return .surgeActive(zoneCode: zoneCode)
        case "proof_required":
            guard let bookingID = stringValue(for: ["booking_id", "bookingID"], in: userInfo) else { return nil }
            return .proofRequired(bookingID: bookingID)
        default:
            print("Kilat push ignored unknown category: \(category)")
            return nil
        }
    }

    private func category(from userInfo: [AnyHashable: Any]) -> String? {
        if let category = stringValue(for: ["category"], in: userInfo) {
            return category.lowercased()
        }
        guard
            let aps = userInfo["aps"] as? [AnyHashable: Any],
            let category = aps["category"] as? String
        else {
            return nil
        }
        return category.lowercased()
    }

    private func decodeTipPayload(from userInfo: [AnyHashable: Any]) -> TipReceivedPayload? {
        let normalized = userInfo.reduce(into: [String: Any]()) { result, pair in
            guard let key = pair.key as? String, key != "aps" else { return }
            result[key] = pair.value
        }
        guard JSONSerialization.isValidJSONObject(normalized),
              let data = try? JSONSerialization.data(withJSONObject: normalized)
        else {
            return nil
        }
        return try? decoder.decode(TipReceivedPayload.self, from: data)
    }

    private func stringValue(for keys: [String], in userInfo: [AnyHashable: Any]) -> String? {
        for key in keys {
            if let value = userInfo[key] as? String, !value.isEmpty {
                return value
            }
        }
        return nil
    }

    private static func makeDecoder() -> JSONDecoder {
        let decoder = JSONDecoder()
        decoder.keyDecodingStrategy = .useDefaultKeys
        decoder.dateDecodingStrategy = .iso8601
        return decoder
    }
}
