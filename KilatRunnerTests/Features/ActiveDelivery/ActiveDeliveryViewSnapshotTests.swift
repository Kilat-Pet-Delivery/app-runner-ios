import XCTest
import CoreLocation
@testable import KilatRunner

@MainActor
final class ActiveDeliveryViewSnapshotTests: XCTestCase {

    func test_active_delivery_view_renders_all_four_states() throws {
        let vm = Self.makeViewModel()

        vm.deliveryPhase = .enroute
        vm.hasArrivedAtCurrentWaypoint = false
        XCTAssertEqual(vm.presentationStage, .toPickup,
                       "enroute + not-arrived should map to toPickup")

        vm.deliveryPhase = .enroute
        vm.hasArrivedAtCurrentWaypoint = true
        XCTAssertEqual(vm.presentationStage, .atPickup,
                       "enroute + arrived should map to atPickup")

        vm.deliveryPhase = .pickedUp
        vm.hasArrivedAtCurrentWaypoint = false
        XCTAssertEqual(vm.presentationStage, .toDropoff,
                       "pickedUp + not-arrived should map to toDropoff")

        vm.deliveryPhase = .pickedUp
        vm.hasArrivedAtCurrentWaypoint = true
        XCTAssertEqual(vm.presentationStage, .atDropoff,
                       "pickedUp + arrived should map to atDropoff")

        vm.deliveryPhase = .delivered
        XCTAssertEqual(vm.presentationStage, .delivered,
                       "delivered phase always maps to delivered stage")
    }

    private static func makeViewModel() -> ActiveDeliveryViewModel {
        ActiveDeliveryViewModel(
            booking: makeBooking(),
            locationProvider: SnapshotFakeLocationProvider(),
            runnerRepository: SnapshotFakeRunnerRepository(),
            bookingRepository: SnapshotFakeBookingRepository(),
            webSocketClient: SnapshotFakeRealtimeTrackingClient(),
            tokenStore: SnapshotFakeTokenStore(),
            wsBaseURL: URL(string: "ws://localhost:8080")!
        )
    }

    private static func makeBooking() -> Booking {
        let json = """
        {
          "id": "30000000-0000-4000-8000-000000000001",
          "booking_number": "BK-AD12CD",
          "owner_id": "30000000-0000-4000-8000-000000000099",
          "runner_id": "rn-1",
          "status": "accepted",
          "pet_spec": {"pet_type": "dog", "breed": "Corgi", "name": "Mochi",
                       "weight_kg": 11.0, "special_needs": "", "photo_url": ""},
          "pickup_address": {"line1": "Pet Haven", "line2": "",
                             "city": "Kuala Lumpur", "state": "WP", "postal_code": "59100",
                             "country": "MY", "latitude": 3.1316, "longitude": 101.6788},
          "dropoff_address": {"line1": "12 Jalan 23/8", "line2": "",
                              "city": "Kuala Lumpur", "state": "WP", "postal_code": "50480",
                              "country": "MY", "latitude": 3.1707, "longitude": 101.6504},
          "route_spec": {"pickup_lat": 3.1316, "pickup_lng": 101.6788,
                         "dropoff_lat": 3.1707, "dropoff_lng": 101.6504,
                         "distance_km": 8.4, "estimated_duration_min": 22, "polyline": ""},
          "estimated_price_cents": 3450, "currency": "MYR", "version": 1,
          "created_at": "2026-05-16T10:00:00Z", "updated_at": "2026-05-16T10:00:00Z"
        }
        """
        let decoder = JSONDecoder()
        decoder.keyDecodingStrategy = .convertFromSnakeCase
        decoder.dateDecodingStrategy = .iso8601
        return try! decoder.decode(Booking.self, from: json.data(using: .utf8)!)
    }
}

private final class SnapshotFakeLocationProvider: LocationProvider, @unchecked Sendable {
    let locationUpdates: AsyncStream<CLLocation>
    init() { self.locationUpdates = AsyncStream { _ in } }
    func requestAlwaysAuthorization() async -> CLAuthorizationStatus { .authorizedAlways }
    func startUpdates() {}
    func stopUpdates() {}
}

private actor SnapshotFakeRunnerRepository: RunnerRepositoryProtocol {
    func getMe() async throws -> Runner { throw NetworkError.notFound }
    func goOnline(latitude: Double, longitude: Double) async throws {}
    func goOffline() async throws {}
    func postLocation(_ waypoint: RunnerLocationWaypoint) async throws {}
}

private final class SnapshotFakeBookingRepository: BookingRepositoryProtocol, @unchecked Sendable {
    func listAvailable() async throws -> [Booking] { [] }
    func get(id: String) async throws -> Booking { throw NetworkError.notFound }
    func accept(id: String) async throws -> Booking { throw NetworkError.notFound }
    func markPickup(id: String) async throws -> Booking { throw NetworkError.notFound }
    func markDelivered(id: String) async throws -> Booking { throw NetworkError.notFound }
}

private final class SnapshotFakeRealtimeTrackingClient: RealtimeTrackingClient, @unchecked Sendable {
    let messages: AsyncStream<Data>
    init() { self.messages = AsyncStream { _ in } }
    func connect(url: URL) async throws {}
    func disconnect() {}
}

private final class SnapshotFakeTokenStore: TokenStore {
    func saveAccessToken(_ token: String) throws {}
    func accessToken() -> String? { "snapshot-token" }
    func saveRefreshToken(_ token: String) throws {}
    func refreshToken() -> String? { nil }
    func clear() {}
}
