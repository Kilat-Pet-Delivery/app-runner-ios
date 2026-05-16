import Foundation

protocol BookingRepositoryProtocol {
    func listAvailable() async throws -> [Booking]
    func get(id: String) async throws -> Booking
    func accept(id: String) async throws -> Booking
    func markPickup(id: String) async throws -> Booking
    func markDelivered(id: String) async throws -> Booking
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

    func markPickup(id: String) async throws -> Booking {
        let envelope: APIResponseEnvelope<Booking> = try await authInterceptor.perform(.markPickup(id: id))
        return envelope.data
    }

    func markDelivered(id: String) async throws -> Booking {
        let envelope: APIResponseEnvelope<Booking> = try await authInterceptor.perform(.markDelivered(id: id))
        return envelope.data
    }
}
