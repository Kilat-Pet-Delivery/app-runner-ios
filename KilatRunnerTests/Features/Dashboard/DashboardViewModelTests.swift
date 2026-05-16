import XCTest
@testable import KilatRunner

@MainActor
final class DashboardViewModelTests: XCTestCase {
    func test_loadRunner_populatesRunnerState() async {
        let repository = MockRunnerRepository(runnerResult: .success(Self.onlineRunner))
        let viewModel = DashboardViewModel(
            repository: repository,
            locationPermissionProvider: MockLocationPermissionProvider()
        )

        await viewModel.loadRunner()

        XCTAssertEqual(viewModel.runner, Self.onlineRunner)
        XCTAssertTrue(viewModel.isOnline)
        XCTAssertFalse(viewModel.isLoading)
        XCTAssertNil(viewModel.errorMessage)
    }

    func test_toggleOnline_whenOffline_requestsPermissionThenCallsGoOnline() async {
        let repository = MockRunnerRepository()
        let permissionProvider = MockLocationPermissionProvider(
            permissionGranted: true,
            coordinate: RunnerCoordinate(latitude: 3.139, longitude: 101.6869)
        )
        let viewModel = DashboardViewModel(
            repository: repository,
            locationPermissionProvider: permissionProvider
        )

        await viewModel.toggleOnline()

        XCTAssertEqual(permissionProvider.requestCallCount, 1)
        XCTAssertEqual(repository.goOnlineCallCount, 1)
        XCTAssertEqual(repository.lastOnlineCoordinate, RunnerCoordinate(latitude: 3.139, longitude: 101.6869))
        XCTAssertTrue(viewModel.isOnline)
        XCTAssertFalse(viewModel.isTogglingOnline)
    }

    func test_toggleOnline_permissionDenied_doesNotCallGoOnline_setsError() async {
        let repository = MockRunnerRepository()
        let permissionProvider = MockLocationPermissionProvider(permissionGranted: false)
        let viewModel = DashboardViewModel(
            repository: repository,
            locationPermissionProvider: permissionProvider
        )

        await viewModel.toggleOnline()

        XCTAssertEqual(permissionProvider.requestCallCount, 1)
        XCTAssertEqual(repository.goOnlineCallCount, 0)
        XCTAssertEqual(viewModel.errorMessage, "Allow always-on location access to go online.")
        XCTAssertFalse(viewModel.isOnline)
    }

    func test_toggleOnline_whenOnline_callsGoOffline_noPermissionCheck() async {
        let repository = MockRunnerRepository(runnerResult: .success(Self.onlineRunner))
        let permissionProvider = MockLocationPermissionProvider()
        let viewModel = DashboardViewModel(
            repository: repository,
            locationPermissionProvider: permissionProvider
        )
        await viewModel.loadRunner()

        await viewModel.toggleOnline()

        XCTAssertEqual(permissionProvider.requestCallCount, 0)
        XCTAssertEqual(repository.goOfflineCallCount, 1)
        XCTAssertFalse(viewModel.isOnline)
    }

    private static let onlineRunner = Runner(
        id: "22222222-2222-4222-8222-222222222222",
        userId: "11111111-1111-4111-8111-111111111111",
        fullName: "Test Runner",
        phone: "+60123456780",
        vehicleType: "car",
        vehiclePlate: "KILAT1",
        vehicleModel: "Myvi",
        airConditioned: true,
        sessionStatus: .active,
        rating: 4.9,
        totalTrips: 12,
        crateSpecs: [],
        distanceKm: nil,
        createdAt: Date(timeIntervalSince1970: 0)
    )
}

private final class MockRunnerRepository: RunnerRepositoryProtocol {
    private let runnerResult: Result<Runner, Error>
    private let toggleResult: Result<Void, Error>
    private(set) var goOnlineCallCount = 0
    private(set) var goOfflineCallCount = 0
    private(set) var lastOnlineCoordinate: RunnerCoordinate?

    init(
        runnerResult: Result<Runner, Error> = .failure(NetworkError.notFound),
        toggleResult: Result<Void, Error> = .success(())
    ) {
        self.runnerResult = runnerResult
        self.toggleResult = toggleResult
    }

    func getMe() async throws -> Runner {
        try runnerResult.get()
    }

    func goOnline(latitude: Double, longitude: Double) async throws {
        goOnlineCallCount += 1
        lastOnlineCoordinate = RunnerCoordinate(latitude: latitude, longitude: longitude)
        try toggleResult.get()
    }

    func goOffline() async throws {
        goOfflineCallCount += 1
        try toggleResult.get()
    }

    func postLocation(_ waypoint: RunnerLocationWaypoint) async throws {}
}

private final class MockLocationPermissionProvider: LocationPermissionProvider {
    private let permissionGranted: Bool
    private let coordinate: RunnerCoordinate?
    private(set) var requestCallCount = 0

    init(
        permissionGranted: Bool = true,
        coordinate: RunnerCoordinate? = RunnerCoordinate(latitude: 3.139, longitude: 101.6869)
    ) {
        self.permissionGranted = permissionGranted
        self.coordinate = coordinate
    }

    func requestAlwaysAuthorization() async -> Bool {
        requestCallCount += 1
        return permissionGranted
    }

    func currentCoordinate() async -> RunnerCoordinate? {
        coordinate
    }
}
