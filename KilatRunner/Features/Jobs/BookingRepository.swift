import Foundation

protocol BookingRepositoryProtocol {
    func listAvailable() async throws -> [Booking]
    func fetchHistory(filter: BookingHistoryFilter, cursor: String?, limit: Int) async throws -> BookingHistoryPage
    func fetchScheduled() async throws -> [Booking]
    func get(id: String) async throws -> Booking
    func accept(id: String) async throws -> Booking
    func decline(id: String, reason: DeclineReason) async throws
    func arriveAtPickup(id: String) async throws -> Booking
    func markPickedUp(id: String, qrCode: String?) async throws -> Booking
    func arriveAtDropoff(id: String) async throws -> Booking
    func submitProofOfDelivery(id: String, proof: ProofOfDeliveryRequest) async throws -> Booking
    func completeDelivery(id: String) async throws -> Booking
    func rateCustomer(id: String, rating: CustomerRatingRequest) async throws -> Booking
    func markPickup(id: String) async throws -> Booking
    func markDelivered(id: String) async throws -> Booking
}

extension BookingRepositoryProtocol {
    func decline(id: String, reason: DeclineReason) async throws {
        throw NetworkError.invalidResponse
    }

    func fetchHistory(filter: BookingHistoryFilter, cursor: String?, limit: Int) async throws -> BookingHistoryPage {
        throw NetworkError.invalidResponse
    }

    func fetchScheduled() async throws -> [Booking] {
        throw NetworkError.invalidResponse
    }

    func arriveAtPickup(id: String) async throws -> Booking {
        throw NetworkError.invalidResponse
    }

    func markPickedUp(id: String, qrCode: String?) async throws -> Booking {
        try await markPickup(id: id)
    }

    func arriveAtDropoff(id: String) async throws -> Booking {
        throw NetworkError.invalidResponse
    }

    func submitProofOfDelivery(id: String, proof: ProofOfDeliveryRequest) async throws -> Booking {
        throw NetworkError.invalidResponse
    }

    func completeDelivery(id: String) async throws -> Booking {
        try await markDelivered(id: id)
    }

    func rateCustomer(id: String, rating: CustomerRatingRequest) async throws -> Booking {
        throw NetworkError.invalidResponse
    }
}

final class BookingRepository: BookingRepositoryProtocol {
    private let authInterceptor: AuthInterceptor

    init(authInterceptor: AuthInterceptor) {
        self.authInterceptor = authInterceptor
    }

    convenience init(apiClient: APIClient = APIClient(), tokenStore: TokenStore = KeychainStore()) {
        self.init(authInterceptor: AuthInterceptor(apiClient: apiClient, tokenStore: tokenStore))
    }

    func listAvailable() async throws -> [Booking] {
        let envelope: APIResponseEnvelope<[Booking]> = try await authInterceptor.perform(.availableJobs())
        return envelope.data
    }

    func fetchHistory(filter: BookingHistoryFilter, cursor: String? = nil, limit: Int = 20) async throws -> BookingHistoryPage {
        try await authInterceptor.perform(.bookingHistory(filter: filter.rawValue, cursor: cursor, limit: limit))
    }

    func fetchScheduled() async throws -> [Booking] {
        let envelope: APIResponseEnvelope<[Booking]> = try await authInterceptor.perform(.scheduledBookings)
        return envelope.data
    }

    func get(id: String) async throws -> Booking {
        let envelope: APIResponseEnvelope<Booking> = try await authInterceptor.perform(.bookingDetail(id: id))
        return envelope.data
    }

    func accept(id: String) async throws -> Booking {
        let envelope: APIResponseEnvelope<Booking> = try await authInterceptor.perform(.acceptBooking(id: id))
        return envelope.data
    }

    func decline(id: String, reason: DeclineReason) async throws {
        let _: EmptyResponse = try await authInterceptor.perform(
            .declineBooking(id: id),
            body: DeclineBookingRequest(reason: reason.rawValue)
        )
    }

