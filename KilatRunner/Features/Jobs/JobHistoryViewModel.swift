import Foundation
import Observation

struct JobHistoryDaySection: Identifiable, Equatable {
    let id: Date
    let title: String
    let bookings: [Booking]
}

@MainActor
@Observable
final class JobHistoryViewModel {
    var filter: BookingHistoryFilter = .all
    private(set) var bookings: [Booking] = []
    private(set) var nextCursor: String?
    private(set) var isLoading = false
    private(set) var errorMessage: String?

    @ObservationIgnored private let repository: BookingRepositoryProtocol
    @ObservationIgnored private let pageLimit: Int
    @ObservationIgnored private let calendar: Calendar

    var hasMore: Bool {
        nextCursor != nil
    }

    var deliveriesThisMonth: Int {
        bookings.filter { $0.status == .completed || $0.status == .delivered }.count
    }

    var totalEarningsCents: Int64 {
        bookings.reduce(0) { $0 + ($1.finalPriceCents ?? $1.estimatedPriceCents) }
    }

    var sections: [JobHistoryDaySection] {
        let grouped = Dictionary(grouping: bookings) { booking in
            calendar.startOfDay(for: booking.deliveredAt ?? booking.cancelledAt ?? booking.updatedAt)
        }
        return grouped.keys.sorted(by: >).map { day in
            let dayBookings = grouped[day, default: []].sorted { $0.updatedAt > $1.updatedAt }
            return JobHistoryDaySection(id: day, title: Self.dayFormatter.string(from: day), bookings: dayBookings)
        }
    }

    init(
        repository: BookingRepositoryProtocol = BookingRepository(),
        pageLimit: Int = 20,
        calendar: Calendar = .current
    ) {
        self.repository = repository
        self.pageLimit = pageLimit
        self.calendar = calendar
    }

    func loadFirstPage() async {
        bookings = []
        nextCursor = nil
        await load(cursor: nil, replacesExisting: true)
    }

    func applyFilter(_ filter: BookingHistoryFilter) async {
        guard self.filter != filter else { return }
        self.filter = filter
        await loadFirstPage()
    }

    func loadMore() async {
        guard let nextCursor, !nextCursor.isEmpty else { return }
        await load(cursor: nextCursor, replacesExisting: false)
    }

    private func load(cursor: String?, replacesExisting: Bool) async {
        guard !isLoading else { return }
        errorMessage = nil
        isLoading = true
        defer { isLoading = false }

        do {
            let page = try await repository.fetchHistory(filter: filter, cursor: cursor, limit: pageLimit)
            bookings = replacesExisting ? page.items : appendDeduplicated(page.items)
            nextCursor = page.nextCursor.isEmpty ? nil : page.nextCursor
        } catch let error as NetworkError {
            errorMessage = error.userMessage
        } catch {
            errorMessage = NetworkError.unknown(error.localizedDescription).userMessage
        }
    }

    private func appendDeduplicated(_ newItems: [Booking]) -> [Booking] {
        var seen = Set(bookings.map(\.id))
        var merged = bookings
        for item in newItems where !seen.contains(item.id) {
            merged.append(item)
            seen.insert(item.id)
        }
        return merged
    }

    private static let dayFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .none
        return formatter
    }()
}
