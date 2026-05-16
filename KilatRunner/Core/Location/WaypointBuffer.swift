import Foundation

struct Waypoint: Equatable, Sendable {
    let latitude: Double
    let longitude: Double
    let speedKmh: Double
    let headingDegrees: Double
    let timestamp: Date
}

actor WaypointBuffer {
    typealias FlushHandler = @Sendable ([Waypoint]) async -> Void

    private var waypoints: [Waypoint] = []
    private var batchStartedAt: Date?
    private let flushCount: Int
    private let flushIntervalSeconds: TimeInterval
    private let now: @Sendable () -> Date
    private let flush: FlushHandler

    init(
        flushCount: Int = 5,
        flushIntervalSeconds: TimeInterval = 30,
        now: @escaping @Sendable () -> Date = { Date() },
        flush: @escaping FlushHandler
    ) {
        self.flushCount = flushCount
        self.flushIntervalSeconds = flushIntervalSeconds
        self.now = now
        self.flush = flush
    }

    func add(_ waypoint: Waypoint) async {
        if waypoints.isEmpty {
            batchStartedAt = now()
        }
        waypoints.append(waypoint)
        if shouldFlushByCount() || shouldFlushByTime() {
            await performFlush()
        }
    }

    func tick() async {
        if shouldFlushByTime() {
            await performFlush()
        }
    }

    func forceFlush() async {
        await performFlush()
    }

    var count: Int { waypoints.count }

    private func shouldFlushByCount() -> Bool {
        waypoints.count >= flushCount
    }

    private func shouldFlushByTime() -> Bool {
        guard let started = batchStartedAt, !waypoints.isEmpty else { return false }
        return now().timeIntervalSince(started) >= flushIntervalSeconds
    }

    private func performFlush() async {
        guard !waypoints.isEmpty else { return }
        let batch = waypoints
        waypoints = []
        batchStartedAt = nil
        await flush(batch)
    }
}
