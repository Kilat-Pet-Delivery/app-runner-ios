import XCTest
@testable import KilatRunner

@MainActor
final class ChatViewModelTests: XCTestCase {
    private static let threadID = "thread-1"
    private static let selfID = "runner-1"
    private static let remoteID = "customer-1"

    func test_connect_subscribesToWS_andLoadsRecentMessages() async throws {
        let repository = FakeChatRepository()
        let chatSocket = FakeChatSocketClient()
        let presenceSocket = FakePresenceSocketClient()
        repository.messagesByCursor[nil] = ChatMessagesPage(
            messages: [Self.makeMessage(id: "m1", side: .other, body: "hi")],
            nextCursor: "cursor-2"
        )

        let vm = ChatViewModel(
            threadID: Self.threadID,
            selfUserID: Self.selfID,
            remoteUserID: Self.remoteID,
            repository: repository,
            chatSocket: chatSocket,
            presenceSocket: presenceSocket
        )

        await vm.connect()

        XCTAssertEqual(vm.messages.map(\.id), ["m1"])
        XCTAssertEqual(vm.nextCursor, "cursor-2")
        XCTAssertEqual(chatSocket.connectCallCount, 1)
        XCTAssertEqual(presenceSocket.connectCallCount, 1)
    }

    func test_sendText_appendsLocallyImmediately_withStateSent() async throws {
        let repository = FakeChatRepository()
        repository.messagesByCursor[nil] = ChatMessagesPage(messages: [], nextCursor: nil)
        let vm = ChatViewModel(
            threadID: Self.threadID,
            selfUserID: Self.selfID,
            remoteUserID: Self.remoteID,
            repository: repository,
            chatSocket: FakeChatSocketClient(),
            presenceSocket: FakePresenceSocketClient()
        )
        await vm.connect()

        repository.sendDelay = 50_000_000
        let send = Task { await vm.sendText("on my way") }

        try await waitUntil { vm.messages.count == 1 }
        let optimistic = try XCTUnwrap(vm.messages.first)
        XCTAssertEqual(optimistic.body, "on my way")
        XCTAssertEqual(optimistic.deliveryState, .sent)
        XCTAssertEqual(optimistic.senderSide, .self)
        await send.value
    }

    func test_remoteMessageSent_appendsToMessages_andMarksRead_ifActive() async throws {
        let repository = FakeChatRepository()
        repository.messagesByCursor[nil] = ChatMessagesPage(messages: [], nextCursor: nil)
        let chatSocket = FakeChatSocketClient()

        let vm = ChatViewModel(
            threadID: Self.threadID,
            selfUserID: Self.selfID,
            remoteUserID: Self.remoteID,
            repository: repository,
            chatSocket: chatSocket,
            presenceSocket: FakePresenceSocketClient()
        )
        vm.isActive = true
        await vm.connect()

        chatSocket.emit(.messageSent(Self.makeMessage(id: "remote-1", side: .other, body: "ping")))

        try await waitUntil { vm.messages.contains(where: { $0.id == "remote-1" }) }
        try await waitUntil { repository.readMarks.contains(where: { $0.messageID == "remote-1" }) }
    }

    func test_remoteMessageSent_doesNotMarkRead_ifScrolledAway() async throws {
        let repository = FakeChatRepository()
        repository.messagesByCursor[nil] = ChatMessagesPage(messages: [], nextCursor: nil)
        let chatSocket = FakeChatSocketClient()

        let vm = ChatViewModel(
            threadID: Self.threadID,
            selfUserID: Self.selfID,
            remoteUserID: Self.remoteID,
            repository: repository,
            chatSocket: chatSocket,
            presenceSocket: FakePresenceSocketClient()
        )
        vm.isActive = false
        await vm.connect()

        chatSocket.emit(.messageSent(Self.makeMessage(id: "remote-2", side: .other, body: "ping")))

        try await waitUntil { vm.messages.contains(where: { $0.id == "remote-2" }) }
        try? await Task.sleep(nanoseconds: 50_000_000)
        XCTAssertFalse(repository.readMarks.contains(where: { $0.messageID == "remote-2" }))
    }

    func test_loadOlder_prependsAndAvoidsDuplicates() async throws {
        let repository = FakeChatRepository()
        let initial = Self.makeMessage(id: "m1", side: .other, body: "current", offsetSeconds: 0)
        let older = Self.makeMessage(id: "m0", side: .other, body: "older", offsetSeconds: -60)
        let duplicate = Self.makeMessage(id: "m1", side: .other, body: "current", offsetSeconds: 0)
        repository.messagesByCursor[nil] = ChatMessagesPage(messages: [initial], nextCursor: "c2")
        repository.messagesByCursor["c2"] = ChatMessagesPage(messages: [older, duplicate], nextCursor: nil)

        let vm = ChatViewModel(
            threadID: Self.threadID,
            selfUserID: Self.selfID,
            remoteUserID: Self.remoteID,
            repository: repository,
            chatSocket: FakeChatSocketClient(),
            presenceSocket: FakePresenceSocketClient()
        )
        await vm.connect()
        await vm.loadOlder()

        XCTAssertEqual(vm.messages.map(\.id), ["m0", "m1"])
        XCTAssertNil(vm.nextCursor)
    }

