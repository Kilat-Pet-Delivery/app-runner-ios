import Foundation
import Observation

@Observable
final class PetProfileViewModel {
    private(set) var pet: PetProfile?
    private(set) var isLoading = false
    var errorMessage: String?

    @ObservationIgnored private let bookingID: String
    @ObservationIgnored private let repository: PetProfileRepositoryProtocol

    init(bookingID: String, repository: PetProfileRepositoryProtocol = PetProfileRepository()) {
        self.bookingID = bookingID
        self.repository = repository
    }

    @MainActor
    func load() async {
        guard !isLoading else { return }
        isLoading = true
        errorMessage = nil
        defer { isLoading = false }

        do {
            pet = try await repository.fetchPet(bookingID: bookingID)
        } catch let error as NetworkError {
            errorMessage = error.userMessage
        } catch {
            errorMessage = NetworkError.unknown(error.localizedDescription).userMessage
        }
    }
}
