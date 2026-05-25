import XCTest
@testable import KilatRunner

@MainActor
final class PermissionsViewModelTests: XCTestCase {
    func test_allGranted_autoCompletes_withoutShowingScreens() async {
        let client = PermissionsClientSpy(statuses: [
            .location: .granted,
            .camera: .granted,
            .notifications: .granted
        ])
        let viewModel = PermissionsViewModel(client: client)

        await viewModel.load()

        XCTAssertTrue(viewModel.isCompleted)
        XCTAssertNil(viewModel.currentStep)
    }

    func test_locationDenied_advancesToCamera_andShowsSettingsLink() async {
        let client = PermissionsClientSpy(statuses: [
            .location: .denied,
            .camera: .notDetermined,
            .notifications: .notDetermined
        ])
        let viewModel = PermissionsViewModel(client: client)

        await viewModel.load()

        XCTAssertEqual(viewModel.currentStep, .location)
        XCTAssertTrue(viewModel.showsSettingsLink)

        viewModel.skipCurrent()

        XCTAssertEqual(viewModel.currentStep, .camera)
        XCTAssertFalse(viewModel.showsSettingsLink)
    }
}

private final class PermissionsClientSpy: PermissionsClientProtocol {
    var statuses: [RunnerPermissionStep: RunnerPermissionStatus]

    init(statuses: [RunnerPermissionStep: RunnerPermissionStatus]) {
        self.statuses = statuses
    }

    func status(for step: RunnerPermissionStep) async -> RunnerPermissionStatus {
        statuses[step] ?? .notDetermined
    }

    func request(_ step: RunnerPermissionStep) async -> RunnerPermissionStatus {
        statuses[step] ?? .denied
    }
}
