import Foundation
import Observation

@Observable
final class JobDetailViewModel {
    private(set) var booking: Booking
    private(set) var isAccepting = false
    var acceptedBookingId: String?
    var errorMessage: String?

    @ObservationIgnored private let repository: BookingRepositoryProtocol

    init(booking: Booking, repository: BookingRepositoryProtocol) {
        self.booking = booking
        self.repository = repository
    }

    convenience init(booking: Booking) {
        self.init(booking: booking, repository: BookingRepository())
    }

    @MainActor
    func accept() async {
        errorMessage = nil
        isAccepting = true
        defer { isAccepting = false }

        do {
            let updated = try await repository.accept(id: booking.id)
            booking = updated
            acceptedBookingId = updated.id
        } catch let error as NetworkError {
            errorMessage = error.userMessage
        } catch {
            errorMessage = NetworkError.unknown(error.localizedDescription).userMessage
        }
    }
}
