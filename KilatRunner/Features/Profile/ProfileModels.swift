import Foundation

struct RunnerProfile: Decodable, Equatable {
    let id: String
    let fullName: String
    let phone: String
    let email: String?
    let photoURL: URL?
    let vehicleType: String?
    let vehiclePlate: String?
    let deliveries: Int
    let onTimeRate: Double
    let acceptanceRate: Double
    let ratingAverage: Double
    let identityVerified: Bool
    let licenseVerified: Bool

    enum CodingKeys: String, CodingKey {
        case id
        case fullName
        case phone
        case email
        case photoURL = "photoUrl"
        case vehicleType
        case vehiclePlate
        case deliveries
        case onTimeRate
        case acceptanceRate
        case ratingAverage
        case identityVerified
        case licenseVerified
    }
}

struct TierSnapshot: Decodable, Equatable {
    let tier: RunnerTier
    let deliveries30D: Int
    let onTimeRate: Double
    let acceptanceRate: Double
    let ratingAverage: Double

    enum CodingKeys: String, CodingKey {
        case tier
        case deliveries30D = "deliveries30d"
        case onTimeRate
        case acceptanceRate
        case ratingAverage
    }
}

enum RunnerTier: String, Decodable, Equatable {
    case bronze
    case silver
    case gold
    case elite

    var displayName: String {
        rawValue.capitalized
    }

    var nextTierName: String {
        switch self {
        case .bronze: return "Silver"
        case .silver: return "Gold"
        case .gold: return "Elite"
        case .elite: return "Elite"
        }
    }

    var progressTarget: Int {
        switch self {
        case .bronze: return 30
        case .silver: return 100
        case .gold, .elite: return 250
        }
    }
}

struct ProfileViewState: Equatable {
    var profile: RunnerProfile
    var tier: TierSnapshot

    var tierProgress: Double {
        guard tier.tier.progressTarget > 0 else { return 1 }
        return min(1, Double(tier.deliveries30D) / Double(tier.tier.progressTarget))
    }

    static func bronzeFallback(profile: RunnerProfile) -> ProfileViewState {
        ProfileViewState(
            profile: profile,
            tier: TierSnapshot(
                tier: .bronze,
                deliveries30D: profile.deliveries,
                onTimeRate: profile.onTimeRate,
                acceptanceRate: profile.acceptanceRate,
                ratingAverage: profile.ratingAverage
            )
        )
    }
}

struct UpdateProfileRequest: Encodable, Equatable {
    let fullName: String
    let phone: String
}

struct PhotoUploadResponse: Decodable, Equatable {
    let photoURL: String

    enum CodingKeys: String, CodingKey {
        case photoURL = "photoUrl"
    }
}
