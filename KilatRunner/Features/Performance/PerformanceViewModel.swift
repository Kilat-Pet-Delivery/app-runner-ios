import Foundation
import Observation

@MainActor
@Observable
final class PerformanceViewModel {
    private(set) var state: PerformanceDashboardState?
    private(set) var isLoading = false
    var errorMessage: String?

    @ObservationIgnored private let repository: PerformanceRepositoryProtocol
    @ObservationIgnored private let calendar: Calendar
    @ObservationIgnored private let today: () -> Date

    init(
        repository: PerformanceRepositoryProtocol = PerformanceRepository(),
        calendar: Calendar = Calendar(identifier: .gregorian),
        today: @escaping () -> Date = Date.init
    ) {
        self.repository = repository
        self.calendar = calendar
        self.today = today
    }

    func load() async {
        errorMessage = nil
        isLoading = true
        defer { isLoading = false }

        do {
            let tier = try await repository.fetchTier()
            state = PerformanceDashboardState(
                tier: tier,
                weeklyOnTime: makeWeeklyOnTimeBars(rate: tier.onTimeRate, today: today())
            )
        } catch let error as NetworkError {
            errorMessage = error.userMessage
        } catch {
            errorMessage = NetworkError.unknown(error.localizedDescription).userMessage
        }
    }

    func makeWeeklyOnTimeBars(rate: Double, today: Date) -> [PerformanceBarData] {
        let base = min(100, max(0, rate * 100))
        return (0..<7).compactMap { offset in
            guard let day = calendar.date(byAdding: .day, value: offset - 6, to: today) else { return nil }
            let label = day.formatted(.dateTime.weekday(.abbreviated))
            let variation = Double(offset - 3)
            return PerformanceBarData(
                id: label,
                label: label,
                value: min(100, max(0, base + variation)),
                highlight: calendar.isDate(day, inSameDayAs: today)
            )
        }
    }
}
