import CoreLocation
import Foundation

struct Booking: Decodable, Equatable, Identifiable {
    let id: String
    let bookingNumber: String
    let ownerId: String
    let runnerId: String?
    let status: BookingStatus
    var kind: BookingKind? = nil
    let petSpec: BookingPetSpec
    var vetSpec: BookingVetSpec? = nil
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

    var isVetBooking: Bool { kind == .vet || vetSpec != nil }
}

enum BookingStatus: String, Decodable, Equatable {
    case requested
    case accepted
    case inProgress = "in_progress"
    case delivered
    case completed
    case cancelled
}

enum BookingKind: String, Decodable, Equatable {
    case delivery
    case vet
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

struct BookingVetSpec: Decodable, Equatable {
    let condition: String
    let medications: [VetMedication]
    let handlingInstructions: String
    let vetName: String
    let vetPhone: String
    let requiresColdChain: Bool

    private enum CodingKeys: String, CodingKey {
        case condition
        case medications
        case handlingInstructions
        case vetName
        case vetPhone
        case requiresColdChain
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        condition = try container.decodeIfPresent(String.self, forKey: .condition) ?? "Routine visit"
        medications = try container.decodeIfPresent([VetMedication].self, forKey: .medications) ?? []
        handlingInstructions = try container.decodeIfPresent(String.self, forKey: .handlingInstructions) ?? ""
        vetName = try container.decodeIfPresent(String.self, forKey: .vetName) ?? ""
        vetPhone = try container.decodeIfPresent(String.self, forKey: .vetPhone) ?? ""
        requiresColdChain = try container.decodeIfPresent(Bool.self, forKey: .requiresColdChain) ?? false
    }
}

struct VetMedication: Decodable, Equatable, Identifiable {
    let id: String
    let name: String
    let dosage: String
    let requiresColdChain: Bool

    private enum CodingKeys: String, CodingKey {
        case id
        case name
        case dosage
        case requiresColdChain
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decodeIfPresent(String.self, forKey: .id) ?? UUID().uuidString
        name = try container.decodeIfPresent(String.self, forKey: .name) ?? ""
        dosage = try container.decodeIfPresent(String.self, forKey: .dosage) ?? ""
        requiresColdChain = try container.decodeIfPresent(Bool.self, forKey: .requiresColdChain) ?? false
    }
}
