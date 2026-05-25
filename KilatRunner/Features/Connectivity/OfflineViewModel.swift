import Foundation
import Observation

@MainActor
@Observable
final class OfflineViewModel {
    private(set) var queuedWaypointCount: Int

    var queuedActionsSummary: String {
        switch queuedWaypointCount {
        case 0:
            return "No delivery updates are queued."
        case 1:
            return "1 waypoint update queued."
        default:
            return "\(queuedWaypointCount) waypoint updates queued."
        }
    }

    @ObservationIgnored private let queuedCountProvider: () async -> Int

    init(
        queuedWaypointCount: Int = 0,
        queuedCountProvider: @escaping () async -> Int = { 0 }
    ) {
        self.queuedWaypointCount = queuedWaypointCount
        self.queuedCountProvider = queuedCountProvider
    }

    func refresh() async {
        queuedWaypointCount = await queuedCountProvider()
    }
}
