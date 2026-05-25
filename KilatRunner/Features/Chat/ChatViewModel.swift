import Foundation
import Observation
#if canImport(UIKit)
import UIKit
#endif

@MainActor
@Observable
final class ChatViewModel {
    enum LoadState: Equatable {
        case idle
        case loading
        case loaded
        case error(String)
    }

    var threadID: String
    var messages: [ChatMessage] = []
    var isLoadingOlder = false
    var remoteIsTyping = false
    var remotePresence: ChatPresence = .offline
    var composeText: String = ""
    var isSendingPhoto = false
    var loadState: LoadState = .idle
    var nextCursor: String?
    var isActive: Bool = true
    private(set) var typingEmitCount: Int = 0

    @ObservationIgnored private let repository: ChatRepositoryProtocol
    @ObservationIgnored private let chatSocket: ChatSocketClientProtocol
    @ObservationIgnored private let presenceSocket: PresenceSocketClientProtocol
    @ObservationIgnored private let selfUserID: String
    @ObservationIgnored private let remoteUserID: String

    @ObservationIgnored private var chatStreamTask: Task<Void, Never>?
    @ObservationIgnored private var presenceStreamTask: Task<Void, Never>?
    @ObservationIgnored private var typingDebounceTask: Task<Void, Never>?
    @ObservationIgnored private var lastTypingEmitAt: Date?

    init(
        threadID: String,
        selfUserID: String,
        remoteUserID: String,
        repository: ChatRepositoryProtocol = ChatRepository(),
        chatSocket: ChatSocketClientProtocol? = nil,
        presenceSocket: PresenceSocketClientProtocol? = nil
    ) {
        self.threadID = threadID
        self.selfUserID = selfUserID
        self.remoteUserID = remoteUserID
        self.repository = repository
        self.chatSocket = chatSocket ?? ChatSocketClient()
        self.presenceSocket = presenceSocket ?? PresenceSocketClient()
    }

    deinit {
        chatStreamTask?.cancel()
        presenceStreamTask?.cancel()
        typingDebounceTask?.cancel()
    }

    func connect() async {
        loadState = .loading
        do {
            let page = try await repository.fetchMessages(threadID: threadID, cursor: nil)
            messages = page.messages.sorted(by: { $0.timestamp < $1.timestamp })
            nextCursor = page.nextCursor
            loadState = .loaded
        } catch {
            loadState = .error((error as? NetworkError)?.userMessage ?? error.localizedDescription)
        }

        try? await chatSocket.connect()
        try? await presenceSocket.connect()

        let chatStream = chatSocket.events
        chatStreamTask = Task { [weak self] in
            for await event in chatStream {
                await self?.handleChatEvent(event)
            }
        }

        let presenceStream = presenceSocket.events
        presenceStreamTask = Task { [weak self] in
            for await event in presenceStream {
                await self?.handlePresenceEvent(event)
            }
        }

        if let latest = messages.last, latest.senderSide == .other, isActive {
            try? await repository.markRead(threadID: threadID, messageID: latest.id)
        }
    }

    func disconnect() {
        chatStreamTask?.cancel()
        presenceStreamTask?.cancel()
        typingDebounceTask?.cancel()
        chatStreamTask = nil
        presenceStreamTask = nil
        typingDebounceTask = nil
        chatSocket.disconnect()
        presenceSocket.disconnect()
    }

    func loadOlder() async {
        guard !isLoadingOlder, let cursor = nextCursor else { return }
        isLoadingOlder = true
        defer { isLoadingOlder = false }
        do {
            let page = try await repository.fetchMessages(threadID: threadID, cursor: cursor)
            let existing = Set(messages.map(\.id))
            let added = page.messages
                .filter { !existing.contains($0.id) }
                .sorted(by: { $0.timestamp < $1.timestamp })
            messages = (added + messages).sorted(by: { $0.timestamp < $1.timestamp })
            nextCursor = page.nextCursor
        } catch {
            // silent — composer still works
        }
    }

    func sendText(_ body: String) async {
        let trimmed = body.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }

        let clientID = UUID().uuidString
        let optimistic = ChatMessage(
            id: clientID,
            threadID: threadID,
            senderID: selfUserID,
            senderSide: .self,
            body: trimmed,
            attachmentURL: nil,
            deliveryState: .sent,
            timestamp: Date()
        )
        messages.append(optimistic)
        composeText = ""

        do {
            let sent = try await repository.sendMessage(threadID: threadID, body: trimmed, clientMessageID: clientID)
            replaceMessage(matching: clientID, with: sent)
        } catch {
            // Leave optimistic message as .sent (mock failures don't roll back per design).
        }
    }

    #if canImport(UIKit)
    func sendPhoto(_ image: UIImage) async {
        guard let data = image.jpegData(compressionQuality: 0.8) else { return }
        await sendPhotoData(data)
    }
    #endif

    func sendPhotoData(_ data: Data) async {
        let clientID = UUID().uuidString
        isSendingPhoto = true
        defer { isSendingPhoto = false }

        do {
            let sent = try await repository.sendAttachment(threadID: threadID, imageData: data, clientMessageID: clientID)
            messages.append(sent)
        } catch {
            // surface error silently for now
        }
    }

    func setTyping(active: Bool) {
        let now = Date()
        if let last = lastTypingEmitAt, now.timeIntervalSince(last) < 1.0 {
            return
        }
        lastTypingEmitAt = now
        typingEmitCount += 1
    }

    private func handleChatEvent(_ event: ChatEvent) async {
        switch event {
        case let .messageSent(message):
            if message.senderSide == .other {
                appendUniqueRemoteMessage(message)
                if isActive {
                    try? await repository.markRead(threadID: threadID, messageID: message.id)
                }
            } else {
                // Confirm our own optimistic send if not already.
                if !messages.contains(where: { $0.id == message.id }) {
                    appendUniqueRemoteMessage(message)
                }
            }

        case let .messageDelivered(messageID, _):
            updateDeliveryState(messageID: messageID, to: .delivered)

        case let .messageRead(messageID, _, _):
            updateDeliveryState(messageID: messageID, to: .read)

        case let .typing(_, senderID, isActiveTyping):
            if senderID == remoteUserID {
                remoteIsTyping = isActiveTyping
            }
        }
    }

    private func handlePresenceEvent(_ event: PresenceEvent) async {
        switch event {
        case let .online(userID) where userID == remoteUserID:
            remotePresence = .online
        case let .offline(userID) where userID == remoteUserID:
            remotePresence = .offline
        case let .lastSeen(userID, at) where userID == remoteUserID:
            remotePresence = .lastSeen(at)
        default:
            break
        }
    }

    private func appendUniqueRemoteMessage(_ message: ChatMessage) {
        guard !messages.contains(where: { $0.id == message.id }) else { return }
        messages.append(message)
    }

    private func replaceMessage(matching clientID: String, with confirmed: ChatMessage) {
        guard let index = messages.firstIndex(where: { $0.id == clientID }) else {
            if !messages.contains(where: { $0.id == confirmed.id }) {
                messages.append(confirmed)
            }
            return
        }
        messages[index] = confirmed
    }

    private func updateDeliveryState(messageID: String, to state: ChatDeliveryState) {
        guard let index = messages.firstIndex(where: { $0.id == messageID }) else { return }
        let existing = messages[index]
        messages[index] = ChatMessage(
            id: existing.id,
            threadID: existing.threadID,
            senderID: existing.senderID,
            senderSide: existing.senderSide,
            body: existing.body,
            attachmentURL: existing.attachmentURL,
            deliveryState: state,
            timestamp: existing.timestamp
        )
    }
}
