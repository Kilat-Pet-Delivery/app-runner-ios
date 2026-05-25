import Foundation
import Observation

enum AvailableJobsSort: String, CaseIterable, Identifiable {
    case bestPay
    case nearest
    case quickest

    var id: String { rawValue }

    var label: String {
        switch self {
        case .bestPay:  return "Best pay"
        case .nearest:  return "Nearest"
        case .quickest: return "Quickest"
        }
    }
}

@Observable
final class AvailableJobsViewModel {
    var jobs: [Booking] = []
    private(set) var isLoading = false
    var errorMessage: String?
    var selectedSort: AvailableJobsSort = .bestPay
    private(set) var searchRadiusKm = 8
    private(set) var isCreatingJobAlert = false
    var noticeMessage: String?

    var sortedJobs: [Booking] {
        switch selectedSort {
        case .bestPay:
            return jobs.sorted { (lhs, rhs) in
                let l = lhs.finalPriceCents ?? lhs.estimatedPriceCents
                let r = rhs.finalPriceCents ?? rhs.estimatedPriceCents
                return l > r
            }
        case .nearest:
            return jobs.sorted { (lhs, rhs) in
                (lhs.distanceKm ?? .greatestFiniteMagnitude) < (rhs.distanceKm ?? .greatestFiniteMagnitude)
            }
        case .quickest:
            return jobs.sorted { (lhs, rhs) in
                (lhs.distanceKm ?? .greatestFiniteMagnitude) < (rhs.distanceKm ?? .greatestFiniteMagnitude)
            }
        }
    }

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

    @MainActor
    func widenRadius() {
        searchRadiusKm += 4
        noticeMessage = "Search radius widened to \(searchRadiusKm) km."
    }

    @MainActor
    func createJobAlert() async {
        guard !isCreatingJobAlert else { return }
        noticeMessage = nil
        errorMessage = nil
        isCreatingJobAlert = true
        defer { isCreatingJobAlert = false }

        do {
            try await repository.createJobAlert(radiusKm: searchRadiusKm)
            noticeMessage = "We'll notify you when jobs are available nearby."
        } catch let error as NetworkError {
            errorMessage = error.userMessage
        } catch {
            errorMessage = NetworkError.unknown(error.localizedDescription).userMessage
        }
    }
}
