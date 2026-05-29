import Foundation

enum ChatSenderSide: String, Codable, Equatable {
    case `self`
    case other
}

enum ChatDeliveryState: String, Codable, Equatable {
    case sent
    case delivered
    case read
}

enum ChatPresence: Equatable {
    case online
    case offline
    case lastSeen(Date)
}

struct ChatParticipant: Decodable, Equatable, Identifiable {
    let id: String
    let displayName: String
    let avatarURL: URL?
    let role: String?
}

struct ChatThread: Decodable, Equatable, Identifiable {
    let id: String
    let bookingID: String?
    let participants: [ChatParticipant]
    let lastMessagePreview: String?
    let lastMessageAt: Date?
    let unreadCount: Int
}

struct ChatMessage: Decodable, Equatable, Identifiable {
    let id: String
    let threadID: String
    let senderID: String
    let senderSide: ChatSenderSide
    let body: String
    let attachmentURL: URL?
    let deliveryState: ChatDeliveryState
    let timestamp: Date
}

struct ChatQuickReply: Decodable, Equatable, Identifiable {
    let id: String
    let title: String
}

struct ChatMessagesPage: Decodable, Equatable {
    let messages: [ChatMessage]
    let nextCursor: String?
}

struct ChatMessageRequest: Encodable, Equatable {
    let body: String
    let clientMessageID: String
}

enum ChatEvent: Equatable {
    case messageSent(ChatMessage)
    case messageDelivered(messageID: String, threadID: String)
    case messageRead(messageID: String, threadID: String, at: Date)
    case typing(threadID: String, senderID: String, isActive: Bool)
}

enum PresenceEvent: Equatable {
    case online(userID: String)
    case offline(userID: String)
    case lastSeen(userID: String, at: Date)
}
