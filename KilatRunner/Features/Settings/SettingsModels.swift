import Foundation

struct UserSettings: Codable, Equatable {
    var language: RunnerLanguage
    var theme: RunnerTheme
    var notificationPreferences: [NotificationCategory: Bool]
    var accountVisibility: AccountVisibility

    static let fallback = UserSettings(
        language: .english,
        theme: .system,
        notificationPreferences: Dictionary(uniqueKeysWithValues: NotificationCategory.allCases.map { ($0, true) }),
        accountVisibility: .visible
    )
}

enum RunnerTheme: String, Codable, CaseIterable, Identifiable {
    case system
    case light
    case dark

    var id: String { rawValue }
    var title: String { rawValue.capitalized }
}

enum RunnerLanguage: String, Codable, CaseIterable, Identifiable {
    case english = "en"
    case malay = "ms"
    case chinese = "zh"

    var id: String { rawValue }

    var title: String {
        switch self {
        case .english: return "English"
        case .malay: return "Bahasa Melayu"
        case .chinese: return "Chinese"
        }
    }
}

enum NotificationCategory: String, Codable, CaseIterable, Identifiable {
    case jobs
    case chat
    case payments
    case incidents
    case promotions

    var id: String { rawValue }
    var title: String { rawValue.capitalized }
}

enum AccountVisibility: String, Codable, CaseIterable, Identifiable {
    case visible
    case privateMode = "private"

    var id: String { rawValue }
    var title: String { self == .visible ? "Visible" : "Private" }
}
