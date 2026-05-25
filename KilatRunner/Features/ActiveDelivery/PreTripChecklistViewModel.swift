import Foundation
import Observation

enum PreTripChecklistItem: String, CaseIterable, Identifiable, Encodable {
    case carrierSecured
    case strapsSecure
    case waterReady
    case phoneCharged
    case vetNumberSaved

    var id: String { rawValue }

    var title: String {
        switch self {
        case .carrierSecured: return "Carrier secured"
        case .strapsSecure: return "Straps secure"
        case .waterReady: return "Water ready"
        case .phoneCharged: return "Phone charged"
        case .vetNumberSaved: return "Vet number saved"
        }
    }
}

protocol PreTripChecklistRepositoryProtocol {
    func submit(bookingID: String, checkedItems: [PreTripChecklistItem]) async throws
}

final class PreTripChecklistRepository: PreTripChecklistRepositoryProtocol {
    private let authInterceptor: AuthInterceptor

    init(authInterceptor: AuthInterceptor) {
        self.authInterceptor = authInterceptor
    }

    convenience init(apiClient: APIClient = APIClient(), tokenStore: TokenStore = KeychainStore()) {
        self.init(authInterceptor: AuthInterceptor(apiClient: apiClient, tokenStore: tokenStore))
    }

    func submit(bookingID: String, checkedItems: [PreTripChecklistItem]) async throws {
        let _: EmptyResponse = try await authInterceptor.perform(
            .preTripChecklist(id: bookingID),
            body: PreTripChecklistRequest(items: checkedItems.map(\.rawValue))
        )
    }
}

struct PreTripChecklistRequest: Encodable, Equatable {
    let items: [String]
}

@MainActor
@Observable
final class PreTripChecklistViewModel {
    private(set) var checkedItems: Set<PreTripChecklistItem> = []
    private(set) var isSubmitting = false
    private(set) var didSubmit = false
    var errorMessage: String?

    var isReady: Bool {
        checkedItems.count == PreTripChecklistItem.allCases.count && !isSubmitting
    }

    @ObservationIgnored private let bookingID: String
    @ObservationIgnored private let repository: PreTripChecklistRepositoryProtocol

    init(
        bookingID: String,
        repository: PreTripChecklistRepositoryProtocol = PreTripChecklistRepository()
    ) {
        self.bookingID = bookingID
        self.repository = repository
    }

    func toggle(_ item: PreTripChecklistItem) {
        if checkedItems.contains(item) {
            checkedItems.remove(item)
        } else {
            checkedItems.insert(item)
        }
    }

    func submit() async {
        guard isReady else { return }
        errorMessage = nil
        isSubmitting = true
        defer { isSubmitting = false }

        do {
            try await repository.submit(
                bookingID: bookingID,
                checkedItems: PreTripChecklistItem.allCases.filter { checkedItems.contains($0) }
            )
            didSubmit = true
        } catch let error as NetworkError {
            errorMessage = error.userMessage
        } catch {
            errorMessage = NetworkError.unknown(error.localizedDescription).userMessage
        }
    }
}
