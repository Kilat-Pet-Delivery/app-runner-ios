import Foundation

protocol IncidentRepositoryProtocol {
    func createIncident(
        type: IncidentType,
        severity: IncidentSeverity,
        bookingID: String?,
        notes: String?,
        photoURL: String?
    ) async throws -> Incident
    func getIncident(id: String) async throws -> Incident
    func resolveIncident(id: String, reason: String) async throws -> Incident
}

final class IncidentRepository: IncidentRepositoryProtocol {
    private let authInterceptor: AuthInterceptor

    init(authInterceptor: AuthInterceptor) {
        self.authInterceptor = authInterceptor
    }

    convenience init(apiClient: APIClient = APIClient(), tokenStore: TokenStore = KeychainStore()) {
        self.init(authInterceptor: AuthInterceptor(apiClient: apiClient, tokenStore: tokenStore))
    }

    func createIncident(
        type: IncidentType,
        severity: IncidentSeverity,
        bookingID: String?,
        notes: String?,
        photoURL: String?
    ) async throws -> Incident {
        let request = CreateIncidentRequest(
            type: type,
            severity: severity,
            bookingID: bookingID,
            notes: notes,
            photoURL: photoURL
        )
        let envelope: APIResponseEnvelope<Incident> = try await authInterceptor.perform(.incidents, body: request)
        return envelope.data
    }

    func getIncident(id: String) async throws -> Incident {
        let envelope: APIResponseEnvelope<Incident> = try await authInterceptor.perform(.incidentDetail(id: id))
        return envelope.data
    }

    func resolveIncident(id: String, reason: String) async throws -> Incident {
        let request = IncidentTransitionRequest(status: .resolved, reason: reason)
        let envelope: APIResponseEnvelope<Incident> = try await authInterceptor.perform(.incidentTransition(id: id), body: request)
        return envelope.data
    }
}
