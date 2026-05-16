import CoreLocation
import XCTest
@testable import KilatRunner

@MainActor
final class ActiveDeliveryViewModelTests: XCTestCase {
    func test_init_derivesCoordinatesFromBooking() {
        let booking = Self.makeBooking()
        let viewModel = ActiveDeliveryViewModel(
            booking: booking,
            locationProvider: FakeLocationProvider(),
            runnerRepository: FakeRunnerRepository(),
            webSocketClient: FakeRealtimeTrackingClient(),
            tokenStore: FakeTokenStore()
        )

        XCTAssertEqual(viewModel.pickupCoordinate.latitude, booking.pickupAddress.latitude)
        XCTAssertEqual(viewModel.pickupCoordinate.longitude, booking.pickupAddress.longitude)
        XCTAssertEqual(viewModel.dropoffCoordinate.latitude, booking.dropoffAddress.latitude)
        XCTAssertEqual(viewModel.dropoffCoordinate.longitude, booking.dropoffAddress.longitude)
    }

    func test_initialDeliveryPhase_isEnroute() {
        let viewModel = ActiveDeliveryViewModel(
            booking: Self.makeBooking(),
            locationProvider: FakeLocationProvider(),
            runnerRepository: FakeRunnerRepository(),
            webSocketClient: FakeRealtimeTrackingClient(),
            tokenStore: FakeTokenStore()
        )

        XCTAssertEqual(viewModel.deliveryPhase, .enroute)
    }

    func test_onAppear_startsLocationUpdates() {
        let locationProvider = FakeLocationProvider()
        let viewModel = ActiveDeliveryViewModel(
            booking: Self.makeBooking(),
            locationProvider: locationProvider,
            runnerRepository: FakeRunnerRepository(),
            webSocketClient: FakeRealtimeTrackingClient(),
            tokenStore: FakeTokenStore()
        )

        viewModel.onAppear()

        XCTAssertEqual(locationProvider.startUpdatesCallCount, 1)
    }

    func test_locationUpdate_updatesCurrentLocation() async throws {
        let locationProvider = FakeLocationProvider()
        let viewModel = ActiveDeliveryViewModel(
            booking: Self.makeBooking(),
            locationProvider: locationProvider,
            runnerRepository: FakeRunnerRepository(),
            webSocketClient: FakeRealtimeTrackingClient(),
            tokenStore: FakeTokenStore()
        )

        viewModel.onAppear()

        let testCoordinate = CLLocationCoordinate2D(latitude: 3.14, longitude: 101.5)
        let testLocation = CLLocation(
            coordinate: testCoordinate,
            altitude: 0,
            horizontalAccuracy: 10,
            verticalAccuracy: 10,
            course: 90,
            speed: 5,
            timestamp: Date()
        )
        locationProvider.emit(testLocation)

        try? await Task.sleep(nanoseconds: 100_000_000)

        let coord = try XCTUnwrap(viewModel.currentLocation)
        XCTAssertEqual(coord.latitude, 3.14, accuracy: 0.0001)
        XCTAssertEqual(coord.longitude, 101.5, accuracy: 0.0001)
    }

    func test_onDeliveryCompleted_stopsUpdatesAndFlushes() async throws {
        let locationProvider = FakeLocationProvider()
        let runnerRepository = FakeRunnerRepository()
        let viewModel = ActiveDeliveryViewModel(
            booking: Self.makeBooking(),
            locationProvider: locationProvider,
            runnerRepository: runnerRepository,
            webSocketClient: FakeRealtimeTrackingClient(),
            tokenStore: FakeTokenStore()
        )

        viewModel.onAppear()
        let testLocation = CLLocation(
            coordinate: CLLocationCoordinate2D(latitude: 3.14, longitude: 101.5),
            altitude: 0,
            horizontalAccuracy: 10,
            verticalAccuracy: 10,
            course: 90,
            speed: 5,
            timestamp: Date()
        )
        locationProvider.emit(testLocation)
        try? await Task.sleep(nanoseconds: 100_000_000)

        await viewModel.onDeliveryCompleted()

        XCTAssertEqual(viewModel.deliveryPhase, .delivered)
        XCTAssertEqual(locationProvider.stopUpdatesCallCount, 1)
        let posted = await runnerRepository.postedWaypoints
        XCTAssertEqual(posted.count, 1)
        let firstPosted = try XCTUnwrap(posted.first)
        XCTAssertEqual(firstPosted.latitude, 3.14, accuracy: 0.0001)
    }

