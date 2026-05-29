import Foundation

protocol TrackingRepositoryProtocol {
    func getHistory(bookingId: String) async throws -> [TrackingUpdate]
    func arriveAtPickup(bookingId: String) async throws -> Booking
    func markPickedUp(bookingId: String, qrCode: String?) async throws -> Booking
    func arriveAtDropoff(bookingId: String) async throws -> Booking
    func submitProofOfDelivery(bookingId: String, proof: ProofOfDeliveryRequest) async throws -> Booking
    func completeDelivery(bookingId: String) async throws -> Booking
}

extension TrackingRepositoryProtocol {
    func arriveAtPickup(bookingId: String) async throws -> Booking { throw NetworkError.invalidResponse }
    func markPickedUp(bookingId: String, qrCode: String?) async throws -> Booking { throw NetworkError.invalidResponse }
    func arriveAtDropoff(bookingId: String) async throws -> Booking { throw NetworkError.invalidResponse }
    func submitProofOfDelivery(bookingId: String, proof: ProofOfDeliveryRequest) async throws -> Booking { throw NetworkError.invalidResponse }
    func completeDelivery(bookingId: String) async throws -> Booking { throw NetworkError.invalidResponse }
}

final class TrackingRepository: TrackingRepositoryProtocol {
    private let authInterceptor: AuthInterceptor

    init(authInterceptor: AuthInterceptor) {
        self.authInterceptor = authInterceptor
    }

    convenience init(apiClient: APIClient = APIClient(), tokenStore: TokenStore = KeychainStore()) {
        self.init(authInterceptor: AuthInterceptor(apiClient: apiClient, tokenStore: tokenStore))
    }

    func getHistory(bookingId: String) async throws -> [TrackingUpdate] {
        let envelope: APIResponseEnvelope<[TrackingUpdate]> = try await authInterceptor.perform(.trackingHistory(bookingId: bookingId))
        return envelope.data
    }

    func arriveAtPickup(bookingId: String) async throws -> Booking {
        let envelope: APIResponseEnvelope<Booking> = try await authInterceptor.perform(.arriveAtPickup(id: bookingId))
        return envelope.data
    }

    func markPickedUp(bookingId: String, qrCode: String?) async throws -> Booking {
        let envelope: APIResponseEnvelope<Booking> = try await authInterceptor.perform(
            .markPickup(id: bookingId),
            body: MarkPickedUpRequest(qrCode: qrCode)
        )
        return envelope.data
    }

    func arriveAtDropoff(bookingId: String) async throws -> Booking {
        let envelope: APIResponseEnvelope<Booking> = try await authInterceptor.perform(.arriveAtDropoff(id: bookingId))
        return envelope.data
    }

    func submitProofOfDelivery(bookingId: String, proof: ProofOfDeliveryRequest) async throws -> Booking {
        let envelope: APIResponseEnvelope<Booking> = try await authInterceptor.perform(.proofOfDelivery(id: bookingId), body: proof)
        return envelope.data
    }

    func completeDelivery(bookingId: String) async throws -> Booking {
        let envelope: APIResponseEnvelope<Booking> = try await authInterceptor.perform(.completeDelivery(id: bookingId))
        return envelope.data
    }
}
