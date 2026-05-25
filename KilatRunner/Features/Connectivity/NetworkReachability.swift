import Foundation
import Network
import Observation

enum NetworkReachabilityStatus: Equatable {
    case online
    case offline
}

@MainActor
@Observable
final class NetworkReachability {
    static let shared = NetworkReachability()

    private(set) var status: NetworkReachabilityStatus = .online

    var isOffline: Bool { status == .offline }

    @ObservationIgnored private let monitor: NWPathMonitor?
    @ObservationIgnored private let queue = DispatchQueue(label: "kilat.runner.network-reachability")
    @ObservationIgnored private var hasStarted = false

    init(monitor: NWPathMonitor? = NWPathMonitor(), startsImmediately: Bool = true) {
        self.monitor = monitor
        if startsImmediately {
            start()
        }
    }

    func start() {
        guard !hasStarted, let monitor else { return }
        hasStarted = true
        monitor.pathUpdateHandler = { [weak self] path in
            Task { @MainActor in
                self?.apply(path.status)
            }
        }
        monitor.start(queue: queue)
    }

    func apply(_ pathStatus: NWPath.Status) {
        status = pathStatus == .satisfied ? .online : .offline
    }

    func cancel() {
        monitor?.cancel()
        hasStarted = false
    }
}
