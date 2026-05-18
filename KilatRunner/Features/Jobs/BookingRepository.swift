import Foundation

protocol BookingRepositoryProtocol {
    func listAvailable() async throws -> [Booking]
    func get(id: String) async throws -> Booking
    func accept(id: String) async throws -> Booking
    func decline(id: String, reason: DeclineReason) async throws
    func markPickup(id: String) async throws -> Booking
    func markDelivered(id: String) async throws -> Booking
}

extension BookingRepositoryProtocol {
    func decline(id: String, reason: DeclineReason) async throws {
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

    func markPickup(id: String) async throws -> Booking {
        let envelope: APIResponseEnvelope<Booking> = try await authInterceptor.perform(.markPickup(id: id))
        return envelope.data
    }

    func markDelivered(id: String) async throws -> Booking {
        let envelope: APIResponseEnvelope<Booking> = try await authInterceptor.perform(.markDelivered(id: id))
        return envelope.data
    }
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
