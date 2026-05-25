import Foundation
import Observation

enum CancelActiveRoute: Equatable {
    case sos
}

@MainActor
@Observable
final class CancelActiveViewModel {
    var selectedReason: CancelActiveReason?
    var notes = ""
    private(set) var isSubmitting = false
    private(set) var didSubmit = false
    private(set) var route: CancelActiveRoute?
    private(set) var errorMessage: String?

    @ObservationIgnored private let bookingID: String
    @ObservationIgnored private let repository: IncidentRepositoryProtocol

    init(bookingID: String, repository: IncidentRepositoryProtocol = IncidentRepository()) {
        self.bookingID = bookingID
        self.repository = repository
    }

    func submit() async {
        guard let selectedReason else {
            errorMessage = "Choose a reason before cancelling."
            return
        }
        guard !isSubmitting else { return }

        if selectedReason == .petEmergency {
            route = .sos
            return
        }

        errorMessage = nil
        isSubmitting = true
        defer { isSubmitting = false }

        do {
            _ = try await repository.createIncident(
                type: .cancelActive,
                severity: selectedReason == .vehicleBrokeDown ? .high : .medium,
                bookingID: bookingID,
                notes: incidentNotes(for: selectedReason),
                photoURL: nil
            )
            didSubmit = true
        } catch let error as NetworkError {
            errorMessage = error.userMessage
        } catch {
            errorMessage = NetworkError.unknown(error.localizedDescription).userMessage
        }
    }

    private func incidentNotes(for reason: CancelActiveReason) -> String {
        let trimmedNotes = notes.trimmingCharacters(in: .whitespacesAndNewlines)
        if trimmedNotes.isEmpty {
            return reason.label
        }
        return "\(reason.label): \(trimmedNotes)"
    }
}
