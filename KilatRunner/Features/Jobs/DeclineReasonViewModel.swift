import Foundation
import Observation

@Observable
final class DeclineReasonViewModel: Identifiable {
    let id = UUID()
    let bookingID: String
    private(set) var isSubmitting = false
    var selectedReason: DeclineReason?
    var didDismiss = false
    var errorMessage: String?

    @ObservationIgnored private let repository: BookingRepositoryProtocol

    init(bookingID: String, repository: BookingRepositoryProtocol = BookingRepository()) {
        self.bookingID = bookingID
        self.repository = repository
    }

    @MainActor
    func select(_ reason: DeclineReason) async {
        selectedReason = reason
        await submit(reason)
    }

    @MainActor
    func skip() async {
        await submit(.other)
    }

    @MainActor
    private func submit(_ reason: DeclineReason) async {
        errorMessage = nil
        isSubmitting = true
        defer { isSubmitting = false }

        do {
            try await repository.decline(id: bookingID, reason: reason)
            didDismiss = true
        } catch let error as NetworkError {
            errorMessage = error.userMessage
        } catch {
            errorMessage = NetworkError.unknown(error.localizedDescription).userMessage
        }
    }
}
