import CoreLocation
import Foundation
import Observation

enum DeliveryPhase: Equatable {
    case enroute
    case pickedUp
    case delivered
}

@MainActor
@Observable
final class ActiveDeliveryViewModel {
    private(set) var booking: Booking
    var currentLocation: CLLocationCoordinate2D?
    private(set) var deliveryPhase: DeliveryPhase = .enroute
    private(set) var isMarkingPickup = false
    private(set) var isMarkingDelivered = false
    var errorMessage: String?

    @ObservationIgnored private let locationProvider: LocationProvider
    @ObservationIgnored private let runnerRepository: RunnerRepositoryProtocol
    @ObservationIgnored private let bookingRepository: BookingRepositoryProtocol
    @ObservationIgnored private let webSocketClient: RealtimeTrackingClient
    @ObservationIgnored private let tokenStore: TokenStore
    @ObservationIgnored private let wsBaseURL: URL
    @ObservationIgnored private let buffer: WaypointBuffer
    @ObservationIgnored private var locationStreamTask: Task<Void, Never>?
    @ObservationIgnored private var webSocketStreamTask: Task<Void, Never>?

    var pickupCoordinate: CLLocationCoordinate2D { booking.pickupCoordinate }
    var dropoffCoordinate: CLLocationCoordinate2D { booking.dropoffCoordinate }

    init(
        booking: Booking,
        locationProvider: LocationProvider,
        runnerRepository: RunnerRepositoryProtocol,
        bookingRepository: BookingRepositoryProtocol = BookingRepository(),
        webSocketClient: RealtimeTrackingClient? = nil,
        tokenStore: TokenStore = KeychainStore(),
        wsBaseURL: URL = AppEnvironment.wsBaseURL
    ) {
        self.booking = booking
        self.locationProvider = locationProvider
        self.runnerRepository = runnerRepository
        self.bookingRepository = bookingRepository
        self.webSocketClient = webSocketClient ?? WebSocketClient()
        self.tokenStore = tokenStore
        self.wsBaseURL = wsBaseURL
        self.buffer = WaypointBuffer { batch in
            for waypoint in batch {
                try? await runnerRepository.postLocation(
                    RunnerLocationWaypoint(
                        latitude: waypoint.latitude,
                        longitude: waypoint.longitude,
                        speedKmh: waypoint.speedKmh,
                        headingDegrees: waypoint.headingDegrees
                    )
                )
            }
        }
    }

    convenience init(booking: Booking) {
        self.init(
            booking: booking,
            locationProvider: LocationManager(),
            runnerRepository: RunnerRepository(),
            bookingRepository: BookingRepository(),
            webSocketClient: WebSocketClient(),
            tokenStore: KeychainStore(),
            wsBaseURL: AppEnvironment.wsBaseURL
        )
    }

    func onAppear() {
        guard locationStreamTask == nil else { return }
        locationProvider.startUpdates()
        let provider = locationProvider
        locationStreamTask = Task { [weak self] in
            for await location in provider.locationUpdates {
                await self?.handleLocation(location)
            }
        }
        startWebSocket()
    }

    func onDisappear() async {
        locationProvider.stopUpdates()
        locationStreamTask?.cancel()
        locationStreamTask = nil
        webSocketClient.disconnect()
        webSocketStreamTask?.cancel()
        webSocketStreamTask = nil
        await buffer.forceFlush()
    }

    func onDeliveryCompleted() async {
        deliveryPhase = .delivered
        await stopRealtimeAndFlush()
    }

    func markPickup() async {
        guard deliveryPhase == .enroute, !isMarkingPickup else { return }
        errorMessage = nil
        isMarkingPickup = true
        defer { isMarkingPickup = false }

        do {
            let updated = try await bookingRepository.markPickup(id: booking.id)
            booking = updated
            deliveryPhase = .pickedUp
        } catch let error as NetworkError {
            errorMessage = error.userMessage
        } catch {
            errorMessage = NetworkError.unknown(error.localizedDescription).userMessage
        }
    }

    func markDelivered() async {
        guard deliveryPhase == .pickedUp, !isMarkingDelivered else { return }
        errorMessage = nil
        isMarkingDelivered = true
        defer { isMarkingDelivered = false }

        do {
            let updated = try await bookingRepository.markDelivered(id: booking.id)
            booking = updated
            deliveryPhase = .delivered
            await stopRealtimeAndFlush()
        } catch let error as NetworkError {
            errorMessage = error.userMessage
        } catch {
            errorMessage = NetworkError.unknown(error.localizedDescription).userMessage
        }
    }

    private func handleLocation(_ location: CLLocation) async {
        currentLocation = location.coordinate
        let waypoint = Waypoint(
            latitude: location.coordinate.latitude,
            longitude: location.coordinate.longitude,
            speedKmh: max(0, location.speed * 3.6),
            headingDegrees: max(0, location.course),
            timestamp: location.timestamp
        )
        await buffer.add(waypoint)
    }

    private func startWebSocket() {
        guard webSocketStreamTask == nil else { return }
        guard let url = trackingURL() else { return }
        let client = webSocketClient
        webSocketStreamTask = Task { [weak self] in
            do {
                try await client.connect(url: url)
                for await data in client.messages {
                    self?.handleTrackingData(data)
                }
            } catch {
                await MainActor.run {
                    self?.errorMessage = "Could not connect to live tracking."
                }
            }
        }
    }

    private func trackingURL() -> URL? {
        guard let token = tokenStore.accessToken() else { return nil }
        var url = wsBaseURL.appending(path: "ws/tracking/\(booking.id)")
        guard var components = URLComponents(url: url, resolvingAgainstBaseURL: false) else {
            return nil
        }
        components.queryItems = [URLQueryItem(name: "token", value: token)]
        url = components.url ?? url
        return url
    }

    private func handleTrackingData(_ data: Data) {
        let decoder = JSONDecoder()
        decoder.keyDecodingStrategy = .convertFromSnakeCase
        decoder.dateDecodingStrategy = .iso8601
        guard let update = try? decoder.decode(TrackingUpdate.self, from: data) else {
            return
        }
        currentLocation = CLLocationCoordinate2D(latitude: update.latitude, longitude: update.longitude)
    }

    private func stopRealtimeAndFlush() async {
        locationProvider.stopUpdates()
        locationStreamTask?.cancel()
        locationStreamTask = nil
        webSocketClient.disconnect()
        webSocketStreamTask?.cancel()
        webSocketStreamTask = nil
        await buffer.forceFlush()
    }
}
