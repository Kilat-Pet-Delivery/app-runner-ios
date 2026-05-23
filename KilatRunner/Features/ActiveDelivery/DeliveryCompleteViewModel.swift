import Foundation
import Observation

@MainActor
@Observable
final class DeliveryCompleteViewModel {
    static let availableTags = ["Friendly", "On time", "Clear instructions", "Tipped", "Difficult location"]

    var rating = 5
    private(set) var selectedTags: [String] = []
    private(set) var isSubmitting = false
    private(set) var didComplete = false
    private(set) var errorMessage: String?

    @ObservationIgnored private let completeHandler: (CustomerRatingRequest) async throws -> Booking

    init(completeHandler: @escaping (CustomerRatingRequest) async throws -> Booking) {
        self.completeHandler = completeHandler
    }

    convenience init(bookingID: String, repository: BookingRepositoryProtocol = BookingRepository()) {
        self.init { request in
            _ = try await repository.rateCustomer(id: bookingID, rating: request)
            return try await repository.completeDelivery(id: bookingID)
        }
    }

    func toggleTag(_ tag: String) {
        if selectedTags.contains(tag) {
            selectedTags.removeAll { $0 == tag }
        } else if selectedTags.count < 5 {
            selectedTags.append(tag)
        }
    }

    func complete() async {
        guard !isSubmitting else { return }
        errorMessage = nil
        isSubmitting = true
        defer { isSubmitting = false }

        do {
            _ = try await completeHandler(CustomerRatingRequest(rating: rating, tags: selectedTags))
            didComplete = true
        } catch let error as NetworkError {
            errorMessage = error.userMessage
        } catch {
            errorMessage = NetworkError.unknown(error.localizedDescription).userMessage
        }
    }
}
