import XCTest
@testable import KilatRunner

@MainActor
final class OfflineViewModelTests: XCTestCase {
    func test_queuedWaypoints_appearInCard_whenBufferNonEmpty() async {
        let viewModel = OfflineViewModel {
            4
        }

        await viewModel.refresh()

        XCTAssertEqual(viewModel.queuedWaypointCount, 4)
        XCTAssertEqual(viewModel.queuedActionsSummary, "4 waypoint updates queued.")
    }
}
