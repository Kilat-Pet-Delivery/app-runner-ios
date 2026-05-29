import Foundation

protocol ChatRepositoryProtocol {
    func listThreads() async throws -> [ChatThread]
    func fetchMessages(threadID: String, cursor: String?) async throws -> ChatMessagesPage
    func sendMessage(threadID: String, body: String, clientMessageID: String) async throws -> ChatMessage
    func sendAttachment(threadID: String, imageData: Data, clientMessageID: String) async throws -> ChatMessage
    func markRead(threadID: String, messageID: String) async throws
    func listQuickReplies() async throws -> [ChatQuickReply]
}

final class ChatRepository: ChatRepositoryProtocol {
    private let authInterceptor: AuthInterceptor

    init(authInterceptor: AuthInterceptor) {
        self.authInterceptor = authInterceptor
    }

    convenience init(apiClient: APIClient = APIClient(), tokenStore: TokenStore = KeychainStore()) {
        self.init(authInterceptor: AuthInterceptor(apiClient: apiClient, tokenStore: tokenStore))
    }

    func listThreads() async throws -> [ChatThread] {
        let envelope: APIResponseEnvelope<[ChatThread]> = try await authInterceptor.perform(.threads)
        return envelope.data
    }

    func fetchMessages(threadID: String, cursor: String?) async throws -> ChatMessagesPage {
        let envelope: APIResponseEnvelope<ChatMessagesPage> = try await authInterceptor.perform(
            .threadMessages(threadId: threadID, cursor: cursor)
        )
        return envelope.data
    }

    func sendMessage(threadID: String, body: String, clientMessageID: String) async throws -> ChatMessage {
        let envelope: APIResponseEnvelope<ChatMessage> = try await authInterceptor.perform(
            .sendThreadMessage(threadId: threadID),
            body: ChatMessageRequest(body: body, clientMessageID: clientMessageID)
        )
        return envelope.data
    }

    func sendAttachment(threadID: String, imageData: Data, clientMessageID: String) async throws -> ChatMessage {
        let envelope: APIResponseEnvelope<ChatMessage> = try await authInterceptor.uploadMultipart(
            .sendThreadAttachment(threadId: threadID),
            fields: ["client_message_id": clientMessageID],
            fileField: "photo",
            fileName: "attachment.jpg",
            fileMIMEType: "image/jpeg",
            fileData: imageData
        )
        return envelope.data
    }

    func markRead(threadID: String, messageID: String) async throws {
        let _: APIResponseEnvelope<EmptyResponse> = try await authInterceptor.perform(
            .markThreadRead(threadId: threadID),
            body: MarkReadRequest(messageID: messageID)
        )
    }

    func listQuickReplies() async throws -> [ChatQuickReply] {
        let envelope: APIResponseEnvelope<[ChatQuickReply]> = try await authInterceptor.perform(.quickReplies)
        return envelope.data
    }
}

private struct MarkReadRequest: Encodable {
    let messageID: String
}
