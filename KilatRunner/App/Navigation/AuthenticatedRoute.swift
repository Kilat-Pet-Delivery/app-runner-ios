import Foundation

enum AuthenticatedRoute: Hashable {
    case profile
    case settings
    case support
    case notifications
    case chat(threadID: String)
    case bankAccounts
    case documents
    case jobHistory
    case scheduledJobs
    case quests
    case hotZones
    case performance
    case reviews
    case referFriend
}

extension AuthenticatedRoute: Identifiable {
    var id: String {
        switch self {
        case .profile: return "profile"
        case .settings: return "settings"
        case .support: return "support"
        case .notifications: return "notifications"
        case let .chat(threadID): return "chat-\(threadID)"
        case .bankAccounts: return "bank-accounts"
        case .documents: return "documents"
        case .jobHistory: return "job-history"
        case .scheduledJobs: return "scheduled-jobs"
        case .quests: return "quests"
        case .hotZones: return "hot-zones"
        case .performance: return "performance"
        case .reviews: return "reviews"
        case .referFriend: return "refer-friend"
        }
    }
}
