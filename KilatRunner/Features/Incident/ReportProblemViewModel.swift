import Foundation
import Observation

@MainActor
@Observable
final class ReportProblemViewModel {
    var selectedIssue: ReportProblemIssue?
    var notes = ""
    var photoData: Data?
    private(set) var isSubmitting = false
    private(set) var didSubmit = false
    private(set) var errorMessage: String?

    @ObservationIgnored private let bookingID: String
    @ObservationIgnored private let repository: IncidentRepositoryProtocol
    @ObservationIgnored private let photoUploader: PhotoUploading

    init(
        bookingID: String,
        repository: IncidentRepositoryProtocol = IncidentRepository(),
        photoUploader: PhotoUploading = PhotoUploader()
    ) {
        self.bookingID = bookingID
        self.repository = repository
        self.photoUploader = photoUploader
    }

    func submit() async {
        guard let selectedIssue else {
            errorMessage = "Choose what went wrong."
            return
        }
        guard !isSubmitting else { return }

        errorMessage = nil
        isSubmitting = true
        defer { isSubmitting = false }

        do {
            let photoURL: String?
            if let photoData {
                photoURL = try await photoUploader.upload(data: photoData, fileName: "incident-photo.jpg")
            } else {
                photoURL = nil
            }
            _ = try await repository.createIncident(
                type: .problemReport,
                severity: severity(for: selectedIssue),
                bookingID: bookingID,
                notes: incidentNotes(for: selectedIssue),
                photoURL: photoURL
            )
            didSubmit = true
        } catch let error as NetworkError {
            errorMessage = error.userMessage
        } catch {
            errorMessage = NetworkError.unknown(error.localizedDescription).userMessage
        }
    }

    private func severity(for issue: ReportProblemIssue) -> IncidentSeverity {
        switch issue {
        case .petUnwell: return .high
        case .vendorNotReady, .wrongItem, .locationWrong: return .medium
        case .traffic, .other: return .low
        }
    }

    private func incidentNotes(for issue: ReportProblemIssue) -> String {
        let trimmedNotes = notes.trimmingCharacters(in: .whitespacesAndNewlines)
        if trimmedNotes.isEmpty {
            return issue.label
        }
        return "\(issue.label): \(trimmedNotes)"
    }
}