    func test_setTyping_debouncesEmits_to1PerSecond() async throws {
        let vm = ChatViewModel(
            threadID: Self.threadID,
            selfUserID: Self.selfID,
            remoteUserID: Self.remoteID,
            repository: FakeChatRepository(),
            chatSocket: FakeChatSocketClient(),
            presenceSocket: FakePresenceSocketClient()
        )

        for _ in 0..<5 {
            vm.setTyping(active: true)
            try? await Task.sleep(nanoseconds: 50_000_000)
        }
        XCTAssertEqual(vm.typingEmitCount, 1)

        try await Task.sleep(nanoseconds: 1_100_000_000)
        vm.setTyping(active: true)
        XCTAssertEqual(vm.typingEmitCount, 2)
    }

    func test_presenceUpdate_updatesHeaderDot() async throws {
        let presenceSocket = FakePresenceSocketClient()
        let vm = ChatViewModel(
            threadID: Self.threadID,
            selfUserID: Self.selfID,
            remoteUserID: Self.remoteID,
            repository: FakeChatRepository(),
            chatSocket: FakeChatSocketClient(),
            presenceSocket: presenceSocket
        )
        await vm.connect()

        presenceSocket.emit(.online(userID: Self.remoteID))
        try await waitUntil { vm.remotePresence == .online }

        presenceSocket.emit(.offline(userID: Self.remoteID))
        try await waitUntil { vm.remotePresence == .offline }
    }

    // MARK: - Helpers

    private static func makeMessage(
        id: String,
        side: ChatSenderSide,
        body: String,
        offsetSeconds: TimeInterval = 0
    ) -> ChatMessage {
        ChatMessage(
            id: id,
            threadID: threadID,
            senderID: side == .self ? selfID : remoteID,
            senderSide: side,
            body: body,
            attachmentURL: nil,
            deliveryState: .sent,
            timestamp: Date(timeIntervalSinceReferenceDate: 600_000_000 + offsetSeconds)
        )
    }

    private func waitUntil(
        timeoutNanoseconds: UInt64 = 2_000_000_000,
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

private final class FakeChatRepository: ChatRepositoryProtocol, @unchecked Sendable {
    struct ReadMark: Equatable {
        let threadID: String
        let messageID: String
    }

    var messagesByCursor: [String?: ChatMessagesPage] = [:]
    var readMarks: [ReadMark] = []
    var sendDelay: UInt64 = 0

    func listThreads() async throws -> [ChatThread] { [] }

    func fetchMessages(threadID: String, cursor: String?) async throws -> ChatMessagesPage {
        messagesByCursor[cursor] ?? ChatMessagesPage(messages: [], nextCursor: nil)
    }

    func sendMessage(threadID: String, body: String, clientMessageID: String) async throws -> ChatMessage {
        if sendDelay > 0 { try await Task.sleep(nanoseconds: sendDelay) }
        return ChatMessage(
            id: clientMessageID,
            threadID: threadID,
            senderID: "runner-1",
            senderSide: .self,
            body: body,
            attachmentURL: nil,
            deliveryState: .sent,
            timestamp: Date()
        )
    }

    func sendAttachment(threadID: String, imageData: Data, clientMessageID: String) async throws -> ChatMessage {
        ChatMessage(
            id: clientMessageID,
            threadID: threadID,
            senderID: "runner-1",
            senderSide: .self,
            body: "",
            attachmentURL: URL(string: "https://example.test/photo.jpg"),
            deliveryState: .sent,
            timestamp: Date()
        )
    }

    func markRead(threadID: String, messageID: String) async throws {
        readMarks.append(ReadMark(threadID: threadID, messageID: messageID))
    }

    func listQuickReplies() async throws -> [ChatQuickReply] { [] }
}

@MainActor
private final class FakeChatSocketClient: ChatSocketClientProtocol {
    let events: AsyncStream<ChatEvent>
    private let yielder: AsyncStream<ChatEvent>.Continuation
    private(set) var connectCallCount = 0

    init() {
        var continuation: AsyncStream<ChatEvent>.Continuation!
        events = AsyncStream { continuation = $0 }
        yielder = continuation
    }

    func connect() async throws {
        connectCallCount += 1
    }

    func disconnect() {}

    func emit(_ event: ChatEvent) {
        yielder.yield(event)
    }
}

@MainActor
private final class FakePresenceSocketClient: PresenceSocketClientProtocol {
    let events: AsyncStream<PresenceEvent>
    private let yielder: AsyncStream<PresenceEvent>.Continuation
    private(set) var connectCallCount = 0

    init() {
        var continuation: AsyncStream<PresenceEvent>.Continuation!
        events = AsyncStream { continuation = $0 }
        yielder = continuation
    }

    func connect() async throws {
        connectCallCount += 1
    }

    func disconnect() {}

    func emit(_ event: PresenceEvent) {
        yielder.yield(event)
    }
}
