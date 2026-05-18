import Foundation
import Observation

@Observable
final class NotificationsViewModel {
    var items: [RunnerNotification] = []
    private(set) var isLoading = false
    private(set) var nextCursor: String?
    var errorMessage: String?

    var hasMore: Bool {
        nextCursor != nil
    }

    @ObservationIgnored private let repository: NotificationRepositoryProtocol
    @ObservationIgnored private let pageLimit: Int

    init(repository: NotificationRepositoryProtocol = NotificationRepository(), pageLimit: Int = 20) {
        self.repository = repository
        self.pageLimit = pageLimit
    }

    @MainActor
    func loadFirstPage() async {
        guard !isLoading else { return }
        items = []
        nextCursor = nil
        await load(cursor: nil, replacesExisting: true)
    }

    @MainActor
    func loadNextPage() async {
        guard let nextCursor, !nextCursor.isEmpty, !isLoading else { return }
        await load(cursor: nextCursor, replacesExisting: false)
    }

    @MainActor
    func markReadLocally(_ id: String) {
        guard let index = items.firstIndex(where: { $0.id == id }), items[index].readAt == nil else {
            return
        }
        items[index].readAt = Date()
    }

    @MainActor
    private func load(cursor: String?, replacesExisting: Bool) async {
        errorMessage = nil
        isLoading = true
        defer { isLoading = false }

        do {
            let response = try await repository.list(cursor: cursor, limit: pageLimit)
            items = replacesExisting ? response.items : items + response.items
            nextCursor = response.nextCursor.isEmpty ? nil : response.nextCursor
        } catch let error as NetworkError {
            errorMessage = error.userMessage
        } catch {
            errorMessage = NetworkError.unknown(error.localizedDescription).userMessage
        }
    }
}
