import Foundation
import Observation

@Observable
final class ApplyViewModel {
    var name = ""
    var phone = ""
    var icNumber = ""
    var vehicleType: VehicleType = .motorbike
    var plateNumber = ""
    var petExperience: Set<PetExperienceOption> = []
    var comfortableWithLivePets = true
    var consentAcknowledged = false
    private(set) var isSubmitting = false
    var submittedApplicationId: String?
    var errorMessage: String?

    var isSubmitEnabled: Bool {
        !name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty &&
        !phone.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty &&
        !icNumber.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty &&
        !plateNumber.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty &&
        !petExperience.isEmpty &&
        consentAcknowledged &&
        !isSubmitting
    }

    @ObservationIgnored private let repository: ApplicationRepositoryProtocol

    init(repository: ApplicationRepositoryProtocol = ApplicationRepository()) {
        self.repository = repository
    }

    func toggleExperience(_ option: PetExperienceOption) {
        if petExperience.contains(option) {
            petExperience.remove(option)
        } else {
            petExperience.insert(option)
        }
    }

    func makeRequest() -> RunnerApplicationRequest {
        RunnerApplicationRequest(
            name: name.trimmingCharacters(in: .whitespacesAndNewlines),
            phone: normalizedPhone,
            icNumber: icNumber.trimmingCharacters(in: .whitespacesAndNewlines),
            vehicleType: vehicleType,
            plateNumber: plateNumber.trimmingCharacters(in: .whitespacesAndNewlines).uppercased(),
            petExperience: petExperience.map(\.rawValue).sorted(),
            comfortableWithLivePets: comfortableWithLivePets,
            consentAcknowledged: consentAcknowledged
        )
    }

    @MainActor
    func submit() async {
        errorMessage = nil

        guard isSubmitEnabled else {
            errorMessage = "Complete the form and accept the consent."
            return
        }

        isSubmitting = true
        defer { isSubmitting = false }

        do {
            let response = try await repository.apply(makeRequest())
            submittedApplicationId = response.applicationId
        } catch let error as NetworkError {
            errorMessage = error.userMessage
        } catch {
            errorMessage = NetworkError.unknown(error.localizedDescription).userMessage
        }
    }

    private var normalizedPhone: String {
        let trimmed = phone.trimmingCharacters(in: .whitespacesAndNewlines)
        if trimmed.hasPrefix("+60") { return trimmed }
        if trimmed.hasPrefix("0") { return "+6\(trimmed)" }
        return "+60\(trimmed)"
    }
}
