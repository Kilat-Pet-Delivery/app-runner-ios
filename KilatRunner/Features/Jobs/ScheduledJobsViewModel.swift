import Foundation
import Observation

enum ScheduledJobsBucket: String, CaseIterable, Identifiable, Equatable {
    case tomorrow
    case thisWeek
    case nextWeek
    case later

    var id: String { rawValue }

    var title: String {
        switch self {
        case .tomorrow: return "Tomorrow"
        case .thisWeek: return "This week"
        case .nextWeek: return "Next week"
        case .later: return "Later"
        }
    }
}

struct ScheduledJobsSection: Identifiable, Equatable {
    let bucket: ScheduledJobsBucket
    let bookings: [Booking]

    var id: ScheduledJobsBucket { bucket }
}

@MainActor
@Observable
final class ScheduledJobsViewModel {
    private(set) var bookings: [Booking] = []
    private(set) var isLoading = false
    private(set) var errorMessage: String?

    @ObservationIgnored private let repository: BookingRepositoryProtocol
    @ObservationIgnored private let now: () -> Date
    @ObservationIgnored private let calendar: Calendar

    var sections: [ScheduledJobsSection] {
        let grouped = Dictionary(grouping: bookings, by: bucket(for:))
        return ScheduledJobsBucket.allCases.compactMap { bucket in
            let bookings = grouped[bucket, default: []].sorted { scheduledDate(for: $0) < scheduledDate(for: $1) }
            return bookings.isEmpty ? nil : ScheduledJobsSection(bucket: bucket, bookings: bookings)
        }
    }

    init(
        repository: BookingRepositoryProtocol = BookingRepository(),
        now: @escaping () -> Date = Date.init,
        calendar: Calendar = .current
    ) {
        self.repository = repository
        self.now = now
        self.calendar = calendar
    }

    func load() async {
        guard !isLoading else { return }
        errorMessage = nil
        isLoading = true
        defer { isLoading = false }

        do {
            bookings = try await repository.fetchScheduled()
        } catch let error as NetworkError {
            errorMessage = error.userMessage
        } catch {
            errorMessage = NetworkError.unknown(error.localizedDescription).userMessage
        }
    }

    func scheduledDate(for booking: Booking) -> Date {
        booking.scheduledAt ?? booking.createdAt
    }

    private func bucket(for booking: Booking) -> ScheduledJobsBucket {
        let today = calendar.startOfDay(for: now())
        let date = calendar.startOfDay(for: scheduledDate(for: booking))
        let days = calendar.dateComponents([.day], from: today, to: date).day ?? 0

        if days == 1 {
            return .tomorrow
        }
        if days <= 7 {
            return .thisWeek
        }
        if days <= 14 {
            return .nextWeek
        }
        return .later
    }
}
