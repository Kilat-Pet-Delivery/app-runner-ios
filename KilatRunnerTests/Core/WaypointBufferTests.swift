import Foundation
import XCTest
@testable import KilatRunner

final class WaypointBufferTests: XCTestCase {
    func test_addLessThan5Waypoints_doesNotFlush() async {
        let recorder = FlushRecorder()
        let buffer = WaypointBuffer(flushCount: 5, flushIntervalSeconds: 30) { batch in
            await recorder.record(batch)
        }

        for index in 0..<4 {
            await buffer.add(Self.waypoint(at: index))
        }

        let flushed = await recorder.batches
        XCTAssertTrue(flushed.isEmpty)
        await XCTAssertEqualAsync(await buffer.count, 4)
    }

    func test_addExactly5Waypoints_flushesOnce() async {
        let recorder = FlushRecorder()
        let buffer = WaypointBuffer(flushCount: 5, flushIntervalSeconds: 30) { batch in
            await recorder.record(batch)
        }

        for index in 0..<5 {
            await buffer.add(Self.waypoint(at: index))
        }

        let flushed = await recorder.batches
        XCTAssertEqual(flushed.count, 1)
        XCTAssertEqual(flushed.first?.count, 5)
        await XCTAssertEqualAsync(await buffer.count, 0)
    }

    func test_after30Seconds_flushesEvenIfUnderCount() async {
        let recorder = FlushRecorder()
        let clock = MutableClock(start: Date(timeIntervalSince1970: 0))
        let buffer = WaypointBuffer(
            flushCount: 5,
            flushIntervalSeconds: 30,
            now: { clock.now() }
        ) { batch in
            await recorder.record(batch)
        }

        await buffer.add(Self.waypoint(at: 0))
        await buffer.add(Self.waypoint(at: 1))

        clock.advance(by: 31)
        await buffer.tick()

        let flushed = await recorder.batches
        XCTAssertEqual(flushed.count, 1)
        XCTAssertEqual(flushed.first?.count, 2)
    }

    func test_flush_clearsBuffer() async {
        let recorder = FlushRecorder()
        let buffer = WaypointBuffer(flushCount: 3, flushIntervalSeconds: 30) { batch in
            await recorder.record(batch)
        }

        for index in 0..<3 {
            await buffer.add(Self.waypoint(at: index))
        }
        await buffer.add(Self.waypoint(at: 99))

        let flushed = await recorder.batches
        XCTAssertEqual(flushed.count, 1)
        XCTAssertEqual(flushed.first?.count, 3)
        await XCTAssertEqualAsync(await buffer.count, 1)
    }

    func test_concurrentAdds_threadSafe() async {
        let recorder = FlushRecorder()
        let buffer = WaypointBuffer(flushCount: 100, flushIntervalSeconds: 30) { batch in
            await recorder.record(batch)
        }

        await withTaskGroup(of: Void.self) { group in
            for index in 0..<10 {
                group.addTask {
                    await buffer.add(Self.waypoint(at: index))
                }
            }
        }

        let flushed = await recorder.batches
        XCTAssertTrue(flushed.isEmpty, "Should not flush under threshold")
        await XCTAssertEqualAsync(await buffer.count, 10)
    }

    // MARK: - Helpers

    private static func waypoint(at index: Int) -> Waypoint {
        Waypoint(
            latitude: 3.0 + Double(index) * 0.001,
            longitude: 101.0 + Double(index) * 0.001,
            speedKmh: 30.0,
            headingDegrees: 90.0,
            timestamp: Date(timeIntervalSince1970: TimeInterval(index))
        )
    }
}

private actor FlushRecorder {
    private(set) var batches: [[Waypoint]] = []

    func record(_ batch: [Waypoint]) {
        batches.append(batch)
    }
}

private final class MutableClock: @unchecked Sendable {
    private var current: Date
    private let lock = NSLock()

    init(start: Date) {
        self.current = start
    }

    func now() -> Date {
        lock.lock(); defer { lock.unlock() }
        return current
    }

    func advance(by seconds: TimeInterval) {
        lock.lock(); defer { lock.unlock() }
        current = current.addingTimeInterval(seconds)
    }
}

private func XCTAssertEqualAsync<T: Equatable>(
    _ expression1: @autoclosure () async throws -> T,
    _ expression2: @autoclosure () async throws -> T,
    file: StaticString = #filePath,
    line: UInt = #line
) async {
    do {
        let lhs = try await expression1()
        let rhs = try await expression2()
        XCTAssertEqual(lhs, rhs, file: file, line: line)
    } catch {
        XCTFail("Threw: \(error)", file: file, line: line)
    }
}
