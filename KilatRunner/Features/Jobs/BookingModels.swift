import CoreLocation
import Foundation

struct Booking: Decodable, Equatable, Identifiable {
    let id: String
    let bookingNumber: String
    let ownerId: String
    let runnerId: String?
    let status: BookingStatus
    let petSpec: BookingPetSpec
    let pickupAddress: BookingAddress
    let dropoffAddress: BookingAddress
    let routeSpec: BookingRouteSpec?
    let estimatedPriceCents: Int64
    let finalPriceCents: Int64?
    let currency: String
    let scheduledAt: Date?
    let pickedUpAt: Date?
    let deliveredAt: Date?
    let cancelledAt: Date?
    let cancelNote: String?
    let notes: String?
    let version: Int64
    let createdAt: Date
    let updatedAt: Date

    var pickupCoordinate: CLLocationCoordinate2D {
        CLLocationCoordinate2D(latitude: pickupAddress.latitude, longitude: pickupAddress.longitude)
    }

    var dropoffCoordinate: CLLocationCoordinate2D {
        CLLocationCoordinate2D(latitude: dropoffAddress.latitude, longitude: dropoffAddress.longitude)
    }

    var distanceKm: Double? { routeSpec?.distanceKm }
}

enum BookingStatus: String, Decodable, Equatable {
    case requested
    case accepted
    case inProgress = "in_progress"
    case delivered
    case completed
    case cancelled
}

struct BookingAddress: Decodable, Equatable {
    let line1: String
    let line2: String
    let city: String
    let state: String
    let postalCode: String
    let country: String
    let latitude: Double
    let longitude: Double

    var singleLineLabel: String {
        let parts = [line1, line2, city, state, postalCode, country].filter { !$0.isEmpty }
        return parts.joined(separator: ", ")
    }
}

struct BookingPetSpec: Decodable, Equatable {
    let petType: String
    let breed: String
    let name: String
    let weightKg: Double
    let specialNeeds: String
    let photoUrl: String

    private enum CodingKeys: String, CodingKey {
        case petType
        case breed
        case name
        case weightKg
        case specialNeeds
        case photoUrl
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        petType = try container.decodeIfPresent(String.self, forKey: .petType) ?? ""
        breed = try container.decodeIfPresent(String.self, forKey: .breed) ?? ""
        name = try container.decodeIfPresent(String.self, forKey: .name) ?? ""
        weightKg = try container.decodeIfPresent(Double.self, forKey: .weightKg) ?? 0
        specialNeeds = try container.decodeIfPresent(String.self, forKey: .specialNeeds) ?? ""
        photoUrl = try container.decodeIfPresent(String.self, forKey: .photoUrl) ?? ""
    }
}

struct BookingRouteSpec: Decodable, Equatable {
    let pickupLat: Double
    let pickupLng: Double
    let dropoffLat: Double
    let dropoffLng: Double
    let distanceKm: Double
    let estimatedDurationMin: Int
    let polyline: String

    private enum CodingKeys: String, CodingKey {
        case pickupLat
        case pickupLng
        case dropoffLat
        case dropoffLng
        case distanceKm
        case estimatedDurationMin
        case polyline
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        pickupLat = try container.decodeIfPresent(Double.self, forKey: .pickupLat) ?? 0
        pickupLng = try container.decodeIfPresent(Double.self, forKey: .pickupLng) ?? 0
        dropoffLat = try container.decodeIfPresent(Double.self, forKey: .dropoffLat) ?? 0
        dropoffLng = try container.decodeIfPresent(Double.self, forKey: .dropoffLng) ?? 0
        distanceKm = try container.decodeIfPresent(Double.self, forKey: .distanceKm) ?? 0
        estimatedDurationMin = try container.decodeIfPresent(Int.self, forKey: .estimatedDurationMin) ?? 0
        polyline = try container.decodeIfPresent(String.self, forKey: .polyline) ?? ""
    }
}
