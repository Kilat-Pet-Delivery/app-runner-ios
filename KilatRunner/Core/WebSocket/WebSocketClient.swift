import Foundation
import Observation

enum WebSocketConnectionState: Equatable {
    case idle
    case connected
    case reconnecting(attempt: Int)
    case disconnected
}

enum WebSocketChannel: Equatable {
    case tracking(bookingID: String)
    case chat
    case presence

    var path: String {
        switch self {
        case let .tracking(bookingID): return "ws/tracking/\(bookingID)"
        case .chat: return "ws/chat"
        case .presence: return "ws/presence"
        }
    }

    func url(base: URL, accessToken: String?) -> URL? {
        let candidate = base.appending(path: path)
        guard var components = URLComponents(url: candidate, resolvingAgainstBaseURL: false) else {
            return nil
        }
        if let accessToken, !accessToken.isEmpty {
            components.queryItems = [URLQueryItem(name: "token", value: accessToken)]
        }
        return components.url
    }
}

protocol WebSocketTransport: Sendable {
    func connect(url: URL) async throws
    func disconnect()
    func receive() async throws -> Data
}

@MainActor
protocol RealtimeTrackingClient: AnyObject {
    var messages: AsyncStream<Data> { get }
    func connect(url: URL) async throws
    func disconnect()
}

@MainActor
@Observable
final class WebSocketClient: RealtimeTrackingClient {
    private(set) var state: WebSocketConnectionState = .idle

    @ObservationIgnored private let transport: WebSocketTransport
    @ObservationIgnored private let maxReconnectAttempts: Int
    @ObservationIgnored private let sleep: @Sendable (UInt64) async throws -> Void
    @ObservationIgnored private var receiveTask: Task<Void, Never>?
    @ObservationIgnored private var messageContinuation: AsyncStream<Data>.Continuation?

    @ObservationIgnored
    lazy var messages: AsyncStream<Data> = AsyncStream { continuation in
        self.messageContinuation = continuation
    }

    init(
        transport: WebSocketTransport = URLSessionWebSocketTransport(),
        maxReconnectAttempts: Int = 5,
        sleep: @escaping @Sendable (UInt64) async throws -> Void = { try await Task.sleep(nanoseconds: $0) }
    ) {
        self.transport = transport
        self.maxReconnectAttempts = maxReconnectAttempts
        self.sleep = sleep
    }

    deinit {
        receiveTask?.cancel()
        messageContinuation?.finish()
        transport.disconnect()
    }

    func connect(url: URL) async throws {
        receiveTask?.cancel()
        try await transport.connect(url: url)
        state = .connected
        startReceiving(url: url)
    }

    func connect(channel: WebSocketChannel, baseURL: URL, accessToken: String?) async throws {
        guard let url = channel.url(base: baseURL, accessToken: accessToken) else {
            throw URLError(.badURL)
        }
        try await connect(url: url)
    }

    func disconnect() {
        receiveTask?.cancel()
        receiveTask = nil
        transport.disconnect()
        state = .disconnected
    }

    private func startReceiving(url: URL) {
        let transport = transport
        let continuation = messageContinuation
        receiveTask = Task { [weak self] in
            while !Task.isCancelled {
                do {
                    let data = try await transport.receive()
                    continuation?.yield(data)
                } catch {
                    await self?.reconnect(url: url)
                    return
                }
            }
        }
    }

    private func reconnect(url: URL) async {
        for attempt in 1...maxReconnectAttempts {
            guard !Task.isCancelled else { return }
            state = .reconnecting(attempt: attempt)
            do {
                try await sleep(backoffNanoseconds(for: attempt))
                try await transport.connect(url: url)
                guard !Task.isCancelled else { return }
                state = .connected
                startReceiving(url: url)
                return
            } catch {
                continue
            }
        }

        state = .disconnected
    }

    private func backoffNanoseconds(for attempt: Int) -> UInt64 {
        let seconds = min(pow(2.0, Double(attempt - 1)), 30)
        return UInt64(seconds * 1_000_000_000)
    }
}

final class URLSessionWebSocketTransport: WebSocketTransport, @unchecked Sendable {
    private let session: URLSession
    private var task: URLSessionWebSocketTask?

    init(session: URLSession = .shared) {
        self.session = session
    }

    func connect(url: URL) async throws {
        disconnect()
        let task = session.webSocketTask(with: url)
        self.task = task
        task.resume()
    }

    func disconnect() {
        task?.cancel(with: .normalClosure, reason: nil)
        task = nil
    }

    func receive() async throws -> Data {
        guard let task else {
            throw URLError(.notConnectedToInternet)
        }

        let message = try await task.receive()
        switch message {
        case .data(let data):
            return data
        case .string(let string):
            return Data(string.utf8)
        @unknown default:
            throw URLError(.cannotDecodeContentData)
        }
    }
}
