import Foundation

@MainActor
protocol ChatSocketClientProtocol: AnyObject {
    var events: AsyncStream<ChatEvent> { get }
    func connect() async throws
    func disconnect()
}

@MainActor
final class ChatSocketClient: ChatSocketClientProtocol {
    private let webSocketClient: WebSocketClient
    private let baseURL: URL
    private let tokenStore: TokenStore
    private var streamTask: Task<Void, Never>?

    private lazy var continuation: AsyncStream<ChatEvent>.Continuation? = nil
    lazy var events: AsyncStream<ChatEvent> = AsyncStream { continuation in
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
            channel: .chat,
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

    static func decode(_ data: Data) -> ChatEvent? {
        let decoder = JSONDecoder()
        decoder.keyDecodingStrategy = .convertFromSnakeCase
        decoder.dateDecodingStrategy = .iso8601

        guard let envelope = try? decoder.decode(ChatEventEnvelope.self, from: data) else {
            return nil
        }

        switch envelope.type {
        case "chat.message.sent":
            return (try? decoder.decode(ChatMessageSentPayload.self, from: data))
                .map { .messageSent($0.payload) }
        case "chat.message.delivered":
            return (try? decoder.decode(ChatMessageDeliveredPayload.self, from: data)).map {
                .messageDelivered(messageID: $0.payload.messageID, threadID: $0.payload.threadID)
            }
        case "chat.message.read":
            return (try? decoder.decode(ChatMessageReadPayload.self, from: data)).map {
                .messageRead(messageID: $0.payload.messageID, threadID: $0.payload.threadID, at: $0.payload.at)
            }
        case "chat.typing":
            return (try? decoder.decode(ChatTypingPayload.self, from: data)).map {
                .typing(threadID: $0.payload.threadID, senderID: $0.payload.senderID, isActive: $0.payload.isActive)
            }
        default:
            return nil
        }
    }
}

private struct ChatEventEnvelope: Decodable {
    let type: String
}

private struct ChatMessageSentPayload: Decodable {
    let payload: ChatMessage
}

private struct ChatMessageDeliveredPayload: Decodable {
    struct Body: Decodable {
        let messageID: String
        let threadID: String
    }
    let payload: Body
}

private struct ChatMessageReadPayload: Decodable {
    struct Body: Decodable {
        let messageID: String
        let threadID: String
        let at: Date
    }
    let payload: Body
}

private struct ChatTypingPayload: Decodable {
    struct Body: Decodable {
        let threadID: String
        let senderID: String
        let isActive: Bool
    }
    let payload: Body
}
