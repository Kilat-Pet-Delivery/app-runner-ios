import Foundation
import XCTest
@testable import KilatRunner

@MainActor
final class SOSViewModelTests: XCTestCase {
    func test_longPressOneSecond_firesIncident_severityCritical() async {
        let repository = IncidentRepositorySpy()
        let viewModel = SOSViewModel(bookingID: "booking-3", repository: repository)

        await viewModel.fireAfterLongPress()

        XCTAssertTrue(viewModel.hasActiveIncident)
        XCTAssertTrue(viewModel.isLocationStreaming)
        XCTAssertEqual(repository.createCalls.count, 1)
        XCTAssertEqual(repository.createCalls[0].type, .sos)
        XCTAssertEqual(repository.createCalls[0].severity, .critical)
    }

    func test_cooldownWindow_allowsCancel_forFiveSeconds() async {
        let repository = IncidentRepositorySpy()
        let dateProvider = ManualDateProvider(now: Date(timeIntervalSince1970: 100))
        let viewModel = SOSViewModel(
            bookingID: "booking-3",
            repository: repository,
            dateProvider: dateProvider,
            cooldownSeconds: 5
        )

        await viewModel.fireAfterLongPress()
        XCTAssertTrue(viewModel.canCancelDuringCooldown)

        await viewModel.cancelFalseAlarm()

        XCTAssertTrue(viewModel.didResolve)
        XCTAssertFalse(viewModel.isLocationStreaming)
        XCTAssertEqual(repository.resolveCalls, [.init(id: "incident-1", reason: "false_alarm")])
    }

    func test_afterCooldown_locationKeepsStreaming_untilResolved() async {
        let repository = IncidentRepositorySpy()
        let dateProvider = ManualDateProvider(now: Date(timeIntervalSince1970: 100))
        let viewModel = SOSViewModel(
            bookingID: "booking-3",
            repository: repository,
            dateProvider: dateProvider,
            cooldownSeconds: 5
        )

        await viewModel.fireAfterLongPress()
        dateProvider.current = Date(timeIntervalSince1970: 106)

        XCTAssertFalse(viewModel.canCancelDuringCooldown)
        XCTAssertTrue(viewModel.isLocationStreaming)

        await viewModel.cancelFalseAlarm()

        XCTAssertTrue(repository.resolveCalls.isEmpty)
        XCTAssertTrue(viewModel.isLocationStreaming)
    }
}

private final class ManualDateProvider: CurrentDateProviding {
    var current: Date

    init(now: Date) {
        self.current = now
    }

    func now() -> Date {
        current
    }
}