    func test_onAppear_connectsWebSocket() async throws {
        let webSocketClient = FakeRealtimeTrackingClient()
        let viewModel = ActiveDeliveryViewModel(
            booking: Self.makeBooking(),
            locationProvider: FakeLocationProvider(),
            runnerRepository: FakeRunnerRepository(),
            webSocketClient: webSocketClient,
            tokenStore: FakeTokenStore(accessToken: "abc123"),
            wsBaseURL: URL(string: "ws://localhost:8080")!
        )

        viewModel.onAppear()
        try await waitUntil { webSocketClient.connectedURL != nil }

        let url = try XCTUnwrap(webSocketClient.connectedURL)
        XCTAssertEqual(url.path, "/ws/tracking/10000000-0000-4000-8000-000000000001")
        XCTAssertEqual(URLComponents(url: url, resolvingAgainstBaseURL: false)?.queryItems?.first?.name, "token")
        XCTAssertEqual(URLComponents(url: url, resolvingAgainstBaseURL: false)?.queryItems?.first?.value, "abc123")
    }

    func test_incomingTrackingUpdate_updatesCurrentLocation() async throws {
        let webSocketClient = FakeRealtimeTrackingClient()
        let viewModel = ActiveDeliveryViewModel(
            booking: Self.makeBooking(),
            locationProvider: FakeLocationProvider(),
            runnerRepository: FakeRunnerRepository(),
            webSocketClient: webSocketClient,
            tokenStore: FakeTokenStore()
        )

        viewModel.onAppear()
        let json = """
        {
          "booking_id": "10000000-0000-4000-8000-000000000001",
          "runner_id": "22222222-2222-4222-8222-222222222222",
          "latitude": 3.1555,
          "longitude": 101.7222,
          "speed_kmh": 18.5,
          "heading_degrees": 120,
          "timestamp": "2026-05-16T10:01:00Z"
        }
        """
        webSocketClient.emit(Data(json.utf8))
        try await waitUntil { viewModel.currentLocation != nil }

        let coord = try XCTUnwrap(viewModel.currentLocation)
        XCTAssertEqual(coord.latitude, 3.1555, accuracy: 0.0001)
        XCTAssertEqual(coord.longitude, 101.7222, accuracy: 0.0001)
    }

    func test_onDisappear_disconnectsWebSocket() async throws {
        let webSocketClient = FakeRealtimeTrackingClient()
        let viewModel = ActiveDeliveryViewModel(
            booking: Self.makeBooking(),
            locationProvider: FakeLocationProvider(),
            runnerRepository: FakeRunnerRepository(),
            webSocketClient: webSocketClient,
            tokenStore: FakeTokenStore()
        )

        viewModel.onAppear()
        await viewModel.onDisappear()

        XCTAssertEqual(webSocketClient.disconnectCallCount, 1)
    }

    // MARK: - Fixtures

