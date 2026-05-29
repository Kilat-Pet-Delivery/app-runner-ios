import Foundation

protocol NotificationRepositoryProtocol {
    func list(cursor: String?, limit: Int) async throws -> NotificationListResponse
}

final class NotificationRepository: NotificationRepositoryProtocol {
    private let authInterceptor: AuthInterceptor

    init(authInterceptor: AuthInterceptor) {
        self.authInterceptor = authInterceptor
    }

    convenience init(apiClient: APIClient = APIClient(), tokenStore: TokenStore = KeychainStore()) {
        self.init(authInterceptor: AuthInterceptor(apiClient: apiClient, tokenStore: tokenStore))
    }

    func list(cursor: String? = nil, limit: Int = 20) async throws -> NotificationListResponse {
        try await authInterceptor.perform(.notifications(cursor: cursor, limit: limit))
    }
}

struct NotificationListResponse: Decodable, Equatable {
    let items: [RunnerNotification]
    let nextCursor: String
}

struct RunnerNotification: Decodable, Equatable, Identifiable {
    let id: String
    let type: String
    let title: String
    let body: String
    let createdAt: Date
    var readAt: Date?

    var isUnread: Bool { readAt == nil }
}
