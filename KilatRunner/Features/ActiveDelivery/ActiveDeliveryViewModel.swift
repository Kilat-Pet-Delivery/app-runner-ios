import CoreLocation
import Foundation
import Observation

enum DeliveryPhase: Equatable {
    case enroute
    case pickedUp
    case proofSubmitted
    case delivered
}

enum ActiveDeliveryPresentationStage: String, Equatable {
    case toPickup
    case arrivedAtPickup
    case pickedUp
    case toDropoff
    case arrivedAtDropoff
    case proofSubmitted
    case complete

    static var atPickup: Self { .arrivedAtPickup }
    static var atDropoff: Self { .arrivedAtDropoff }
    static var delivered: Self { .complete }
}

@MainActor
@Observable
final class ActiveDeliveryViewModel {
    var booking: Booking
    var currentLocation: CLLocationCoordinate2D?
    var deliveryPhase: DeliveryPhase = .enroute
    private(set) var isMarkingPickup = false
    private(set) var isMarkingDelivered = false
    private(set) var isSubmittingProof = false
    private(set) var isCompletingDelivery = false
    var errorMessage: String?
    var hasArrivedAtCurrentWaypoint: Bool = false

    var presentationStage: ActiveDeliveryPresentationStage {
        switch (deliveryPhase, hasArrivedAtCurrentWaypoint) {
        case (.enroute, false):   return .toPickup
        case (.enroute, true):    return .arrivedAtPickup
        case (.pickedUp, false):  return .toDropoff
        case (.pickedUp, true):   return .arrivedAtDropoff
        case (.proofSubmitted, _): return .proofSubmitted
        case (.delivered, _):     return .complete
        }
    }

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

    func queuedWaypointCount() async -> Int {
        await buffer.queuedCount()
    }

    func markPickup() async {
        await markPickedUp()
    }

    func arriveAtPickup() async {
        guard presentationStage == .toPickup, !isMarkingPickup else { return }
        errorMessage = nil
        isMarkingPickup = true
        defer { isMarkingPickup = false }

        do {
            let updated = try await bookingRepository.arriveAtPickup(id: booking.id)
            booking = updated
            hasArrivedAtCurrentWaypoint = true
        } catch let error as NetworkError {
            errorMessage = error.userMessage
        } catch {
            errorMessage = NetworkError.unknown(error.localizedDescription).userMessage
        }
    }

    func markPickedUp(qrCode: String? = nil) async {
        guard presentationStage == .arrivedAtPickup, !isMarkingPickup else { return }
        errorMessage = nil
        isMarkingPickup = true
        defer { isMarkingPickup = false }

        do {
            let updated = try await bookingRepository.markPickedUp(id: booking.id, qrCode: qrCode)
            booking = updated
            deliveryPhase = .pickedUp
            hasArrivedAtCurrentWaypoint = false
        } catch let error as NetworkError {
            errorMessage = error.userMessage
        } catch {
            errorMessage = NetworkError.unknown(error.localizedDescription).userMessage
        }
    }

    func arriveAtDropoff() async {
        guard presentationStage == .toDropoff, !isMarkingDelivered else { return }
        errorMessage = nil
        isMarkingDelivered = true
        defer { isMarkingDelivered = false }

        do {
            let updated = try await bookingRepository.arriveAtDropoff(id: booking.id)
            booking = updated
            hasArrivedAtCurrentWaypoint = true
        } catch let error as NetworkError {
            errorMessage = error.userMessage
        } catch {
            errorMessage = NetworkError.unknown(error.localizedDescription).userMessage
        }
    }

    @discardableResult
    func submitProofOfDelivery(_ proof: ProofOfDeliveryRequest) async throws -> Booking {
        guard presentationStage == .arrivedAtDropoff, !isSubmittingProof else {
            throw NetworkError.invalidResponse
        }
        errorMessage = nil
        isSubmittingProof = true
        defer { isSubmittingProof = false }

        do {
            let updated = try await bookingRepository.submitProofOfDelivery(id: booking.id, proof: proof)
            booking = updated
            deliveryPhase = .proofSubmitted
            hasArrivedAtCurrentWaypoint = false
            return updated
        } catch let error as NetworkError {
            errorMessage = error.userMessage
            throw error
        } catch {
            let networkError = NetworkError.unknown(error.localizedDescription)
            errorMessage = networkError.userMessage
            throw networkError
        }
    }

    func markDelivered() async {
        await completeDelivery()
    }

    @discardableResult
    func completeDelivery() async -> Booking? {
        guard (presentationStage == .proofSubmitted || presentationStage == .arrivedAtDropoff), !isCompletingDelivery else {
            return nil
        }
        errorMessage = nil
        isCompletingDelivery = true
        defer { isCompletingDelivery = false }

        do {
            let updated = try await bookingRepository.completeDelivery(id: booking.id)
            booking = updated
            deliveryPhase = .delivered
            await stopRealtimeAndFlush()
            return updated
        } catch let error as NetworkError {
            errorMessage = error.userMessage
        } catch {
            errorMessage = NetworkError.unknown(error.localizedDescription).userMessage
        }
        return nil
    }

    @discardableResult
    func submitCustomerRatingAndComplete(_ rating: CustomerRatingRequest) async throws -> Booking {
        let rated = try await bookingRepository.rateCustomer(id: booking.id, rating: rating)
        booking = rated
        return await completeDelivery() ?? rated
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
