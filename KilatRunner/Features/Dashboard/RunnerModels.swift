import Foundation

struct Runner: Decodable, Equatable, Identifiable {
    let id: String
    let userId: String
    let fullName: String
    let phone: String
    let vehicleType: String
    let vehiclePlate: String
    let vehicleModel: String
    let airConditioned: Bool
    let sessionStatus: RunnerSessionStatus
    let rating: Double
    let totalTrips: Int
    let crateSpecs: [CrateSpec]
    let distanceKm: Double?
    let createdAt: Date

    var isOnline: Bool {
        sessionStatus == .active
    }

    var maxCrateCapacityKg: Double {
        crateSpecs.map(\.maxWeightKg).max() ?? 0
    }
}

enum RunnerSessionStatus: String, Decodable, Equatable {
    case active
    case inactive
}

enum OnlineStatus: String, Equatable {
    case online
    case offline

    init(sessionStatus: RunnerSessionStatus) {
        self = sessionStatus == .active ? .online : .offline
    }
}

struct CrateSpec: Decodable, Equatable, Identifiable {
    let id: String
    let size: String
    let petTypes: [String]
    let maxWeightKg: Double
    let widthCm: Double
    let heightCm: Double
    let depthCm: Double
    let ventilated: Bool
    let temperatureControlled: Bool
}

struct RunnerLocationWaypoint: Encodable, Equatable {
    let latitude: Double
    let longitude: Double
    let speedKmh: Double
    let headingDegrees: Double
}

struct GoOnlineRequest: Encodable, Equatable {
    let latitude: Double
    let longitude: Double
}
