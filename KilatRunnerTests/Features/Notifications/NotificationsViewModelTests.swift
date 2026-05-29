import XCTest
@testable import KilatRunner

@MainActor
final class NotificationsViewModelTests: XCTestCase {
    func test_load_fetchesFirstPage() async {
        let repository = MockNotificationRepository(pages: [
            NotificationListResponse(items: [Self.notification(id: "n1")], nextCursor: "cursor-2")
        ])
        let viewModel = NotificationsViewModel(repository: repository, pageLimit: 1)

        await viewModel.loadFirstPage()

        XCTAssertEqual(repository.calls, [nil])
        XCTAssertEqual(viewModel.items.map(\.id), ["n1"])
        XCTAssertTrue(viewModel.hasMore)
    }

    func test_scrollToEnd_fetchesNextPage() async {
        let repository = MockNotificationRepository(pages: [
            NotificationListResponse(items: [Self.notification(id: "n1")], nextCursor: "cursor-2"),
            NotificationListResponse(items: [Self.notification(id: "n2")], nextCursor: "")
        ])
        let viewModel = NotificationsViewModel(repository: repository, pageLimit: 1)

        await viewModel.loadFirstPage()
        await viewModel.loadNextPage()

        XCTAssertEqual(repository.calls, [nil, "cursor-2"])
        XCTAssertEqual(viewModel.items.map(\.id), ["n1", "n2"])
        XCTAssertFalse(viewModel.hasMore)
    }

    func test_noMore_doesNotRefetch() async {
        let repository = MockNotificationRepository(pages: [
            NotificationListResponse(items: [Self.notification(id: "n1")], nextCursor: "")
        ])
        let viewModel = NotificationsViewModel(repository: repository, pageLimit: 1)

        await viewModel.loadFirstPage()
        await viewModel.loadNextPage()

        XCTAssertEqual(repository.calls.count, 1)
    }

    func test_tappingRow_marksReadLocally() {
        let viewModel = NotificationsViewModel(repository: MockNotificationRepository(pages: []))
        viewModel.items = [Self.notification(id: "n1", readAt: nil)]

        viewModel.markReadLocally("n1")

        XCTAssertNotNil(viewModel.items.first?.readAt)
    }

    private static func notification(id: String, readAt: Date? = nil) -> RunnerNotification {
        RunnerNotification(
            id: id,
            type: "booking",
            title: "New job",
            body: "A job is nearby.",
            createdAt: Date(timeIntervalSince1970: 0),
            readAt: readAt
        )
    }
}

private final class MockNotificationRepository: NotificationRepositoryProtocol {
    private var pages: [NotificationListResponse]
    private(set) var calls: [String?] = []

    init(pages: [NotificationListResponse]) {
        self.pages = pages
    }

    func list(cursor: String?, limit: Int) async throws -> NotificationListResponse {
        calls.append(cursor)
        return pages.removeFirst()
    }
}
