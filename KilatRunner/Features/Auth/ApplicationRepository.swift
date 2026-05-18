import Foundation

protocol ApplicationRepositoryProtocol {
    func apply(_ request: RunnerApplicationRequest) async throws -> RunnerApplicationResponse
}

final class ApplicationRepository: ApplicationRepositoryProtocol {
    private let apiClient: APIClient

    init(apiClient: APIClient = APIClient(encoder: APIClient.makeCamelCaseEncoder())) {
        self.apiClient = apiClient
    }

    func apply(_ request: RunnerApplicationRequest) async throws -> RunnerApplicationResponse {
        let envelope: APIResponseEnvelope<RunnerApplicationResponse> = try await apiClient.request(
            .runnerApply,
            body: request
        )
        return envelope.data
    }
}

enum VehicleType: String, CaseIterable, Identifiable, Encodable {
    case motorbike
    case car
    case bicycle

    var id: String { rawValue }

    var label: String {
        switch self {
        case .motorbike: return "Motorbike"
        case .car: return "Car"
        case .bicycle: return "Bicycle"
        }
    }
}

enum PetExperienceOption: String, CaseIterable, Identifiable, Encodable {
    case dogs
    case cats
    case birds
    case fish
    case smallPets = "small_pets"
    case vetTrips = "vet_trips"

    var id: String { rawValue }

    var label: String {
        switch self {
        case .dogs: return "Dogs"
        case .cats: return "Cats"
        case .birds: return "Birds"
        case .fish: return "Fish"
        case .smallPets: return "Small pets"
        case .vetTrips: return "Vet trips"
        }
    }
}

struct RunnerApplicationRequest: Encodable, Equatable {
    let name: String
    let phone: String
    let icNumber: String
    let vehicleType: VehicleType
    let plateNumber: String
    let petExperience: [String]
    let comfortableWithLivePets: Bool
    let consentAcknowledged: Bool
}

struct RunnerApplicationResponse: Decodable, Equatable {
    let applicationId: String
}
