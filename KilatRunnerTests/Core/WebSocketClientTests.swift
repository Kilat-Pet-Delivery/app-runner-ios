import XCTest
@testable import KilatRunner

@MainActor
final class WebSocketClientTests: XCTestCase {
    func test_connect_emitsReceivedMessages() async throws {
        let transport = FakeWebSocketTransport()
        let client = WebSocketClient(transport: transport)
        let url = URL(string: "ws://localhost/ws/tracking/booking-1")!

        try await client.connect(url: url)
        let messageTask = Task { await client.messages.firstValue() }
        await transport.emit(Data("hello".utf8))

        let receivedMessage = await messageTask.value
        let message = try XCTUnwrap(receivedMessage)
        XCTAssertEqual(String(data: message, encoding: .utf8), "hello")
    }

    func test_disconnect_stopsEmittingMessages() async throws {
        let transport = FakeWebSocketTransport()
        let client = WebSocketClient(transport: transport)
        let url = URL(string: "ws://localhost/ws/tracking/booking-1")!

        try await client.connect(url: url)
        client.disconnect()
        await transport.emit(Data("ignored".utf8))

        XCTAssertEqual(client.state, .disconnected)
        let disconnectCallCount = await transport.disconnectCallCount
        XCTAssertEqual(disconnectCallCount, 1)
    }

    func test_drop_triggersReconnectWithBackoff() async throws {
        let transport = FakeWebSocketTransport()
        let sleeper = SleepRecorder()
        let client = WebSocketClient(
            transport: transport,
            sleep: { nanoseconds in await sleeper.record(nanoseconds) }
        )
        let url = URL(string: "ws://localhost/ws/tracking/booking-1")!

        try await client.connect(url: url)
        await transport.failNextConnects(2)
        await transport.drop()
        try await waitUntil { client.state == .connected }

        let connectCallCount = await transport.connectCallCount
        let recordedSleeps = await sleeper.snapshot()
        XCTAssertEqual(connectCallCount, 4)
        XCTAssertEqual(recordedSleeps, [
            1_000_000_000,
            2_000_000_000,
            4_000_000_000
        ])
    }

    func test_exceedMaxAttempts_surfacesDisconnectedState() async throws {
        let transport = FakeWebSocketTransport()
        let sleeper = SleepRecorder()
        let client = WebSocketClient(
            transport: transport,
            sleep: { nanoseconds in await sleeper.record(nanoseconds) }
        )
        let url = URL(string: "ws://localhost/ws/tracking/booking-1")!

        try await client.connect(url: url)
        await transport.failNextConnects(5)
        await transport.drop()
        try await waitUntil { client.state == .disconnected }

        let connectCallCount = await transport.connectCallCount
        let recordedSleepCount = await sleeper.recordedCount()
        XCTAssertEqual(connectCallCount, 6)
        XCTAssertEqual(recordedSleepCount, 5)
    }

    private func waitUntil(
        timeoutNanoseconds: UInt64 = 1_000_000_000,
        condition: @escaping () async -> Bool
    ) async throws {
        let deadline = Date().addingTimeInterval(Double(timeoutNanoseconds) / 1_000_000_000)
        while Date() < deadline {
            if await condition() { return }
            try await Task.sleep(nanoseconds: 10_000_000)
        }
        XCTFail("Timed out waiting for condition.")
    }
}

private actor SleepRecorder {
    private(set) var recorded: [UInt64] = []

    func record(_ nanoseconds: UInt64) {
        recorded.append(nanoseconds)
    }

    func snapshot() -> [UInt64] {
        recorded
    }

    func recordedCount() -> Int {
        recorded.count
    }
}

private final class FakeWebSocketTransport: WebSocketTransport, @unchecked Sendable {
    private let core = FakeWebSocketTransportCore()

    var connectCallCount: Int {
        get async { await core.connectCallCount }
    }

    var disconnectCallCount: Int {
        get async { await core.disconnectCallCount }
    }

    func connect(url: URL) async throws {
        try await core.connect(url: url)
    }

    func disconnect() {
        Task { await core.disconnect() }
    }

    func receive() async throws -> Data {
        try await core.receive()
    }

    func emit(_ data: Data) async {
        await core.emit(data)
    }

    func drop() async {
        await core.drop()
    }

    func failNextConnects(_ count: Int) async {
        await core.failNextConnects(count)
    }
}

private actor FakeWebSocketTransportCore {
    private(set) var connectCallCount = 0
    private(set) var disconnectCallCount = 0
    private var failedConnectsRemaining = 0
    private var pendingResults: [Result<Data, Error>] = []
    private var receiveContinuation: CheckedContinuation<Data, Error>?

    func connect(url: URL) async throws {
        connectCallCount += 1
        if failedConnectsRemaining > 0 {
            failedConnectsRemaining -= 1
            throw URLError(.cannotConnectToHost)
        }
    }

    func disconnect() {
        disconnectCallCount += 1
    }

    func receive() async throws -> Data {
        if !pendingResults.isEmpty {
            return try pendingResults.removeFirst().get()
        }

        return try await withCheckedThrowingContinuation { continuation in
            receiveContinuation = continuation
        }
    }

    func emit(_ data: Data) {
        deliver(.success(data))
    }

    func drop() {
        deliver(.failure(URLError(.networkConnectionLost)))
    }

    func failNextConnects(_ count: Int) {
        failedConnectsRemaining = count
    }

    private func deliver(_ result: Result<Data, Error>) {
        if let continuation = receiveContinuation {
            receiveContinuation = nil
            continuation.resume(with: result)
        } else {
            pendingResults.append(result)
        }
    }
}

private extension AsyncStream where Element == Data {
    func firstValue() async -> Data? {
        for await value in self {
            return value
        }
        return nil
    }
}