    func arriveAtPickup(id: String) async throws -> Booking {
        let envelope: APIResponseEnvelope<Booking> = try await authInterceptor.perform(.arriveAtPickup(id: id))
        return envelope.data
    }

    func markPickedUp(id: String, qrCode: String?) async throws -> Booking {
        if let qrCode {
            let envelope: APIResponseEnvelope<Booking> = try await authInterceptor.perform(
                .markPickup(id: id),
                body: MarkPickedUpRequest(qrCode: qrCode)
            )
            return envelope.data
        }
        return try await markPickup(id: id)
    }

    func arriveAtDropoff(id: String) async throws -> Booking {
        let envelope: APIResponseEnvelope<Booking> = try await authInterceptor.perform(.arriveAtDropoff(id: id))
        return envelope.data
    }

    func submitProofOfDelivery(id: String, proof: ProofOfDeliveryRequest) async throws -> Booking {
        let envelope: APIResponseEnvelope<Booking> = try await authInterceptor.perform(.proofOfDelivery(id: id), body: proof)
        return envelope.data
    }

    func completeDelivery(id: String) async throws -> Booking {
        let envelope: APIResponseEnvelope<Booking> = try await authInterceptor.perform(.completeDelivery(id: id))
        return envelope.data
    }

    func rateCustomer(id: String, rating: CustomerRatingRequest) async throws -> Booking {
        let envelope: APIResponseEnvelope<Booking> = try await authInterceptor.perform(.rateCustomer(id: id), body: rating)
        return envelope.data
    }

    func markPickup(id: String) async throws -> Booking {
        let envelope: APIResponseEnvelope<Booking> = try await authInterceptor.perform(.markPickup(id: id))
        return envelope.data
    }

    func markDelivered(id: String) async throws -> Booking {
        let envelope: APIResponseEnvelope<Booking> = try await authInterceptor.perform(.markDelivered(id: id))
        return envelope.data
    }
}

struct MarkPickedUpRequest: Encodable, Equatable {
    let qrCode: String?
}

enum ProofRecipient: String, CaseIterable, Identifiable, Encodable, Equatable {
    case customer
    case receptionist
    case leftAtDoor = "left_at_door"

    var id: String { rawValue }

    var label: String {
        switch self {
        case .customer: return "Customer"
        case .receptionist: return "Receptionist"
        case .leftAtDoor: return "Left at door"
        }
    }

    var requiresSignature: Bool {
        self == .customer
    }
}

struct ProofOfDeliveryRequest: Encodable, Equatable {
    let photoStorageKey: String
    let signatureStorageKey: String?
    let recipient: ProofRecipient
    let notes: String
}

struct CustomerRatingRequest: Encodable, Equatable {
    let rating: Int
    let tags: [String]
}

enum DeclineReason: String, CaseIterable, Identifiable, Encodable {
    case tooFar = "too_far"
    case cannotTransport = "cannot_transport"
    case alreadyBusy = "already_busy"
    case pickupIssue = "pickup_issue"
    case other

    var id: String { rawValue }

    var label: String {
        switch self {
        case .tooFar: return "Too far"
        case .cannotTransport: return "I can't transport"
        case .alreadyBusy: return "Already busy"
        case .pickupIssue: return "Pickup issue"
        case .other: return "Other"
        }
    }
}

struct DeclineBookingRequest: Encodable, Equatable {
    let reason: String
}

enum BookingHistoryFilter: String, CaseIterable, Identifiable, Equatable {
    case all
    case live
    case cancelled

    var id: String { rawValue }

    var label: String {
        switch self {
        case .all: return "All"
        case .live: return "Live"
        case .cancelled: return "Cancelled"
        }
    }
}

struct BookingHistoryPage: Decodable, Equatable {
    let items: [Booking]
    let nextCursor: String
}
