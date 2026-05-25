import Foundation

enum QuestCadence: String, Decodable, Equatable {
    case daily
    case weekly
}

enum QuestStatus: String, Decodable, Equatable {
    case active
    case completed
    case redeemed
}

struct RunnerQuest: Decodable, Equatable, Identifiable {
    let id: String
    let title: String
    let subtitle: String
    let cadence: QuestCadence
    let progressCurrent: Int
    let progressTarget: Int
    let rewardCents: Int
    var status: QuestStatus

    var progress: Double {
        guard progressTarget > 0 else { return 0 }
        return min(1, Double(progressCurrent) / Double(progressTarget))
    }

    var isClaimable: Bool {
        status == .completed
    }
}

struct QuestListResponse: Decodable, Equatable {
    let streakDays: Int
    let daily: [RunnerQuest]
    let weekly: [RunnerQuest]
}

struct TipReceivedPayload: Decodable, Equatable {
    let bookingID: String
    let tipAmountMYR: Double
    let customerName: String
    let message: String?
    let threadID: String?

    enum CodingKeys: String, CodingKey {
        case bookingID = "booking_id"
        case tipAmountMYR = "tip_amount_myr"
        case customerName = "customer_name"
        case message
        case threadID = "thread_id"
    }
}
