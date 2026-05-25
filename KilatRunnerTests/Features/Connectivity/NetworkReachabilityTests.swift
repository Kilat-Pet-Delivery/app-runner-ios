import Network
import XCTest
@testable import KilatRunner

@MainActor
final class NetworkReachabilityTests: XCTestCase {
    func test_pathLost_flipsStateOffline_andPathRestored_flipsBack() {
        let reachability = NetworkReachability(monitor: nil, startsImmediately: false)

        XCTAssertFalse(reachability.isOffline)

        reachability.apply(.unsatisfied)

        XCTAssertTrue(reachability.isOffline)
        XCTAssertEqual(reachability.status, .offline)

        reachability.apply(.satisfied)

        XCTAssertFalse(reachability.isOffline)
        XCTAssertEqual(reachability.status, .online)
    }
}
