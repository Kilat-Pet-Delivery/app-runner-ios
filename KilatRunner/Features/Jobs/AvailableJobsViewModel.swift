import Foundation
import Observation

@Observable
final class AvailableJobsViewModel {
    private(set) var jobs: [Booking] = []
    private(set) var isLoading = false
    var errorMessage: String?

    @ObservationIgnored private let repository: BookingRepositoryProtocol

    init(repository: BookingRepositoryProtocol) {
        self.repository = repository
    }

    convenience init() {
        self.init(repository: BookingRepository())
    }

    @MainActor
    func load() async {
        errorMessage = nil
        isLoading = true
        defer { isLoading = false }

        do {
            jobs = try await repository.listAvailable()
        } catch let error as NetworkError {
            errorMessage = error.userMessage
        } catch {
            errorMessage = NetworkError.unknown(error.localizedDescription).userMessage
        }
    }

    @MainActor
    func refresh() async {
        await load()
    }
}