    private static func makeBooking() -> Booking {
        let json = """
        {
          "id": "10000000-0000-4000-8000-000000000001",
          "booking_number": "BK-AB12CD",
          "owner_id": "20000000-0000-4000-8000-000000000001",
          "runner_id": "22222222-2222-4222-8222-222222222222",
          "status": "accepted",
          "pet_spec": {
            "pet_type": "cat",
            "breed": "Persian",
            "name": "Milo",
            "weight_kg": 4.5,
            "special_needs": "",
            "photo_url": ""
          },
          "pickup_address": {
            "line1": "123 Jalan Ampang",
            "line2": "",
            "city": "Kuala Lumpur",
            "state": "WP",
            "postal_code": "50450",
            "country": "MY",
            "latitude": 3.1626,
            "longitude": 101.7185
          },
          "dropoff_address": {
            "line1": "1 Jalan SS2/24",
            "line2": "",
            "city": "Petaling Jaya",
            "state": "Selangor",
            "postal_code": "47300",
            "country": "MY",
            "latitude": 3.1170,
            "longitude": 101.6190
          },
          "route_spec": {
            "pickup_lat": 3.1626,
            "pickup_lng": 101.7185,
            "dropoff_lat": 3.1170,
            "dropoff_lng": 101.6190,
            "distance_km": 12.4,
            "estimated_duration_min": 28,
            "polyline": ""
          },
          "estimated_price_cents": 2500,
          "currency": "MYR",
          "version": 1,
          "created_at": "2026-05-16T10:00:00Z",
          "updated_at": "2026-05-16T10:00:00Z"
        }
        """
        let decoder = JSONDecoder()
        decoder.keyDecodingStrategy = .convertFromSnakeCase
        decoder.dateDecodingStrategy = .iso8601
        return try! decoder.decode(Booking.self, from: json.data(using: .utf8)!)
    }

    private func waitUntil(
        timeoutNanoseconds: UInt64 = 1_000_000_000,
        condition: @escaping () async -> Bool
    ) async throws {
        let deadline = Date().addingTimeInterval(Double(timeoutNanoseconds) / 1_000_000_000)
        while Date() < deadline {
            if await condition() { return }
            try await Task.sleep(nanoseconds: 10_000_000)
        }
        XCTFail("Timed out waiting for condition.")
    }
}

private final class FakeLocationProvider: LocationProvider, @unchecked Sendable {
    let locationUpdates: AsyncStream<CLLocation>
    private let yielder: AsyncStream<CLLocation>.Continuation
    private(set) var startUpdatesCallCount = 0
    private(set) var stopUpdatesCallCount = 0
    private(set) var requestAlwaysCallCount = 0

    init() {
        var continuation: AsyncStream<CLLocation>.Continuation!
        self.locationUpdates = AsyncStream { continuation = $0 }
        self.yielder = continuation
    }

    func requestAlwaysAuthorization() async -> CLAuthorizationStatus {
        requestAlwaysCallCount += 1
        return .authorizedAlways
    }

    func startUpdates() {
        startUpdatesCallCount += 1
    }

    func stopUpdates() {
        stopUpdatesCallCount += 1
        yielder.finish()
    }

    func emit(_ location: CLLocation) {
        yielder.yield(location)
    }
}

private actor FakeRunnerRepository: RunnerRepositoryProtocol {
    private(set) var postedWaypoints: [RunnerLocationWaypoint] = []

    func getMe() async throws -> Runner {
        throw NetworkError.notFound
    }

    func goOnline(latitude: Double, longitude: Double) async throws {}

    func goOffline() async throws {}

    func postLocation(_ waypoint: RunnerLocationWaypoint) async throws {
        postedWaypoints.append(waypoint)
    }
}

private final class FakeRealtimeTrackingClient: RealtimeTrackingClient, @unchecked Sendable {
    let messages: AsyncStream<Data>
    private let yielder: AsyncStream<Data>.Continuation
    private(set) var connectedURL: URL?
    private(set) var disconnectCallCount = 0

    init() {
        var continuation: AsyncStream<Data>.Continuation!
        self.messages = AsyncStream { continuation = $0 }
        self.yielder = continuation
    }

    func connect(url: URL) async throws {
        connectedURL = url
    }

    func disconnect() {
        disconnectCallCount += 1
    }

    func emit(_ data: Data) {
        yielder.yield(data)
    }
}

private final class FakeTokenStore: TokenStore {
    private var storedAccessToken: String?

    init(accessToken: String? = "test-access-token") {
        self.storedAccessToken = accessToken
    }

    func saveAccessToken(_ token: String) throws {
        storedAccessToken = token
    }

    func accessToken() -> String? {
        storedAccessToken
    }

    func saveRefreshToken(_ token: String) throws {}

    func refreshToken() -> String? {
        nil
    }

    func clear() {
        storedAccessToken = nil
    }
}
