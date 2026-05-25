import XCTest
@testable import KilatRunner

@MainActor
final class SupportViewModelTests: XCTestCase {
    func test_tapHeroChat_navigatesToSupportThread() async {
        let repository = FakeSupportRepository()
        repository.threadID = "thread-support"
        let viewModel = SupportViewModel(repository: repository)

        await viewModel.openSupportChat()

        XCTAssertEqual(viewModel.route, .chat(threadID: "thread-support"))
    }
}

private final class FakeSupportRepository: SupportRepositoryProtocol {
    var threadID = "support"

    func listFAQs() async throws -> [FAQItem] { [] }
    func recentTicket() async throws -> SupportTicket? { nil }
    func supportThreadID() async throws -> String { threadID }
}
