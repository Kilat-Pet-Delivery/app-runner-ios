import XCTest
import SwiftUI
import SnapshotTesting
@testable import KilatRunner

@MainActor
final class DashboardViewSnapshotTests: XCTestCase {

    func test_dashboard_view_online_state_renders_online_badge_light() throws {
#if canImport(UIKit) && os(iOS)
        let viewModel = Self.makeViewModel(isOnline: true)
        renderSnapshot(viewModel: viewModel, style: .light, testName: "online_light")
#else
        throw XCTSkip("Snapshot tests require an iOS simulator — skipped on macOS host.")
#endif
    }

    func test_dashboard_view_online_state_renders_online_badge_dark() throws {
#if canImport(UIKit) && os(iOS)
        let viewModel = Self.makeViewModel(isOnline: true)
        renderSnapshot(viewModel: viewModel, style: .dark, testName: "online_dark")
#else
        throw XCTSkip("Snapshot tests require an iOS simulator — skipped on macOS host.")
#endif
    }

    func test_dashboard_view_offline_state_no_active_job_card() {
        let viewModel = Self.makeViewModel(isOnline: false)

        XCTAssertNil(viewModel.activeJob,
                     "Offline dashboard default state should not have an active job")
        XCTAssertFalse(viewModel.isOnline)
    }

    func test_dashboard_view_with_active_job_renders_amber_card() throws {
#if canImport(UIKit) && os(iOS)
        let viewModel = Self.makeViewModel(isOnline: true)
        viewModel.activeJob = DashboardActiveJob(
            bookingId: "test-booking",
            pickupAddress: "Pet Haven · Bangsar",
            dropoffAddress: "Mont Kiara · 12 Jalan 23"
        )

        XCTAssertNotNil(viewModel.activeJob)
        renderSnapshot(viewModel: viewModel, style: .light, testName: "with_active_job")
#else
        throw XCTSkip("Snapshot tests require an iOS simulator — skipped on macOS host.")
#endif
    }

#if canImport(UIKit) && os(iOS)
    private func renderSnapshot(viewModel: DashboardViewModel, style: UIUserInterfaceStyle, testName: String) {
        let view = NavigationStack {
            DashboardView(viewModel: viewModel)
                .environment(AppSession())
        }
        let vc = UIHostingController(rootView: view)
        vc.view.frame = CGRect(x: 0, y: 0, width: 390, height: 844)
        vc.overrideUserInterfaceStyle = style
        withSnapshotTesting(record: .missing) {
            assertSnapshot(of: vc, as: .image(on: .iPhone13Pro), named: testName)
        }
    }
#endif

    private static func makeViewModel(isOnline: Bool) -> DashboardViewModel {
        let runner = Runner(
            id: "rn-1",
            userId: "u-1",
            fullName: "Aiman Hakim",
            phone: "+60123456780",
            vehicleType: "scooter",
            vehiclePlate: "VKL 4421",
            vehicleModel: "Honda EX5",
            airConditioned: false,
            sessionStatus: isOnline ? .active : .inactive,
            rating: 4.9,
            totalTrips: 124,
            crateSpecs: [],
            distanceKm: nil,
            createdAt: Date(timeIntervalSince1970: 0)
        )
        let vm = DashboardViewModel(
            repository: DashboardSnapshotMockRepository(runner: runner),
            locationPermissionProvider: DashboardSnapshotMockLocationProvider()
        )
        vm.runner = runner
        vm.isOnline = isOnline
        vm.weeklyEarningsCents = 23_400
        vm.weeklyGoalCents = 50_000
        vm.deliveriesThisWeek = 11
        vm.onlineMinutesThisWeek = 312
        return vm
    }
}

private final class DashboardSnapshotMockRepository: RunnerRepositoryProtocol {
    private let runner: Runner
    init(runner: Runner) { self.runner = runner }
    func getMe() async throws -> Runner { runner }
    func goOnline(latitude: Double, longitude: Double) async throws {}
    func goOffline() async throws {}
    func postLocation(_ waypoint: RunnerLocationWaypoint) async throws {}
}

private final class DashboardSnapshotMockLocationProvider: LocationPermissionProvider {
    func requestAlwaysAuthorization() async -> Bool { true }
    func currentCoordinate() async -> RunnerCoordinate? {
        RunnerCoordinate(latitude: 3.139, longitude: 101.6869)
    }
}
