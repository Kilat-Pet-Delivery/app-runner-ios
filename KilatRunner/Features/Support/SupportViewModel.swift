import Foundation
import Observation

struct FAQItem: Identifiable, Equatable {
    let id: String
    let question: String
    let answer: String
}

struct SupportTicket: Equatable {
    let id: String
    let title: String
    let status: String
}

protocol SupportRepositoryProtocol {
    func listFAQs() async throws -> [FAQItem]
    func recentTicket() async throws -> SupportTicket?
    func supportThreadID() async throws -> String
}

final class SupportRepository: SupportRepositoryProtocol {
    func listFAQs() async throws -> [FAQItem] {
        [
            FAQItem(id: "payments", question: "When do payouts arrive?", answer: "Most DuitNow cash-outs arrive instantly after release."),
            FAQItem(id: "live-pets", question: "What if a live pet seems stressed?", answer: "Pause safely, contact support, and follow the welfare checklist."),
            FAQItem(id: "delivery", question: "Can I cancel an active delivery?", answer: "Use Report Problem or SOS so support can create the right incident trail.")
        ]
    }

    func recentTicket() async throws -> SupportTicket? {
        nil
    }

    func supportThreadID() async throws -> String {
        "support"
    }
}

@Observable
final class SupportViewModel {
    var faqs: [FAQItem] = []
    var recentTicket: SupportTicket?
    var query = ""
    var expandedFAQIDs: Set<String> = []
    var route: AuthenticatedRoute?
    var errorMessage: String?

    @ObservationIgnored private let repository: SupportRepositoryProtocol

    init(repository: SupportRepositoryProtocol = SupportRepository()) {
        self.repository = repository
    }

    var filteredFAQs: [FAQItem] {
        guard !query.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else { return faqs }
        return faqs.filter { item in
            item.question.localizedCaseInsensitiveContains(query) ||
                item.answer.localizedCaseInsensitiveContains(query)
        }
    }

    @MainActor
    func load() async {
        do {
            async let faqTask = repository.listFAQs()
            async let ticketTask = repository.recentTicket()
            faqs = try await faqTask
            recentTicket = try await ticketTask
        } catch {
            errorMessage = NetworkError.unknown(error.localizedDescription).userMessage
        }
    }

    @MainActor
    func openSupportChat() async {
        do {
            route = .chat(threadID: try await repository.supportThreadID())
        } catch {
            errorMessage = NetworkError.unknown(error.localizedDescription).userMessage
        }
    }

    func toggleFAQ(_ id: String) {
        if expandedFAQIDs.contains(id) {
            expandedFAQIDs.remove(id)
        } else {
            expandedFAQIDs.insert(id)
        }
    }
}
