import CoreLocation
import Foundation
import Observation

struct RunnerCoordinate: Equatable {
    let latitude: Double
    let longitude: Double
}

protocol LocationPermissionProvider {
    func requestAlwaysAuthorization() async -> Bool
    func currentCoordinate() async -> RunnerCoordinate?
}

final class CoreLocationPermissionProvider: LocationPermissionProvider {
    private let locationManager = CLLocationManager()

    func requestAlwaysAuthorization() async -> Bool {
        switch locationManager.authorizationStatus {
        case .authorizedAlways:
            return true
        case .authorizedWhenInUse:
            locationManager.requestAlwaysAuthorization()
            return true
        case .notDetermined:
            locationManager.requestWhenInUseAuthorization()
            return false
        case .denied, .restricted:
            return false
        @unknown default:
            return false
        }
    }

    func currentCoordinate() async -> RunnerCoordinate? {
        guard let coordinate = locationManager.location?.coordinate else {
            return nil
        }

        return RunnerCoordinate(latitude: coordinate.latitude, longitude: coordinate.longitude)
    }
}

struct DashboardActiveJob: Equatable {
    let bookingId: String
    let pickupAddress: String
    let dropoffAddress: String
}

@Observable
final class DashboardViewModel {
    var runner: Runner?
    var isOnline = false
    var errorMessage: String?
    private(set) var isLoading = false
    private(set) var isTogglingOnline = false

    var weeklyEarningsCents: Int = 0
    var weeklyGoalCents: Int = 50_000
    var deliveriesThisWeek: Int = 0
    var onlineMinutesThisWeek: Int = 0
    var activeJob: DashboardActiveJob? = nil
    var upcomingScheduledBooking: Booking? = nil
    var topQuest: RunnerQuest? = nil

    var weeklyGoalProgress: Double {
        guard weeklyGoalCents > 0 else { return 0 }
        return min(1.0, Double(weeklyEarningsCents) / Double(weeklyGoalCents))
    }

    @ObservationIgnored private let repository: RunnerRepositoryProtocol
    @ObservationIgnored private let bookingRepository: BookingRepositoryProtocol
    @ObservationIgnored private let loyaltyRepository: LoyaltyRepositoryProtocol
    @ObservationIgnored private let locationPermissionProvider: LocationPermissionProvider

    init(
        repository: RunnerRepositoryProtocol,
        locationPermissionProvider: LocationPermissionProvider,
        bookingRepository: BookingRepositoryProtocol = BookingRepository(),
        loyaltyRepository: LoyaltyRepositoryProtocol = LoyaltyRepository()
    ) {
        self.repository = repository
        self.locationPermissionProvider = locationPermissionProvider
        self.bookingRepository = bookingRepository
        self.loyaltyRepository = loyaltyRepository
    }

    convenience init() {
        self.init(
            repository: RunnerRepository(),
            locationPermissionProvider: CoreLocationPermissionProvider(),
            bookingRepository: BookingRepository(),
            loyaltyRepository: LoyaltyRepository()
        )
    }

    @MainActor
    func loadRunner() async {
        errorMessage = nil
        isLoading = true
        defer { isLoading = false }

        do {
            let runner = try await repository.getMe()
            self.runner = runner
            isOnline = runner.isOnline
        } catch let error as NetworkError {
            errorMessage = error.userMessage
        } catch {
            errorMessage = NetworkError.unknown(error.localizedDescription).userMessage
        }
    }

    @MainActor
    func loadScheduledHint(now: Date = Date()) async {
        do {
            let scheduled = try await bookingRepository.fetchScheduled()
            upcomingScheduledBooking = scheduled
                .filter { booking in
                    guard let scheduledAt = booking.scheduledAt else { return false }
                    return scheduledAt >= now && scheduledAt <= now.addingTimeInterval(24 * 60 * 60)
                }
                .sorted { ($0.scheduledAt ?? .distantFuture) < ($1.scheduledAt ?? .distantFuture) }
                .first
        } catch {
            upcomingScheduledBooking = nil
        }
    }

    @MainActor
    func loadQuestHint() async {
        do {
            let response = try await loyaltyRepository.fetchQuests()
            topQuest = (response.daily + response.weekly).first { $0.status == .active || $0.status == .completed }
        } catch {
            topQuest = nil
        }
    }

    @MainActor
    func toggleOnline() async {
        guard !isTogglingOnline else {
            return
        }

        errorMessage = nil
        isTogglingOnline = true
        defer { isTogglingOnline = false }

        if isOnline {
            await goOffline()
        } else {
            await goOnline()
        }
    }

    @MainActor
    private func goOnline() async {
        let permissionGranted = await locationPermissionProvider.requestAlwaysAuthorization()
        guard permissionGranted else {
            errorMessage = "Allow always-on location access to go online."
            return
        }

        guard let coordinate = await locationPermissionProvider.currentCoordinate() else {
            errorMessage = "Current location is not available yet."
            return
        }

        do {
            try await repository.goOnline(
                latitude: coordinate.latitude,
                longitude: coordinate.longitude
            )
            isOnline = true
        } catch let error as NetworkError {
            errorMessage = error.userMessage
        } catch {
            errorMessage = NetworkError.unknown(error.localizedDescription).userMessage
        }
    }

    @MainActor
    private func goOffline() async {
        do {
            try await repository.goOffline()
            isOnline = false
        } catch let error as NetworkError {
            errorMessage = error.userMessage
        } catch {
            errorMessage = NetworkError.unknown(error.localizedDescription).userMessage
        }
    }
}
