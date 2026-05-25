import Foundation

@MainActor
protocol PresenceSocketClientProtocol: AnyObject {
    var events: AsyncStream<PresenceEvent> { get }
    func connect() async throws
    func disconnect()
}

@MainActor
final class PresenceSocketClient: PresenceSocketClientProtocol {
    private let webSocketClient: WebSocketClient
    private let baseURL: URL
    private let tokenStore: TokenStore
    private var streamTask: Task<Void, Never>?

    private lazy var continuation: AsyncStream<PresenceEvent>.Continuation? = nil
    lazy var events: AsyncStream<PresenceEvent> = AsyncStream { continuation in
        self.continuation = continuation
    }

    init(
        webSocketClient: WebSocketClient? = nil,
        baseURL: URL = AppEnvironment.wsBaseURL,
        tokenStore: TokenStore = KeychainStore()
    ) {
        self.webSocketClient = webSocketClient ?? WebSocketClient()
        self.baseURL = baseURL
        self.tokenStore = tokenStore
    }

    func connect() async throws {
        try await webSocketClient.connect(
            channel: .presence,
            baseURL: baseURL,
            accessToken: tokenStore.accessToken()
        )
        let stream = webSocketClient.messages
        streamTask = Task { [weak self] in
            for await data in stream {
                if let event = Self.decode(data) {
                    self?.continuation?.yield(event)
                }
            }
        }
    }

    func disconnect() {
        streamTask?.cancel()
        streamTask = nil
        webSocketClient.disconnect()
    }

    static func decode(_ data: Data) -> PresenceEvent? {
        let decoder = JSONDecoder()
        decoder.keyDecodingStrategy = .convertFromSnakeCase
        decoder.dateDecodingStrategy = .iso8601

        guard let envelope = try? decoder.decode(PresenceEventEnvelope.self, from: data) else {
            return nil
        }

        switch envelope.type {
        case "presence.online":
            return (try? decoder.decode(PresenceOnlinePayload.self, from: data))
                .map { .online(userID: $0.payload.userID) }
        case "presence.offline":
            return (try? decoder.decode(PresenceOfflinePayload.self, from: data))
                .map { .offline(userID: $0.payload.userID) }
        case "presence.last_seen":
            return (try? decoder.decode(PresenceLastSeenPayload.self, from: data)).map {
                .lastSeen(userID: $0.payload.userID, at: $0.payload.at)
            }
        default:
            return nil
        }
    }
}

private struct PresenceEventEnvelope: Decodable {
    let type: String
}

private struct PresenceOnlinePayload: Decodable {
    struct Body: Decodable { let userID: String }
    let payload: Body
}

private struct PresenceOfflinePayload: Decodable {
    struct Body: Decodable { let userID: String }
    let payload: Body
}

private struct PresenceLastSeenPayload: Decodable {
    struct Body: Decodable {
        let userID: String
        let at: Date
    }
    let payload: Body
}
